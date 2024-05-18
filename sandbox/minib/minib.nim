# types.nim
import std/[tables, os, strformat, hashes]
import "$nim/compiler/pathutils"
import print
type
  NbBlock = ref object of RootObj
    kind: string
  NbRenderFunc = proc (blk: NbBlock, nb: Nb): string {. noSideEffect .}
  NbRender = object
    funcs: Table[string, NbRenderFunc]
  NbContainer = ref object of NbBlock
    blocks: seq[NbBlock]
  NbDoc = ref object of NbContainer
    title: string
    id: int
    nbJsCounter: int
  Nb = object
    blk: NbBlock # last block processed
    doc: NbDoc # could be a NbBlock but we could give more guarantees with a NbDoc
    containers: seq[NbContainer] # current container
    backend: NbRender # current backend

# this needs to be know for all container blocks not sure whether to put it in types
func render(nb: Nb, blk: NbBlock): string =
  if blk.kind in nb.backend.funcs:
    nb.backend.funcs[blk.kind](blk, nb)
  else:
    ""

proc newId*(doc: var NbDoc): int =
  ## Provides a unique integer each time it is called
  result = doc.id
  inc doc.id

# globals.nim
var nbToJson: Table[string, proc (s: string, i: var int): NbBlock]
var nbToHtml: NbRender # since we need it for json, let's make it also for html

# jsons.nim
import jsony

template addNbBlockToJson*(kind: untyped) =
  nbToJson[$kind] =
    proc (s: string, i: var int): NbBlock =
      var v: kind
      new v
      parseHook(s, i, v[])
      result = v

  method dump(n: kind): string =
    n[].toJson()

proc parseHook*(s: string, i: var int, v: var NbBlock) =
  # First parse the typename
  var n: NbBlock = NbBlock()
  let current_i = i
  parseHook(s, i, n[])
  # Reset i
  i = current_i
  # Parse the correct type
  let kind = n.kind
  if kind notIn nbToJson:
    raise ValueError.newException "cannot find kind in nbToJson: \"" & kind & '"' 
  v = nbToJson[kind](s, i)

method dump(n: NbBlock): string =
    n[].toJson()

proc dumpHook*(s: var string, v: NbBlock) =
  s.add v.dump()

template dumpKey(s: var string, v: string) =
  const v2 = v.toJson() & ":"
  s.add v2


# themes.nim
import std / strutils

func nbContainerToHtml(blk: NbBlock, nb: Nb): string =
  let blk = blk.NbContainer
  for b in blk.blocks:
    result.add nb.render(b).strip & '\n'
  result.strip
# should I add this to the global object?

func nbDocToHtml*(blk: NbBlock, nb: Nb): string =
  "<!DOCTYPE html>\n" &
  "<title>" & blk.NbDoc.title & "</title>\n" &
  nbContainerToHtml(blk, nb)
  
addNbBlockToJson(NbDoc)

# blocks.nim
import std / macros

proc add(nb: var Nb, blk: NbBlock) =
  nb.blk = blk
  if nb.containers.len == 0:
    nb.doc.blocks.add blk
  else:
    nb.containers[^1].blocks.add blk

template withContainer(nb: var Nb, container: NbContainer, body: untyped) =
  nb.add container
  nb.containers.add container
  body
  discard nb.containers.pop

macro toStr*(body: untyped): string =
  (body.toStrLit)

# capture.nim
import capture # imported from old nimib (new nimib does not run locally for me!)

# nimib.nim
import markdown
import jsutils

template nbInit* =
  var nb {. inject .}: Nb
  nb.doc = NbDoc(kind: "NbDoc", title: "a nimib document")
  nbToHtml.funcs["NbDoc"] = nbDocToHtml
  nb.backend = nbToHtml

template nbSave* =
  echo "saving"
  nbCollectAllNbJs(nb)
  echo nb.render nb.doc
  writeFile("test.html", nb.render(nb.doc))

# all other blocks are in a sense all custom blocks
# we could add sugar for common block creation
type
  NbText = ref object of NbBlock
    text: string
template nbText*(ttext: string) =
  let blk = NbText(text: ttext, kind: "NbText")
  nb.add blk
func nbTextToHtml*(blk: NbBlock, nb: Nb): string =
  let blk = blk.NbText
  {.cast(noSideEffect).}: # not sure why markdown is marked with side effects
    markdown(blk.text, config=initGfmConfig())
nbToHtml.funcs["NbText"] = nbTextToHtml
addNbBlockToJson(NbText)
#[ the above could be shortened with sugar to:
newNbBlock(nbText):
  text: string
  toHtml:
    {.cast(noSideEffect).}: # not sure why markdown is marked with side effects
      markdown(blk.text, config=initGfmConfig())
]#

type
  NbImage = ref object of NbBlock
    url: string
template nbImage*(turl: string) =
  let blk = NbImage(url: turl, kind: "NbImage")
  nb.add blk
func nbImageToHtml*(blk: NbBlock, nb: Nb): string =
  let blk = blk.NbImage
  "<img src= '" & blk.url & "'>"
nbToHtml.funcs["NbImage"] = nbImageToHtml
addNbBlockToJson(NbImage)
#[ the above could be shortened with sugar to:
newNbBlock(nbImage):
  url: string
  toHtml:
    "<img src= '" & blk.url & "'>"
]#

type
  NbDetails = ref object of NbContainer
    summary: string
template nbDetails*(tsummary: string, body: untyped) =
  let blk = NbDetails(summary: tsummary, kind: "NbDetails")
  nb.withContainer(blk):
    body

func nbDetailsToHtml*(blk: NbBlock, nb: Nb): string =
  let blk = blk.NbDetails
  "<details><summary>" & blk.summary & "</summary>\n" &
  nbContainerToHtml(blk, nb) &
  "\n</details>"
  
nbToHtml.funcs["NbDetails"] = nbDetailsToHtml
addNbBlockToJson(NbDetails)

type
  NbCode = ref object of NbBlock
    code: string
    output: string
    lang: string
func nbCodeToHtml(blk: NbBlock, nb: Nb): string =
  let blk = blk.NbCode
  "<pre><code class=\"" & blk.lang & "\">\n" &
  blk.code & '\n' &
  "</code></pre>\n" &
  "<pre>\n" &
  blk.output & '\n' &
  "</pre>"
nbToHtml.funcs["NbCode"] = nbCodeToHtml
addNbBlockToJson(NbCode)
template nbCode*(body: untyped) =
  let blk = NbCode(lang: "nim", kind: "NbCode")
  nb.add blk
  blk.code = toStr(body)
  captureStdout(blk.output):
    body

type
  NbJsFromCode = ref object of NbBlock
    code: string
    transformedCode: string
    putAtTop: bool
    showCode: bool
func nbJsFromCodeToHtml(blk: NbBlock, nb: Nb): string =
  let blk = blk.NbJsFromCode
  if blk.showCode:
    "<pre><code class=\"nim\">\n" & blk.code & "\n</code></pre>"
  else:
    ""
nbToHtml.funcs["NbJsFromCode"] = nbJsFromCodeToHtml
addNbBlockToJson(NbJsFromCode)
template nbJsFromCode*(args: varargs[untyped]) =
  let (transformedCode, originalCode) = nimToJsString(putCodeInBlock=false, args)
  let blk = NbJsFromCode(code: originalCode, transformedCode: transformedCode, putAtTop: false, showCode: false, kind: "NbJsFromCode")
  nb.add blk

type
  NbJsFromCodeOwnFile = ref object of NbBlock
    code: string
    transformedCode: string
    jsCode: string
    showCode: bool
func nbJsFromCodeOwnFileToHtml(blk: NbBlock, nb: Nb): string =
  let blk = blk.NbJsFromCodeOwnFile
  result =
    if blk.showCode:
      "<pre><code class=\"nim\">\n" & blk.code & "\n</code></pre>\n"
    else:
      ""
  result &= &"<script>\n{blk.jsCode}\n</script>"
nbToHtml.funcs["NbJsFromCodeOwnFile"] = nbJsFromCodeOwnFileToHtml
addNbBlockToJson(NbJsFromCodeOwnFile)
template nbJsFromCodeOwnFile*(args: varargs[untyped]) =
  let (transformedCode, originalCode) = nimToJsString(putCodeInBlock=false, args)
  let blk = NbJsFromCodeOwnFile(code: originalCode, transformedCode: transformedCode, showCode: false, kind: "NbJsFromCodeOwnFile")
  nb.add blk

# jsutils.nim (these currently require to know of NbJsFromCode and NbJsFromCodeOwnFile...)
proc compileNimToJs*(nb: var Nb, blk: NbBlock): string =
  let blk = blk.NbJsFromCodeOwnFile
  let tempdir = getTempDir() / "nimib"
  createDir(tempdir)
  let (dir, filename, ext) = (getCurrentDir().AbsoluteDir, "js_file", ".nim")#doc.thisFile.splitFile()
  let nimfile = dir / (filename & "_nbCodeToJs_" & $nb.doc.newId() & ext).RelativeFile
  let jsfile = tempdir / &"out{hash(nb.doc.title)}.js"
  var codeText = blk.transformedCode
  let nbJsCounter = nb.doc.nbJsCounter
  nb.doc.nbJsCounter += 1
  var bumpGensymString = """
import std/[macros, json]

macro bumpGensym(n: static int) =
  for i in 0 .. n:
    let _ = gensym()

"""
  bumpGensymString.add &"bumpGensym({nbJsCounter})\n"
  codeText = bumpGensymString & codeText
  writeFile(nimfile, codeText)
  let kxiname = "nimib_kxi_" & $nb.doc.newId()
  let errorCode = execShellCmd(&"nim js -d:danger -d:kxiname=\"{kxiname}\" -o:{jsfile} {nimfile}")
  if errorCode != 0:
    raise newException(OSError, "The compilation of a javascript file failed! Did you remember to capture all needed variables?\n" & $nimfile)
  removeFile(nimfile)
  let jscode = readFile(jsfile)
  removeFile(jsfile)
  return jscode

proc nbCollectAllNbJs*(nb: var Nb) =
  echo "In code!"
  var topCode = "" # placed at the top (nbJsFromCodeGlobal)
  var code = ""
  for blk in nb.doc.blocks: # this won't work for containers, implement nb.flattenBlocks func
    if blk.kind == "NbJsFromCode":
      let blk = blk.NbJsFromCode
      if blk.putAtTop:
        topCode.add "\n" & blk.transformedCode
      else:
        code.add "\n" & blk.transformedCode
  code = topCode & "\n" & code

  print code
  if not code.isEmptyOrWhitespace:
    # Create block which which will compile the code when rendered (nbJsFromJsOwnFile)
    let blk = NbJsFromCodeOwnFile(kind: "NbJsFromCodeOwnFile", code: "", transformedCode: code, showCode: false)
    nb.add blk

  # loop over all nbJsFromCodeOwnFile and compile them
  for blk in nb.doc.blocks:
    if blk.kind == "NbJsFromCodeOwnFile":
      var blk = blk.NbJsFromCodeOwnFile
      blk.jsCode = nb.compileNimToJs(blk)


when isMainModule:
  import print
  nbInit
  nbDetails("Click for details:"):
    nbText: "*hi*"
    nbImage("img.png")
    nbDetails("go deeper"):
      nbText("42")
  nbCode:
    echo "hi"
  nbJsFromCode:
    echo "bye"
  nbSave
  #[
<!DOCTYPE html>
<title>a nimib document<title>
<details><summary>Click for details:</summary>
<p><em>hi</em></p>
<img src= 'img.png'>
<details><summary>go deeper</summary>
<p>42</p>
</details>
</details>
<pre><code class="nim">

echo "hi"
</code></pre>
<pre>
hi

</pre>
  ]#

  let docToJson = nb.doc.toJson()
  print docToJson
  let docFromJson = docToJson.fromJson(NbDoc) # but now this fails
  print docFromJson
  print docFromJson.blocks[0].NbDetails
  print docFromJson.blocks[0].NbDetails.blocks[0].NbText
  print docFromJson.blocks[0].NbDetails.blocks[1].NbImage
  print docFromJson.blocks[1].NbCode
  print docFromJson.blocks[2].NbJsFromCode
  print docFromJson.blocks[3].NbJsFromCodeOwnFile
  #[
  docToJson="{"title":"a nimib document","blocks":[{"summary":"Click for details:","blocks":[{"text":"*hi*","kind":"NbText"},{"url":"img.png","kind":"NbImage"},{"summary":"go deeper","blocks":[{"text":"42","kind":"NbText"}],"kind":"NbDetails"}],"kind":"NbDetails"},{"code":"\\necho \\"hi\\"","output":"hi\\n","lang":"nim","kind":"NbCode"}],"kind":"NbDoc"}"
docFromJson=NbDoc:ObjectType(
  title: "a nimib document",
  blocks: @[NbBlock:ObjectType(kind: "NbDetails"), NbBlock:ObjectType(kind: "NbCode")],
  kind: "NbDoc"
)
docFromJson.blocks[0].NbDetails=NbDetails:ObjectType(
  summary: "Click for details:",
  blocks: @[NbBlock:ObjectType(kind: "NbText"), NbBlock:ObjectType(kind: "NbImage"), NbBlock:ObjectType(kind: "NbDetails")],
  kind: "NbDetails"
)
docFromJson.blocks[0].NbDetails.blocks[0].NbText=NbText:ObjectType(text: "*hi*", kind: "NbText")
docFromJson.blocks[0].NbDetails.blocks[1].NbImage=NbImage:ObjectType(url: "img.png", kind: "NbImage")
docFromJson.blocks[1].NbCode=NbCode:ObjectType(code: "\necho "hi"", output: "hi\n", lang: "nim", kind: "NbCode")
  ]#


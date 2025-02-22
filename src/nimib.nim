import std/[os, strutils, sugar, strformat, macros, macrocache, sequtils, json]
import std / jsonutils except toJson
export jsonutils except toJson
import markdown
import nimib / [types, blocks, docs, boost, config, options, capture, jsons, globals, jsutils, nimibSugars, sources, highlight, logging] 
export types, blocks, docs, boost, sugar, globals, nimibSugars, jsutils, sources, highlight, jsons
# types exports mustache, tables, paths

from nimib / themes import nil
export themes.useLatex, themes.darkMode, themes.`title=`, themes.disableHighlightJs

from nimib / renders import nil

from mustachepkg/values import searchTable, searchDirs, castStr
export searchTable, searchDirs, castStr

template moduleAvailable*(module: untyped): bool =
  (compiles do: import module)

template nbInit*(theme = themes.useDefault, renderer: NbRender = nbToHtml, thisFileRel = "") =
  var nb {.inject.}: Nb
  nb.doc = NbDoc(kind: "NbDoc")
  nb.doc.initDir = getCurrentDir().AbsoluteDir
  loadOptions nb.doc
  loadCfg nb.doc

  # nbInit can be called not from inside the correct file (e.g. when rendering markdown files in nimibook)
  if thisFileRel == "":
    nb.doc.thisFile = instantiationInfo(-1, true).filename.AbsoluteFile
  else:
    nb.doc.thisFile = nb.doc.srcDir / thisFileRel.RelativeFile
    log "thisFile: " & $nb.doc.thisFile

  try:
    nb.doc.source = read(nb.doc.thisFile)
  except IOError:
    log "cannot read source"

  if nb.doc.options.filename == "":
    nb.doc.filename = nb.doc.thisFile.string.splitFile.name & ".html"
  else:
    nb.doc.filename = nb.doc.options.filename

  if nb.doc.cfg.srcDir != "":
    log "srcDir: " & $nb.doc.srcDir
    nb.doc.filename = (nb.doc.thisDir.relativeTo nb.doc.srcDir).string / nb.doc.filename
    log "filename: " & nb.doc.filename

  if nb.doc.cfg.homeDir != "":
    if not dirExists(nb.doc.homeDir):
      log "creating nb.homeDir: " & $nb.doc.homeDir
      createDir(nb.homeDir)

    log "setting current directory to nb.doc.homeDir: " & $nb.doc.homeDir
    setCurrentDir nb.doc.homeDir

  # can be overriden by theme, but it is better to initialize this anyway
  #nb.templateDirs = @["./", "./templates/"]
  #nb.partials = initTable[string, string]()
  nb.doc.context = newJObject() #newContext(searchDirs = @[]) # templateDirs and partials added during nbSave

  # apply render backend (default backend can be overriden by theme)
  nb.backend = renderer

  # apply theme
  theme nb.doc # how do we handle themes?

template nbInitMd*(thisFileRel = "") = 
  var tfr = if thisFileRel == "":
      instantiationInfo(-1).filename
    else:
      thisFileRel

  nbInit(backend=renders.useMdBackend, theme=themes.noTheme, tfr)

  if nb.options.filename == "":
    nb.filename = nb.filename.splitFile.name & ".md"

# block generation templates
template newNbCodeBlock*(cmd: string, body, blockImpl: untyped) =
  newNbBlock(cmd, true, nb, nb.blk, body, blockImpl)

template newNbSlimBlock*(cmd: string, blockImpl: untyped) =
  # a slim block is a block with no body
  newNbBlock(cmd, false, nb, nb.blk, "", blockImpl)

# block templates
#[ template nbCode*(body: untyped) =
  newNbCodeBlock("nbCode", body):
    captureStdout(nb.blk.output):
      body ]#

newNbBlock(NbCode of NbContainer):
  code: string
  output: string
  toHtml:
    withNewlines:
      # TODO: highlight code statically
      if blk.code.len > 0:
        &"<pre><code class=\"nohighlight hljs nim\">{blk.code.highlightNim}</code></pre>"
      nbContainerToHtml(blk, nb)
      if blk.output.len > 0:
        &"<pre class=\"nb-output\">{blk.output}</pre>"

template code*(nb: Nb, body: untyped) =
  let blk = newNbCode()
  blk.code = getCode(body)
  nb.withContainer(blk):
    captureStdout(blk.output):
      body
  nb.add blk

template nbCode*(body: untyped) =
  nb.code:
    body

template codeSkip*(nb: Nb, body: untyped) =
  let blk = newNbCode()
  blk.code = getCode(body)
  nb.add blk

template nbCodeSkip*(body: untyped) =
  nb.codeSkip(body)

#[ template nbCodeSkip*(body: untyped) =
  newNbCodeBlock("nbCodeSkip", body):
    discard ]#

template capture*(nb: Nb, body: untyped) =
  let blk = newNbCode()
  nb.withContainer(blk):
    captureStdout(blk.output):
      body
  nb.add blk

template nbCapture*(body: untyped) =
  nb.capture(body)

#[ template nbCapture*(body: untyped) =
  newNbCodeBlock("nbCapture", body):
    captureStdout(nb.blk.output):
      body ]#

template codeInBlock*(nb: Nb, body: untyped) =
  block:
    nb.code:
      body

template nbCodeInBlock*(body: untyped): untyped =
  nb.codeInBlock:
    body

template nimibCode*(body: untyped) =
  nbCode:
    body

#[ template nimibCode*(body: untyped) =
  newNbCodeBlock("nimibCode", body):
    discard
  body ]#

#[ template nbText*(text: string) =
  newNbSlimBlock("nbText"):
    nb.blk.output = text ]#

newNbBlock(NbText):
  text: string
  toHtml:
    {.cast(noSideEffect).}: # not sure why markdown is marked with side effects
      markdown(blk.text, config=initGfmConfig())

func text*(nb: var Nb, text: string) =
  let blk = newNbText(text=text)
  nb.add blk

template nbText*(ttext: string) =
  nb.text(ttext)

#[ template nbTextWithCode*(body: untyped) =
  newNbCodeBlock("nbText", body):
    nb.blk.output = body ]#

newNbBlock(NbTextWithCode of NbText):
  code: string
  toHtml:
    nbTextToHtml(blk, nb)

template textWithCode*(nb: Nb, body: untyped) =
  let ttext = body
  let tcode = getCode(body)
  let blk = newNbTextWithCode(text=ttext, code=tcode)
  nb.add blk

template nbTextWithCode*(body: untyped) =
  nb.textWithCode:
    body

newNbBlock(NbImage):
  url: string
  caption: string
  alt: string
  toHtml:
    &"""
<figure>
  <img src="{blk.url}" alt="{blk.alt}">
  <figcaption>{blk.caption}</figcaption>
</figure>
"""

func image*(nb: var Nb, turl: string, tcaption = "", talt = "") =
  let blk = newNbImage()
  blk.url = 
    if isAbsolute(turl) or turl.startsWith("http"):
      turl
    else:
      nb.doc.context{"path_to_root"}.getStr / turl
  blk.alt = if talt.len == 0: tcaption else: talt
  blk.caption = tcaption
  nb.add blk

template nbImage*(url: string, caption = "", alt = "") =
  nb.image(url, caption, alt)

#[ template nbImage*(url: string, caption = "", alt = "") =
  newNbSlimBlock("nbImage"):
    nb.blk.context["url"] = nb.relToRoot(url) 
    nb.blk.context["alt_text"] = 
      if alt == "":
        caption
      else:
        alt
        
    nb.blk.context["caption"] = caption ]#

newNbBlock(NbFile):
  filename: string
  ext: string
  content: string
  toHtml:
    &"""
<pre>{blk.filename}</pre>
<pre><code class="{blk.ext} hljs">{blk.content}</code></pre>
"""

proc file*(nb: var Nb, tname: string, tcontent: string) =
  ## Generic string file
  tname.writeFile tcontent
  let blk = newNbFile(filename=tname, ext=tname.getExt, content=tcontent)
  nb.add blk

template file*(nb: Nb, tname: string, body: untyped) =
  ## Read code and write it to file
  let content = getCode(body)
  tname.writeFile content
  let blk = newNbFile(filename=tname, ext=tname.getExt, content=content)
  nb.add blk

proc file*(nb: var Nb, tname: string) =
  ## Read content from a file instead of writing to it
  let content = readFile(tname)
  let blk = newNbFile(filename=tname, ext=tname.getExt, content=content)
  nb.add blk

# todo captions and subtitles support maybe?
template nbVideo*(url: string, typ: string = "", autoplay = false, muted = false, loop: bool = false) =
  newNbSlimBlock("nbVideo"):
    nb.blk.context["url"] = nb.relToRoot(url)
    nb.blk.context["type"] =
      if typ == "": "video/" & url.splitFile.ext[1..^1] # remove the leading dot
      else: typ

    if autoplay: nb.blk.context["autoplay"] = "autoplay"
    if muted: nb.blk.context["muted"] = "muted"
    if loop: nb.blk.context["loop"] = "loop"

template nbAudio*(url: string, typ: string = "", autoplay = false, muted = false, loop: bool = false) =
  newNbSlimBlock("nbAudio"):
    nb.blk.context["url"] = nb.relToRoot(url)
    nb.blk.context["type"] = 
      if typ == "": "audio/" & url.splitFile.ext[1..^1]
      else: typ

    if autoplay: nb.blk.context["autoplay"] = "autoplay"
    if muted: nb.blk.context["muted"] = "muted"
    if loop: nb.blk.context["loop"] = "loop"

template nbFile*(name: string, content: string) =
  nb.file(name, content)

template nbFile*(name: string, body: untyped) =
  nb.file(name, body)

template nbFile*(name: string) =
  nb.file(name)

#[ template nbFile*(name: string, content: string) =
  ## Generic string file
  newNbSlimBlock("nbFile"):
    name.writeFile content
    nb.blk.context["filename"] = name
    nb.blk.context["ext"] = name.getExt
    nb.blk.context["content"] = content

template nbFile*(name: string, body: untyped) =
  newNbCodeBlock("nbFile", body):
    name.writeFile nb.blk.code
    nb.blk.context["filename"] = name
    nb.blk.context["ext"] = name.getExt
    nb.blk.context["content"] = nb.blk.code

template nbFile*(name: string) =
  ## Read content from a file instead of writing to it
  newNbSlimBlock("nbFile"):
    nb.blk.context["filename"] = name
    nb.blk.context["ext"] = name.getExt
    nb.blk.context["content"] = readFile(name) ]#

when moduleAvailable(nimpy):
  newNbBlock(NbPython of NbCode):
    toHtml:
      withNewlines:
        if blk.code.len > 0:
          &"<pre><code class=\"hljs python\">{blk.code}</code></pre>"
        if blk.output.len > 0:
          &"<pre class=\"nb-output\">{blk.output}</pre>"

  template nbInitPython*() =
    import nimpy
    let nbPythonBuiltins = pyBuiltinsModule()

    proc python(nb: var Nb, pythonStr: string) =
      let blk = newNbPython(code = pythonStr)
      captureStdout(blk.output):
          discard nbPythonBuiltins.exec(pythonStr)
      nb.add blk
    
    template nbPython(pythonStr: string) =
      nb.python(pythonStr)

    #[ template nbPython(pythonStr: string) =
      newNbSlimBlock("nbPython"):
        nb.blk.code = pythonStr
        captureStdout(nb.blk.output):
          discard nbPythonBuiltins.exec(pythonStr) ]#

newNbBlock(NbRawHtml):
  html: string
  toHtml:
    blk.html

func rawHtml*(nb: var Nb, content: string) =
  let blk = newNbRawHtml(html = content)
  nb.add blk

template nbRawHtml*(content: string) =
  nb.rawHtml(content)

func show*[T](nb: var Nb, obj: T) =
  nb.rawHtml(obj.toHtml())

template nbShow*(obj: untyped) =
  nb.show(obj)

#[ template nbShow*(obj: untyped) =
  nbRawHtml(obj.toHtml())

template nbRawOutput*(content: string) {.deprecated: "Use nbRawHtml instead".} = 
  nbRawHtml(content)

template nbRawHtml*(content: string) =
  newNbSlimBlock("nbRawHtml"):
    nb.blk.output = content ]#

func nbJsFromStringInit*(body: string): NbBlock =
  newNbJsFromCode(code=body, transformedCode=body, putAtTop=false)

#[ template nbJsFromStringInit*(body: string): NbBlock =
  var result = NbBlock(command: "nbJsFromCode", code: body, context: newContext(searchDirs = @[], partials = nb.partials), output: "")
  result.context["transformedCode"] = body
  result.context["putAtTop"] = false
  result ]#

func addStringToJs*(script: NbJsFromCode or NbJsFromCodeOwnFile, body: string) =
  script.code &= "\n" & body
  script.transformedCode &= "\n" & body

#[ template addStringToJs*(script: NbBlock, body: string) =
  script.code &= "\n" & body
  script.context["transformedCode"] = script.context["transformedCode"].vString & "\n" & body ]#

#[ func addToDocAsJs*(nb: var Nb, script: NbBlock) =
  nb.add script

template addToDocAsJs*(script: NbBlock) =
  nb.blocks.add script
  nb.blk = script ]#

func jsFromString*(nb: var Nb, body: string) =
  let script = nbJsFromStringInit(body)
  nb.add script

template nbJsFromString*(body: string) =
  nb.jsFromString(body)

template jsFromCode*(nb: var Nb, args: varargs[untyped]) =
  let (code, originalCode) = nimToJsString(putCodeInBlock=false, args)
  let blk = newNbJsFromCode(code=originalCode, transformedCode=code, putAtTop=false)
  nb.add blk

template nbJsFromCode*(args: varargs[untyped]) =
  nb.jsFromCode(args)

template jsFromCodeInBlock*(nb: var Nb, args: varargs[untyped]) =
  let (code, originalCode) = nimToJsString(putCodeInBlock=true, args)
  let blk = newNbJsFromCode(code=originalCode, transformedCode=code, putAtTop=false)
  nb.add blk

template nbJsFromCodeInBlock*(args: varargs[untyped]) =
  nb.jsFromCodeInBlock(args)

template jsFromCodeGlobal*(nb: var Nb, args: varargs[untyped]) =
  let (code, originalCode) = nimToJsString(putCodeInBlock=false, args)
  let blk = newNbJsFromCode(code=originalCode, transformedCode=code, putAtTop=true)
  nb.add blk

template nbJsFromCodeGlobal*(args: varargs[untyped]) =
  nb.jsFromCodeGlobal(args)

template jsFromCodeOwnFile*(nb: var Nb, args: varargs[untyped]) =
  let (code, originalCode) = nimToJsString(putCodeInBlock=false, args)
  let blk = newNbJsFromCodeOwnFile(code=originalCode, transformedCode=code)
  nb.add blk

template nbJsFromCodeOwnFile*(args: varargs[untyped]) =
  nb.jsFromCodeOwnFile(args)

#[ template nbJsFromCode*(args: varargs[untyped]) =
  let (code, originalCode) = nimToJsString(putCodeInBlock=false, args)
  var result = NbBlock(command: "nbJsFromCode", code: originalCode, context: newContext(searchDirs = @[], partials = nb.partials), output: "")
  result.context["transformedCode"] = code
  result.context["putAtTop"] = false
  result.addToDocAsJs

template nbJsFromCodeInBlock*(args: varargs[untyped]) =
  let (code, originalCode) = nimToJsString(putCodeInBlock=true, args)
  var result = NbBlock(command: "nbJsFromCode", code: originalCode, context: newContext(searchDirs = @[], partials = nb.partials), output: "")
  result.context["transformedCode"] = code
  result.context["putAtTop"] = false
  result.addToDocAsJs

template nbJsFromCodeGlobal*(args: varargs[untyped]) =
  let (code, originalCode) = nimToJsString(putCodeInBlock=false, args)
  var result = NbBlock(command: "nbJsFromCode", code: originalCode, context: newContext(searchDirs = @[], partials = nb.partials), output: "")
  result.context["transformedCode"] = code
  result.context["putAtTop"] = true
  result.addToDocAsJs

template nbJsFromCodeOwnFile*(args: varargs[untyped]) =
  let (code, originalCode) = nimToJsString(putCodeInBlock=false, args)
  var result = NbBlock(command: "nbJsFromCodeOwnFile", code: originalCode, context: newContext(searchDirs = @[], partials = nb.partials), output: "")
  result.context["transformedCode"] = code
  result.addToDocAsJs

template nbCodeToJs*(args: varargs[untyped]) {.deprecated: "Use nbJsFromCode or nbJsFromString instead".} =
  nbJsFromCode(args) ]#


when moduleAvailable(karax/kbase):
  template karaxCode*(nb: var Nb, args: varargs[untyped]) =
    let rootId = "karax-" & $nb.doc.newId()
    nb.rawHtml: "<div id=\"" & rootId & "\"></div>"
    nbKaraxCodeBackend(rootId, args)

  template nbKaraxCode*(args: varargs[untyped]) =
    nb.karaxCode(args)

when moduleAvailable(happyx):
  template happyxCode*(nb: var Nb, args: varargs[untyped]) =
    let rootId = "happyx-" & $nb.doc.newId()
    nbRawHtml: "<div id=\"" & rootId & "\"></div>"
    nbHappyxCodeBackend(rootId, args)

  template nbHappyxCode*(args: varargs[untyped]) =
    nb.happyxCode(args)

#[ template nbJsShowSource*(message: string = "") {.deprecated: "Use nbCodeDisplay instead".} =
  nb.blk.context["js_show_nim_source"] = true
  if message.len > 0:
    nb.blk.context["js_show_nim_source_message"] = message

template nbCodeToJsShowSource*(message: string = "") {.deprecated: "Use nbCodeDisplay instead".} =
  nbJsShowSource(message) ]#

template codeDisplay*(nb: var Nb, tmplCall: untyped, body: untyped) =
  tmplCall:
    body
  nb.codeSkip:
    body

template nbCodeDisplay*(tmplCall: untyped, body: untyped) =
  ## display codes used in a template (e.g. nbJsFromCode) after the template call
  nb.codeDisplay(tmplCall, body)

template codeAnd*(nb: var Nb, tmplCall: untyped, body: untyped) =
  ## can be used to run code both in c and js backends (e.g. nbCodeAnd(nbJsFromCode))
  nb.code: # this should work because template name starts with nbCode
    body
  tmplCall:
    body

template nbCodeAnd*(tmplCall: untyped, body: untyped) =
  nb.codeAnd(tmplCall, body)

template nbClearOutput*() =
  if not nb.blk.isNil and nb.blk of NbCode:
    nb.blk.NbCode.output = ""

template nbSave* =
  # order if searchDirs/searchTable is relevant: directories have higher priority. rationale:
  #   - in memory partial contains default mustache assets
  #   - to override/customize (for a bunch of documents) the best way is to modify a version on file
  #   - in case you need to manage additional exceptions for a specific document add a new set of partials before calling nbSave
  nb.nbCollectAllNbJs()

  #nb.context.searchDirs(nb.templateDirs)
  #nb.context.searchTable(nb.partials)

  write nb
  if nb.doc.options.show:
    open nb.doc

# how to change this to a better version using nb?
template relPath*(path: AbsoluteFile | AbsoluteDir): string =
  (path.relativeTo nb.homeDir).string

# aliases to minimize breaking changes after refactoring nbDoc -> nb. Should be deprecated at some point?
#[ template nbDoc*: NbDoc = nb
template nbBlock*: NbBlock = nb.blk
template nbHomeDir*: AbsoluteDir = nb.homeDir ]#

# use --nbShow runtime option instead of this
template nbShow* =
  nbSave
  open nb

# the following does not affect user imports but only imports not exported in this module
{. warning[UnusedImport]:off .}

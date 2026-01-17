import std / [strformat, os, strutils, json]
import std / jsonutils except toJson

import ./types, ./blocks, ./capture, ./nimibSugars, ./globals, ./jsons, ./paths, ./docs, ./jsutils

template moduleAvailable*(module: untyped): bool =
  (compiles do: import module)

# block templates

newNbBlock(NbCode of NbContainer):
  code: string
  output: string
  toHtml:
    withNewlines:
      nb.renderPartial("nbCodeSource", jsonutils.toJson(blk))
      nbContainerToHtml(blk, nb)
      nb.renderPartial("nbCodeOutput", jsonutils.toJson(blk))

proc nbCodeToMd(blk: NbBlock, nb: Nb): string =
  let blk = blk.NbCode
  withNewlines:
    if blk.code.len > 0:
      withNewLines:
        "```nim"
        blk.code
        "```"
    if blk.output.len > 0:
      withNewLines:
        "```"
        blk.output
        "```"

nbToMd.funcs["NbCode"] = nbCodeToMd


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

template capture*(nb: Nb, body: untyped) =
  let blk = newNbCode()
  nb.withContainer(blk):
    captureStdout(blk.output):
      body
  nb.add blk

template nbCapture*(body: untyped) =
  nb.capture(body)

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

newNbBlock(NbText):
  text: string
  toHtml:
    nb.renderPartial("nbText", jsonutils.toJson(blk))

func nbTextToMd*(blk: NbBlock, nb: Nb): string =
  blk.NbText.text

nbToMd.funcs["NbText"] = nbTextToMd

func text*(nb: var Nb, text: string) =
  let blk = newNbText(text=text)
  nb.add blk

template nbText*(ttext: string) =
  nb.text(ttext)

newNbBlock(NbTextWithCode of NbText):
  code: string
  toHtml:
    nbTextToHtml(blk, nb)

func nbTextWithCodeToMd*(blk: NbBlock, nb: Nb): string =
  blk.NbTextWithCode.text

nbToMd.funcs["NbTextWithCode"] = nbTextWithCodeToMd

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

func nbImageToMd*(blk: NbBlock, nb: Nb): string =
  let blk = blk.NbImage
  withNewLines:
    &"![{blk.alt}]({blk.url})"
    if blk.caption.len > 0:
      withNewLines:
        ""
        &"**Figure:** {blk.caption}"

nbToMd.funcs["NbImage"] = nbImageToMd

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

newNbBlock(NbFile):
  filename: string
  ext: string
  content: string
  toHtml:
    &"""
<pre>{blk.filename}</pre>
<pre><code class="{blk.ext} hljs">{blk.content}</code></pre>
"""
# Make pre-code with hljs-extensions into a partial! Or a function that calls a partial even? (that constructs the JsNode for us)

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

newNbBlock(NbVideo):
  url: string
  filetype: string
  autoplay: bool
  muted: bool
  loop: bool
  toHtml:
    withNewLines:
      "<video controls"
      if blk.loop: "loop"
      if blk.autoplay: "autoplay"
      if blk.muted: "muted"
      ">"
      &"""<source src="{blk.url}" """
      if blk.filetype.len > 0:
        &"""type="{blk.filetype}" """
      ">"
      "Your browser does not support the video element.</video>"

func video*(nb: var Nb, url: string, filetype: string = "", autoplay = false, muted = false, loop: bool = false) =
  let blk = newNbVideo(autoplay=autoplay, muted=muted, loop=loop)
  blk.url = nb.doc.relToRoot(url)
  blk.filetype = 
    if filetype == "": "video/" & url.splitFile.ext[1..^1] # remove the leading dot
    else: filetype
  nb.add blk
  
# todo captions and subtitles support maybe?
template nbVideo*(url: string, filetype: string = "", autoplay = false, muted = false, loop: bool = false) =
  nb.video(url, filetype, autoplay, muted, loop)

newNbBlock(NbAudio of NbVideo):
  toHtml: 
    withNewLines:
      "<audio controls"
      if blk.loop: "loop"
      if blk.autoplay: "autoplay"
      if blk.muted: "muted"
      ">"
      &"""<source src="{blk.url}" """
      if blk.filetype.len > 0:
        &"""type="{blk.filetype}" """
      ">"
      "Your browser does not support the video element.</audio>"

func audio*(nb: var Nb, url: string, filetype: string = "", autoplay = false, muted = false, loop: bool = false) =
  let blk = newNbAudio(autoplay=autoplay, muted=muted, loop=loop)
  blk.url = nb.doc.relToRoot(url)
  blk.filetype = 
    if filetype == "": "audio/" & url.splitFile.ext[1..^1] # remove the leading dot
    else: filetype
  nb.add blk

template nbAudio*(url: string, filetype: string = "", autoplay = false, muted = false, loop: bool = false) =
  nb.audio(url, filetype, autoplay, muted, loop)

template nbFile*(name: string, content: string) =
  nb.file(name, content)

template nbFile*(name: string, body: untyped) =
  nb.file(name, body)

template nbFile*(name: string) =
  nb.file(name)

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

newNbBlock(NbDiv of NbContainer):
  class: string
  style: string
  toHtml:
    withNewLines:
      &"<div class=\"{blk.class}\" style=\"{blk.style}\">"
      nbContainerToHtml(blk, nb)
      "</div>"

template nbDiv*(classes: string, styles: string, body: untyped) =
  let blk = newNbDiv(class=classes, style=styles)
  nb.withContainer(blk):
    body
  nb.add blk

template nbDiv*(body: untyped) =
  nbDiv("", ""):
    body

func nbJsFromStringInit*(body: string): NbBlock =
  newNbJsFromCode(code=body, transformedCode=body, putAtTop=false)

func addStringToJs*(script: NbJsFromCode or NbJsFromCodeOwnFile, body: string) =
  script.code &= "\n" & body
  script.transformedCode &= "\n" & body

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
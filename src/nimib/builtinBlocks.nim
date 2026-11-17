import std / [strformat, os, strutils, json]
import std / jsonutils except toJson

import ./types, ./blocks, ./capture, ./nimibSugars, ./globals, ./jsons, ./paths, ./docs, ./jsutils, ./renders
from std/cgi import xmlEncode
import ./highlight

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
  width: string
  height: string
  toHtml:
    var sizeAttrs = ""
    if blk.width.len > 0: sizeAttrs.add &" width=\"{blk.width}\""
    if blk.height.len > 0: sizeAttrs.add &" height=\"{blk.height}\""
    &"""
<figure>
  <img src="{blk.url}" alt="{blk.alt}"{sizeAttrs}>
  <figcaption>{blk.caption}</figcaption>
</figure>
"""

func nbImageToMd*(blk: NbBlock, nb: Nb): string =
  ## markdown has no standard syntax for image size: width and height are ignored
  let blk = blk.NbImage
  withNewLines:
    &"![{blk.alt}]({blk.url})"
    if blk.caption.len > 0:
      withNewLines:
        ""
        &"**Figure:** {blk.caption}"

nbToMd.funcs["NbImage"] = nbImageToMd

func image*(nb: var Nb, url: string, caption = "", alt = "", width = "", height = "") =
  ## `width` and `height` are passed as is to the html `width` and `height` attributes
  ## (e.g. "300" for 300 pixels); when empty the image keeps its natural size.
  let blk = newNbImage()
  blk.url = nb.doc.relToRoot(url)
  blk.alt = if alt.len == 0: caption else: alt
  blk.caption = caption
  blk.width = width
  blk.height = height
  nb.add blk

template nbImage*(url: string, caption = "", alt = "", width = "", height = "") =
  nb.image(url, caption, alt, width, height)

newNbBlock(NbFile):
  filename: string
  ext: string
  content: string
  foldable: bool
  folded: bool
  title: string
  firstLine: int  # with `start`, the lines shown (from 1); 0 when the whole file is shown
  lastLine: int
  toHtml:
    let content = blk.content.strip(leading = false, chars = {'\n'})
    let code =
      if blk.ext == "nim": preCodeTag(lang = "nim", code = content.highlightNim, highlight = false)
      else: preCodeTag(lang = blk.ext, code = content.xmlEncode)
    let name = if blk.title.len > 0: inlineMarkdown(blk.title) else: "<code>" & blk.filename.xmlEncode & "</code>"
    let head = name & " <span class=\"nb-small\">" & linesLabel(blk.content, blk.firstLine, blk.lastLine) & "</span>"
    if blk.foldable or blk.folded:
      let open = if blk.folded: "" else: " open"
      withNewlines:
        "<details class=\"nb-file\"" & open & "><summary class=\"nb-file-head\">" & head & "</summary>"
        code
        "</details>"
    else:
      withNewlines:
        "<div class=\"nb-file\"><div class=\"nb-file-head\">" & head & "</div>"
        code
        "</div>"

func nbFileToMd(blk: NbBlock, nb: Nb): string =
  let blk = blk.NbFile
  let name = if blk.title.len > 0: blk.title else: "`" & blk.filename & "`"
  let fence = "```" & blk.ext & "\n" & blk.content.strip(leading = false, chars = {'\n'}) & "\n```"
  if blk.foldable or blk.folded:
    let open = if blk.folded: "" else: " open"
    "<details" & open & "><summary>" & name & " (" & linesLabel(blk.content, blk.firstLine, blk.lastLine) & ")</summary>\n\n" & fence & "\n\n</details>"
  else:
    name & " (" & linesLabel(blk.content, blk.firstLine, blk.lastLine) & ")\n\n" & fence

nbToMd.funcs["NbFile"] = nbFileToMd

func langOf(name: string): string =
  ## The language of a file for highlighting: its extension (`nims` is `nim`).
  result = name.getExt
  if result == "nims": result = "nim"

func codeSlice*(code, start, stop: string): tuple[code: string, first, last: int] =
  ## The part of `code` from the first line that holds `start` up to the line before the next one
  ## that holds `stop` (or to the end), dedented, with its first and last line numbers (from 1).
  ## Empty `start` means the whole code, and lines 0..0.
  if start.len == 0: return (code, 0, 0)
  let i = code.find(start)
  if i < 0: raise newException(ValueError, "nbFile: no line holds " & start.escape)
  let from0 = code.rfind('\n', last = i) + 1
  var part = code[from0 .. ^1]
  if stop.len > 0:
    let firstNl = part.find('\n')
    let j = if firstNl < 0: -1 else: part.find(stop, start = firstNl + 1)
    if j >= 0: part = part[0 ..< part.rfind('\n', last = j) + 1]
  let first = code[0 ..< from0].count('\n') + 1
  let last = first + part.strip(leading = false, chars = {'\n'}).countLines - 1
  (part.dedent, first, last)

proc file*(nb: var Nb, name: string, content: string, foldable = false, folded = false, title = "") =
  ## Writes `content` to the file `name` and shows it.
  name.writeFile content
  let blk = newNbFile(filename=name, ext=langOf(name), content=content, foldable=foldable, folded=folded, title=title)
  nb.add blk

template file*(nb: Nb, name: string, body: untyped) =
  ## Read code and write it to file
  let content = getCode(body)
  name.writeFile content
  let blk = newNbFile(filename=name, ext=langOf(name), content=content)
  nb.add blk

proc file*(nb: var Nb, name: string, foldable = false, folded = false, start = "", stop = "",
           title = "", lang = "") =
  ## Shows the file `name` (a path from the current directory, or from the document's folder),
  ## under its name (or `title`, in Markdown) and its number of lines. `foldable` lets a reader
  ## close it; `folded` shows it closed (and foldable). Folded files one after the other make a list. With `start`, it shows only from the first
  ## line that holds `start`, up to the line before the next one that holds `stop` (or to the end).
  ## `lang` overrides the language given by the extension.
  let path = if fileExists(name) or not fileExists(nb.doc.thisDir.string / name): name
             else: nb.doc.thisDir.string / name
  let (content, firstLine, lastLine) = readFile(path).codeSlice(start, stop)
  let lang = if lang.len > 0: lang else: langOf(name)
  let blk = newNbFile(filename=name, ext=lang, content=content, foldable=foldable, folded=folded, title=title,
                      firstLine=firstLine, lastLine=lastLine)
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

template nbFile*(name: string, content: string, foldable = false, folded = false, title = "") =
  ## Writes `content` to the file `name` and shows it (`foldable` and `folded`: see below).
  nb.file(name, content, foldable, folded, title)

template nbFile*(name: string, body: untyped) =
  nb.file(name, body)

template nbFile*(name: string, foldable = false, folded = false, start = "", stop = "", title = "",
                 lang = "") =
  ## Shows the file `name`: `nbFile "src/main.nim"`, under its name and its number of lines.
  ## `foldable = true` lets a reader close it, `folded = true` shows it closed; `start` (and `stop`)
  ## show only a part of it; `title` (Markdown) goes in place of the name, `lang` in place of the
  ## extension.
  nb.file(name, foldable, folded, start, stop, title, lang)

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
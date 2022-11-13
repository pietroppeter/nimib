import std/[os, strutils, sugar, strformat, macros, macrocache, sequtils, jsonutils]
export jsonutils
import nimib / [types, blocks, docs, boost, config, options, capture, jsutils]
export types, blocks, docs, boost, sugar, jsutils
# types exports mustache, tables, paths

from nimib / themes import nil
export themes.useLatex, themes.darkMode, themes.`title=`

from nimib / renders import nil

from mustachepkg/values import searchTable, searchDirs, castStr
export searchTable, searchDirs, castStr

template moduleAvailable*(module: untyped): bool =
  (compiles do: import module)

template nbInit*(theme = themes.useDefault, backend = renders.useHtmlBackend, thisFileRel = "") =
  var nb {.inject.}: NbDoc
  nb.initDir = getCurrentDir().AbsoluteDir
  loadOptions nb
  loadCfg nb

  # nbInit can be called not from inside the correct file (e.g. when rendering markdown files in nimibook)
  if thisFileRel == "":
    nb.thisFile = instantiationInfo(-1, true).filename.AbsoluteFile
  else:
    nb.thisFile = nb.srcDir / thisFileRel.RelativeFile
    echo "[nimib] thisFile: ", nb.thisFile

  try:
    nb.source = read(nb.thisFile)
  except IOError:
    echo "[nimib] cannot read source"

  if nb.options.filename == "":
    nb.filename = nb.thisFile.string.splitFile.name & ".html"
  else:
    nb.filename = nb.options.filename

  if nb.cfg.srcDir != "":
    echo "[nimib] srcDir: ", nb.srcDir
    nb.filename = (nb.thisDir.relativeTo nb.srcDir).string / nb.filename
    echo "[nimib] filename: ", nb.filename

  if nb.cfg.homeDir != "":
    echo "[nimib] setting current directory to nb.homeDir: ", nb.homeDir
    setCurrentDir nb.homeDir

  # can be overriden by theme, but it is better to initialize this anyway
  nb.templateDirs = @["./", "./templates/"]
  nb.partials = initTable[string, string]()
  nb.context = newContext(searchDirs = @[]) # templateDirs and partials added during nbSave

  # apply render backend (default backend can be overriden by theme)
  backend nb

  # apply theme
  theme nb

template nbInitMd* = nbInit(backend=renders.useMdBackend, theme=themes.noTheme)

# block generation templates
template newNbCodeBlock*(cmd: string, body, blockImpl: untyped) =
  newNbBlock(cmd, true, nb, nb.blk, body, blockImpl)

template newNbSlimBlock*(cmd: string, blockImpl: untyped) =
  # a slim block is a block with no body
  newNbBlock(cmd, false, nb, nb.blk, "", blockImpl)

# block templates
template nbCode*(body: untyped) =
  newNbCodeBlock("nbCode", body):
    captureStdout(nb.blk.output):
      body

template nbCodeInBlock*(body: untyped): untyped =
  block:
    nbCode:
      body

template nbText*(text: string) =
  newNbSlimBlock("nbText"):
    nb.blk.output = text

template nbTextWithCode*(body: untyped) =
  newNbCodeBlock("nbText", body):
    nb.blk.output = body

template nbImage*(url: string, caption = "") =
  newNbSlimBlock("nbImage"):
    nb.blk.context["url"] = nb.relToRoot(url)
    nb.blk.context["caption"] = caption

template nbVideo*(url: string) =
  newNbSlimBlock("nbVideo"):
    nb.blk.context["url"] = nb.relToRoot(url)
    nb.blk.context["ext"] = url.splitFile.ext

template nbFile*(name: string, content: string) =
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

when moduleAvailable(nimpy):
  template nbInitPython*() =
    import nimpy
    let nbPythonBuiltins = pyBuiltinsModule()

    template nbPython(pythonStr: string) =
      newNbSlimBlock("nbPython"):
        nb.blk.code = pythonStr
        captureStdout(nb.blk.output):
          discard nbPythonBuiltins.exec(pythonStr)

template nbRawOutput*(content: string) {.deprecated: "Use nbRawHtml instead".} = 
  nbRawHtml(content)

template nbRawHtml*(content: string) =
  newNbSlimBlock("nbRawHtml"):
    nb.blk.output = content

template nbJsFromStringInit*(body: string): NbBlock =
  var result = NbBlock(command: "nbCodeToJs", code: body, context: newContext(searchDirs = @[], partials = nb.partials), output: "")
  result.context["transformedCode"] = body
  result

template nbJsFromCodeInit*(args: varargs[untyped]): NbBlock =
  let (code, originalCode) = nimToJsString(true, args)
  var result = NbBlock(command: "nbCodeToJs", code: originalCode, context: newContext(searchDirs = @[], partials = nb.partials), output: "")
  result.context["transformedCode"] = code
  result

template nbCodeToJsInit*(args: varargs[untyped]): NbBlock {.deprecated: "Use nbJsFromCodeInit or nbJsFromStringInit instead".} =
  nbJsFromCodeInit(args)

template addCodeToJs*(script: NbBlock, args: varargs[untyped]) =
  let (code, originalCode) = nimToJsString(false, args)
  script.code &= "\n" & originalCode
  script.context["transformedCode"] = script.context["transformedCode"].vString & "\n" & code

template addStringToJs*(script: NbBlock, body: string) =
  script.code &= "\n" & body
  script.context["transformedCode"] = script.context["transformedCode"].vString & "\n" & body

template addToDocAsJs*(script: NbBlock) =
  nb.blocks.add script
  nb.blk = script

template nbJsFromString*(body: string) =
  let script = nbJsFromStringInit(body)
  script.addToDocAsJs

template nbJsFromCode*(args: varargs[untyped]) =
  let script = nbJsFromCodeInit(args)
  script.addToDocAsJs

template nbCodeToJs*(args: varargs[untyped]) {.deprecated: "Use nbJsFromCode or nbJsFromString instead".} =
  nbJsFromCode(args)


when moduleAvailable(karax/kbase):
  template nbKaraxCode*(args: varargs[untyped]) =
    let rootId = "karax-" & $nb.newId()
    nbRawOutput: "<div id=\"" & rootId & "\"></div>"
    nbKaraxCodeBackend(rootId, args)

template nbJsShowSource*(message: string = "") =
  nb.blk.context["js_show_nim_source"] = true
  if message.len > 0:
    nb.blk.context["js_show_nim_source_message"] = message

template nbCodeToJsShowSource*(message: string = "") {.deprecated: "Use nbJsShowSource instead".} =
  nbJsShowSource(message)


template nbClearOutput*() =
  if not nb.blk.isNil:
    nb.blk.output = ""
    nb.blk.context["output"] = ""

template nbSave* =
  # order if searchDirs/searchTable is relevant: directories have higher priority. rationale:
  #   - in memory partial contains default mustache assets
  #   - to override/customize (for a bunch of documents) the best way is to modify a version on file
  #   - in case you need to manage additional exceptions for a specific document add a new set of partials before calling nbSave
  nb.context.searchDirs(nb.templateDirs)
  nb.context.searchTable(nb.partials)

  write nb
  if nb.options.show:
    open nb

# how to change this to a better version using nb?
template relPath*(path: AbsoluteFile | AbsoluteDir): string =
  (path.relativeTo nb.homeDir).string

# aliases to minimize breaking changes after refactoring nbDoc -> nb. Should be deprecated at some point?
template nbDoc*: NbDoc = nb
template nbBlock*: NbBlock = nb.blk
template nbHomeDir*: AbsoluteDir = nb.homeDir

# use --nbShow runtime option instead of this
template nbShow* =
  nbSave
  open nb

# the following does not affect user imports but only imports not exported in this module
{. warning[UnusedImport]:off .}

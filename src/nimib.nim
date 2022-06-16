import std/[os, strutils, sugar, strformat, macros, macrocache, sequtils, jsonutils]
export jsonutils
import nimib / [types, blocks, docs, boost, config, options, capture]
export types, blocks, docs, boost, sugar
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
    nb.blk.context["url"] =
      if isAbsolute(url) or url[0..3] == "http":
        url
      else:
        nb.context["path_to_root"].vString / url
    nb.blk.context["caption"] = caption

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

template nbRawOutput*(content: string) =
  newNbSlimBlock("nbRawOutput"):
    nb.blk.output = content



proc contains*(tab: CacheTable, keyToCheck: string): bool =
  for key, val in tab:
    if key == keyToCheck:
      return true
  return false

const validCodeTable = CacheTable"validCodeTable"
const invalidCodeTable = CacheTable"invalidCodeTable"

macro typedChecker(n: typed): untyped = discard
macro checkIsValidCode(n: untyped): untyped =
  result = quote do:
    when compiles(typedChecker(`n`)):
      true
    else:
      false

macro addValid(key: string, s: typed): untyped =
  # If it is valid we want it typed
  validCodeTable[key.strVal] = s

macro addInvalid(key: string, s: untyped): untyped =
  # If it is invalid we want it untyped
  invalidCodeTable[key.strVal] = s

proc degensymAst(n: NimNode) =
  for i in 0 ..< n.len:
    case n[i].kind
    of nnkIdent, nnkSym:
      let str = n[i].strVal
      if "`gensym" in str:
        let newStr = str.split("`gensym")[0]
        n[i] = ident(newStr)
        echo "Swapped ", str, " for ", newStr
    else:
      degensymAst(n[i])

proc genCapturedAssignment*(capturedVariables, capturedTypes: seq[NimNode]): tuple[code: NimNode, placeholders: seq[NimNode]] =
  result.code = newStmtList()
  # generate fromJSON loading and then add entire body afterwards
  if capturedVariables.len > 0:
    result.code.add quote do:
      import std/json
    for (cap, capType) in zip(capturedVariables, capturedTypes):
      let placeholder = gensym(ident="placeholder")
      result.placeholders.add placeholder
      result.code.add quote do:
        let `cap` = parseJson(`placeholder`).to(`capType`)

macro nimToJsStringSecondStage*(key: static string, captureVars: varargs[typed]): untyped =
  let captureVars = toSeq(captureVars)
  echo "Capture: ", captureVars.repr

  let captureTypes = collect:
    for cap in captureVars:
      echo cap.lisprepr
      cap.getTypeInst

  echo "Capture types: ", captureTypes

  # dispatch either to string based if the body has type string
  # or to typed version otherwise.
  var body: NimNode
  if key in validCodeTable: # type information is available in this branch
    body = validCodeTable[key]
    if captureVars.len == 0 and body.getType.typeKind == ntyString:
      # It is a string, return it as is is.
      result = body
      return
    elif captureVars.len > 0 and body.getType.typeKind == ntyString:
        error("When passing in a string capturing variables is not supported!", body)
    #elif body.getType.typeKind != ntyVoid:
    #  error("Script expression must be discarded", body)
    else:
      # It is not a string, don't do anything here
      discard
  elif key in invalidCodeTable:
    body = invalidCodeTable[key]
  else:
    error(&"Nimib error: key {key} not in any of the tables. Please open an issue on Github with the failing part of your code")
  # Now we have the body!
  # 1. Generate the captured variable assignments and return placeholders
  let (capAssignments, placeholders) = genCapturedAssignment(captureVars, captureTypes)
  echo "capAssignment: ", capAssignments.repr
  echo "placeholders: ", placeholders.repr
  # 2. Stringify code
  let code = newStmtList(capAssignments, body).copyNimTree()
  code.degensymAst()
  var codeText = code.toStrLit
  echo "Code before replacement: -------------\n", codeText.strVal, "\n################"
  # 3. Generate code which does the serialization and replacement of placeholders
  #    It should return the final string
  let codeTextIdent = genSym(NimSymKind.nskVar ,ident="codeText")
  result = newStmtList()
  result.add newVarStmt(codeTextIdent, codeText)
  for i in 0 .. captureVars.high:
    let placeholder = placeholders[i].repr.newLit
    let varIdent = captureVars[i]
    let serializedValue = quote do: # TODO: escape " in JSON
      $(toJson(`varIdent`))
    result.add quote do:
      `codeTextIdent` = `codeTextIdent`.replace(`placeholder`, "\"\"\"" & `serializedValue` & "\"\"\"")
  result.add codeTextIdent
  echo "Final code: -----------------\n", result.repr, "\n#############"

  #result = quote do:
  #  "hello"
    

macro nimToJsString*(args: varargs[untyped]): untyped =
  echo args.len, " ", args.treerepr
  if args.len == 0:
    error("nbNewCode needs a code block to be passed", args)
  
  let body = args[^1]
  let captureVars =
    if args.len == 1:
      @[]
    else:
      args[0 ..< ^1]
  
  # Save UNTYPED body for access later. 
  # It's important that it is untyped to be able to combine
  # multiple code snippets.
  let key = body.repr
  #bodyCacheTable[key] = body

  result = newStmtList()
  result.add quote do:
    when checkIsValidCode(`body`):
      addValid(`key`, `body`)
    else:
      addInvalid(`key`, `body`)
  var nextArgs = @[newLit(key)]
  nextArgs.add captureVars
  result.add newCall("nimToJsStringSecondStage", nextArgs)

type
  NbCodeScript* = ref object
    code*: string

template nbNewCode*(args: varargs[untyped]): NbCodeScript =
  # 1. preprocess code, get back idents to replace with the value
  # 2. Generate code which does the replacement and stringifies code
  # How to loop over each of the variables in the C-code to run replace for each of them?
  # 2. stringify code
  # 3. replace idents from preprocessing with their json values
  # The problem is the overloading so body must be type-checked to see which one to call
  let code = nimToJsString(args)
  echo code
  NbCodeScript(code: code)

template addCode*(script: NbCodeScript, args: varargs[untyped]) =
  script.code &= "\n" & nimToJsString(args)

template addToDocAsJs*(script: NbCodeScript) =
  let tempdir = getTempDir() / "nimib"
  createDir(tempdir)
  block:
    let nimfile {.inject.} = tempdir / "code.nim"
    echo nimfile
    let jsfile {.inject.} = tempdir / "out.js"
    writeFile(nimfile, script.code)
    let errorCode = execShellCmd(fmt"nim js -d:danger -o:{jsfile} {nimfile}")
    if errorCode != 0:
      raise newException(OSError, "The compilation of a javascript file failed! Did you remember to capture all needed variables?")
    let jscode = readFile(jsfile)
    nbRawOutput: "<script>\n" & jscode & "\n</script>"

template nbJsCode*(args: varargs[untyped]) =
  let script = nbNewCode(args)
  script.addToDocAsJs



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

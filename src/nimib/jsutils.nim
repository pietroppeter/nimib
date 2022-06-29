import std / [macros, macrocache, tables, strutils, strformat, sequtils, sugar]


proc contains(tab: CacheTable, keyToCheck: string): bool =
  for key, val in tab:
    if key == keyToCheck:
      return true
  return false

const validCodeTable = CacheTable"validCodeTable"
const invalidCodeTable = CacheTable"invalidCodeTable"
var tabMapIdents {.compiletime.}: Table[string, NimNode]

macro typedChecker(n: typed): untyped = discard
macro checkIsValidCode(n: untyped): untyped =
  result = quote do:
    when compiles(typedChecker(`n`)):
      true
    else:
      false

macro addValid(key: string, s: typed): untyped =
  # If it is valid we want it typed
  if key.strVal notin validCodeTable:
    validCodeTable[key.strVal] = s

macro addInvalid(key: string, s: untyped): untyped =
  # If it is invalid we want it untyped
  if key.strVal notin invalidCodeTable:
    invalidCodeTable[key.strVal] = s

proc degensymAst(n: NimNode) =
  for i in 0 ..< n.len:
    case n[i].kind
    of nnkIdent, nnkSym:
      let str = n[i].strVal
      if "`gensym" in str:
        let newStr = str.split("`gensym")[0]
        var newSym: NimNode
        # If this symbol is already used in this script, use the gensym'd symbol from 
        if newStr in tabMapIdents:
          newSym = tabMapIdents[newStr]
        else: # else create a gensym'd symbol and add it to the table
          newSym = gensym(ident=newStr).repr.ident
          tabMapIdents[newStr] = newSym
        n[i] = newSym
        echo "Swapped ", str, " for ", newSym.repr
      # TODO: What if the symbols aren't gensym'd? In all cases when this is relevant they are defined in a template so we should be fine?
    else:
      degensymAst(n[i])

proc genCapturedAssignment(capturedVariables, capturedTypes: seq[NimNode]): tuple[code: NimNode, placeholders: seq[NimNode]] =
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

  let captureTypes = collect:
    for cap in captureVars:
      cap.getTypeInst

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
      # It is not a string, get the untyped body instead then
      body = invalidCodeTable[key]
  elif key in invalidCodeTable:
    body = invalidCodeTable[key]
  else:
    error(&"Nimib error: key {key} not in any of the tables. Please open an issue on Github with a minimal reproducible example")
  # Now we have the body!
  # 1. Generate the captured variable assignments and return placeholders
  let (capAssignments, placeholders) = genCapturedAssignment(captureVars, captureTypes)
  # 2. Stringify code
  let code = newStmtList(capAssignments, body).copyNimTree()
  code.degensymAst()
  var codeText = code.toStrLit
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

  #result = quote do:
  #  "hello"
    
macro nimToJsString*(isNewScript: static bool, args: varargs[untyped]): untyped =
  if args.len == 0:
    error("nbNewCode needs a code block to be passed", args)
  
  # If new script, clear the table.
  if isNewScript:
    tabMapIdents.clear()

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
      addInvalid(`key`, `body`) # Add this here as we want to keep the untyped body as well
    else:
      addInvalid(`key`, `body`)
  var nextArgs = @[newLit(key)]
  nextArgs.add captureVars
  result.add newCall("nimToJsStringSecondStage", nextArgs)
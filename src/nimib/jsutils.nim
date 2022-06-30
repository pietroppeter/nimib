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

proc degensymAst(n: NimNode, removeGensym = false) =
  for i in 0 ..< n.len:
    case n[i].kind
    of nnkIdent, nnkSym:
      let str = n[i].strVal
      if "`gensym" in str:
        let newStr = str.split("`gensym")[0]
        var newSym: NimNode
        if removeGensym: # remove gensym all together, useful for removing gensym noise when showing code
          newSym = ident(newStr)
        else: # replace gensym with one that is accepted by the parser
           # If this symbol is already used in this script, use the gensym'd symbol from tabMapIdents
          if newStr in tabMapIdents:
            newSym = tabMapIdents[newStr]
          else: # else create a gensym'd symbol and add it to the table
            newSym = gensym(ident=newStr).repr.ident
            tabMapIdents[newStr] = newSym
        n[i] = newSym
        echo "Swapped ", str, " for ", newSym.repr
    else:
      degensymAst(n[i], removeGenSym)

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
      result = nnkTupleConstr.newTree(body, body) #body # return tuple of (body, body)
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
  body = body.copyNimTree()
  # 1. Generate the captured variable assignments and return placeholders
  let (capAssignments, placeholders) = genCapturedAssignment(captureVars, captureTypes)
  # 2. Stringify code
  let code = newStmtList(capAssignments, body).copyNimTree()
  code.degensymAst()
  var codeText = code.toStrLit
  # 3. Generate code which does the serialization and replacement of placeholders
  let codeTextIdent = genSym(NimSymKind.nskVar ,ident="codeText")
  result = newStmtList()
  result.add newVarStmt(codeTextIdent, codeText)
  for i in 0 .. captureVars.high:
    let placeholder = placeholders[i].repr.newLit
    let varIdent = captureVars[i]
    let serializedValue = quote do:
      $(toJson(`varIdent`))
    result.add quote do:
      `codeTextIdent` = `codeTextIdent`.replace(`placeholder`, "\"\"\"" & `serializedValue` & "\"\"\"")
  # return tuple of the transformed code to be compiled and the prettified code for visualization
  body.degensymAst(removeGenSym=true) # remove `gensym if code was written in a template
  result.add nnkTupleConstr.newTree(codeTextIdent, body.toStrLit)
    
macro nimToJsString*(isNewScript: static bool, args: varargs[untyped]): untyped =
  if args.len == 0:
    error("nbCodeToJs needs a code block to be passed", args)
  
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

macro nbKaraxCodeBackend*(rootId: untyped, args: varargs[untyped]) =
  if args.len == 0:
    error("nbKaraxCode needs a code block to be passed", args)
  
  let body = args[^1]
  let captureVars =
    if args.len == 1:
      @[]
    else:
      args[0 ..< ^1]
  
  let newBody = quote do:
    import karax / [kbase, karax, karaxdsl, vdom, compact, jstrutils, kdom]

    template karaxHtml(body: untyped) =
      proc createDom(): VNode =
        result = buildHtml(tdiv):
          body # html karax code
      setRenderer(createDom, root=`rootId`.cstring)

    `body`

  var callArgs = @[rootId]
  callArgs.add captureVars
  callArgs.add newBody

  let call = newCall(ident"nbCodeToJs", callArgs)

  result = call
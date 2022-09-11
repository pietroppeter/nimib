import std / [macros, macrocache, tables, strutils, strformat, sequtils, sugar]


proc contains(tab: CacheTable, keyToCheck: string): bool =
  for key, val in tab:
    if key == keyToCheck:
      return true
  return false

#const validCodeTable = CacheTable"validCodeTable"
const bodyCache = CacheTable"bodyCache"
var tabMapIdents {.compiletime.}: Table[string, NimNode]

#[ macro typedChecker(n: typed): untyped = discard
macro checkIsValidCode(n: untyped): untyped =
  result = quote do:
    when compiles(typedChecker(`n`)):
      true
    else:
      false ]#

# remove this
#[ macro addValid(key: string, s: typed): untyped =
  # If it is valid we want it typed
  if key.strVal notin validCodeTable:
    validCodeTable[key.strVal] = s ]#

macro addBody(key: string, s: untyped): untyped =
  if key.strVal notin bodyCache:
    bodyCache[key.strVal] = s

proc isPragmaExportc(n: NimNode): bool =
  ## Returns whether pragma contains exportc
  n.expectKind(nnkPragma)
  for child in n:
    if child.kind == nnkExprColonExpr: # {.exportc: "newName".}
      if child[0].eqIdent("exportc"):
        result = true
    elif child.kind == nnkIdent:
      if child.eqIdent("exportc"): # {.exportc.}
        result = true

proc gensymProcIterConverter(n: NimNode, replaceProcs: bool) =
  ## By default procs, iterators and converters are injected and will share the same name in the resulting javascript.
  ## Therefore we gensym them here to give them unique names. Also replace the references to it.
  ## replaceProcs: whether to replace procs names or not. It will replace existing names regardless.
  for i in 0 ..< n.len:
    case n[i].kind
    of nnkProcDef, nnkIteratorDef, nnkConverterDef:
      if replaceProcs:
        # add check for {.exportc.} here
        var isExportc: bool
        let pragmas = n[i][4]
        if pragmas.kind == nnkPragma:
          isExportc = isPragmaExportc(pragmas)
        # Do not gensym if proc is exportc'ed
        if not isExportc:
          if n[i][0].kind == nnkPostfix: # foo*
            let oldIdent = n[i][0][1].strVal.nimIdentNormalize
            let newIdent = gensym(ident=oldIdent).repr.ident
            n[i][0][1] = newIdent
            tabMapIdents[oldIdent] = newIdent
          else:
            let oldIdent = n[i][0].strVal.nimIdentNormalize
            let newIdent = gensym(ident=oldIdent).repr.ident
            n[i][0] = newIdent
            tabMapIdents[oldIdent] = newIdent
      # Function might be recursive or contain other procs, loop through it's body as well
      for child in n[i][6]:
        gensymProcIterConverter(child, replaceProcs)
    of nnkLambda:
      # rewrite from:
      # proc () = discard
      # to
      # block:
      #   proc lambda_gensym() = discard
      #   lambda_gensym
      let p = nnkProcDef.newTree()
      n[i].copyChildrenTo p
      let newIdent = gensym(ident="lambda")
      p[0] = newIdent
      # loop through proc body as well
      for child in p[6]:
        gensymProcIterConverter(child, replaceProcs)
      n[i] = newStmtList(p, newIdent)
    of nnkSym, nnkIdent:
      let oldIdent = n[i].strVal.nimIdentNormalize
      if oldIdent in tabMapIdents:
        n[i] = tabMapIdents[oldIdent]
    of nnkCall:
      # Check if it is karaxHtml:
      # if so set replaceProcs = false for the children
      if n[i][0].eqIdent("karaxHtml"):
        gensymProcIterConverter(n[i][1], false)
      else:
        gensymProcIterConverter(n[i], replaceProcs)
    else:
      gensymProcIterConverter(n[i], replaceProcs)

proc degensymAst(n: NimNode, removeGensym = false) =
  for i in 0 ..< n.len:
    case n[i].kind
    of nnkIdent, nnkSym:
      let str = n[i].strVal
      if "`gensym" in str:
        let newStr = str.split("`gensym")[0].nimIdentNormalize
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
    of nnkPragmaExpr:
      let identifier = n[i][0]
      let pragmas = n[i][1]
      if pragmas.isPragmaExportc: # varName {.exportc.}
        echo "Saved: ", identifier.repr, " -> ", identifier.strVal.split("`gensym")[0].ident.repr
        n[i][0] = identifier.strVal.split("`gensym")[0].ident
      else:
        degensymAst(identifier, removeGensym)
        degensymAst(pragmas, removeGensym)
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
  if key in bodyCache:
    body = bodyCache[key]
  else:
    error(&"Nimib error: key {key} not in any of the tables. Please open an issue on Github with a minimal reproducible example")
  # Now we have the body!
  body = body.copyNimTree()
  # 1. Generate the captured variable assignments and return placeholders
  let (capAssignments, placeholders) = genCapturedAssignment(captureVars, captureTypes)
  # 2. Stringify code
  let code = newStmtList(capAssignments, body).copyNimTree()
  code.gensymProcIterConverter(replaceProcs=true)
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
    error("nbJsFromCode needs a code block to be passed", args)
  
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
    addBody(`key`, `body`)
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

    var postRenderCallback: proc () = nil

    template postRender(body: untyped) =
      ## Must be called before karaxHtml!!!
      proc tempProc () =
        body
      postRenderCallback = tempProc

    template karaxHtml(body: untyped) =
      proc createDom(): VNode =
        result = buildHtml(tdiv):
          body # html karax code
      setRenderer(createDom, root=`rootId`.cstring, clientPostRenderCallback = postRenderCallback)

    `body`

  var callArgs = @[rootId]
  callArgs.add captureVars
  callArgs.add newBody

  let call = newCall(ident"nbJsFromCode", callArgs)

  result = call
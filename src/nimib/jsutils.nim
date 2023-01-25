import std / [macros, macrocache, tables, strutils, strformat, sequtils, sugar, os, hashes]
import ./types

proc contains(tab: CacheTable, keyToCheck: string): bool =
  for key, val in tab:
    if key == keyToCheck:
      return true
  return false

const bodyCache = CacheTable"bodyCache"

macro addBody(key: string, s: untyped): untyped =
  if key.strVal notin bodyCache:
    bodyCache[key.strVal] = s

proc degensymAst(n: NimNode) =
  for i in 0 ..< n.len:
    case n[i].kind
    of nnkIdent, nnkSym:
      let str = n[i].strVal
      if "`gensym" in str:
        let newStr = str.split("`gensym")[0]
        let newSym = ident(newStr)
        n[i] = newSym
    else:
      degensymAst(n[i])

proc genCapturedAssignment(capturedVariables, capturedTypes: seq[NimNode]): tuple[code: NimNode, placeholders: seq[NimNode]] =
  result.code = newStmtList()
  # generate fromJSON loading and then add entire body afterwards
  if capturedVariables.len > 0:
    for (cap, capType) in zip(capturedVariables, capturedTypes):
      let placeholder = gensym(ident="placeholder")
      
      let newSym = cap
      result.placeholders.add placeholder
      result.code.add quote do:
        let `newSym` = parseJson(`placeholder`).to(`capType`) # we must gensym `cap` as well!

macro nimToJsStringSecondStage*(key: static string, putCodeInBlock: static bool, captureVars: varargs[typed]): untyped =
  let captureVars = toSeq(captureVars)

  let captureTypes = collect:
    for cap in captureVars:
      cap.getTypeInst

  # Get the untyped body from CacheTable
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
  var code = newStmtList(capAssignments, body).copyNimTree()
  code.degensymAst()

  if putCodeInBlock:
    code = newBlockStmt(code)
  var codeText = code.toStrLit
  # 3. Generate code which does the serialization and replacement of placeholders
  let codeTextIdent = genSym(NimSymKind.nskVar, ident="codeText")
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
  body.degensymAst() # remove `gensym if code was written in a template
  result.add nnkTupleConstr.newTree(codeTextIdent, body.toStrLit)
    
macro nimToJsString*(putCodeInBlock: static bool, args: varargs[untyped]): untyped =
  if args.len == 0:
    error("nbJsFromCode needs a code block to be passed", args)

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
  var nextArgs = @[newLit(key), newLit(putCodeInBlock)]
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

  let call = newCall(ident"nbJsFromCodeOwnFile", callArgs)

  result = call

proc compileNimToJs*(doc: var NbDoc, blk: var NbBlock) =
  let tempdir = getTempDir() / "nimib"
  createDir(tempdir)
  let (dir, filename, ext) = doc.thisFile.splitFile()
  let nimfile = dir / (filename & "_nbCodeToJs_" & $doc.newId() & ext).RelativeFile
  let jsfile = tempdir / &"out{hash(doc.thisFile)}.js"
  var codeText = blk.context["transformedCode"].vString
  let nbJsCounter = doc.nbJsCounter
  doc.nbJsCounter += 1
  var bumpGensymString = """
import std/[macros, json]

macro bumpGensym(n: static int) =
  for i in 0 .. n:
    let _ = gensym()

"""
  bumpGensymString.add &"bumpGensym({nbJsCounter})\n"
  codeText = bumpGensymString & codeText
  writeFile(nimfile, codeText)
  let kxiname = "nimib_kxi_" & $doc.newId()
  let errorCode = execShellCmd(&"nim js -d:danger -d:kxiname=\"{kxiname}\" -o:{jsfile} {nimfile}")
  if errorCode != 0:
    raise newException(OSError, "The compilation of a javascript file failed! Did you remember to capture all needed variables?\n" & $nimfile)
  removeFile(nimfile)
  let jscode = readFile(jsfile)
  removeFile(jsfile)
  blk.output = jscode
  blk.context["output"] = jscode

proc nbCollectAllNbJs*(doc: var NbDoc) =
  var topCode = "" # placed at the top (nbJsFromCodeGlobal)
  var code = ""
  for blk in doc.blocks:
    if blk.command == "nbJsFromCode":
      if blk.context["putAtTop"].vBool:
        topCode.add "\n" & blk.context["transformedCode"].vString
      else:
        code.add "\n" & blk.context["transformedCode"].vString
  code = topCode & "\n" & code

  if not code.isEmptyOrWhitespace:
    # Create block which which will compile the code when rendered (nbJsFromJsOwnFile)
    var blk = NbBlock(command: "nbJsFromCodeOwnFile", code: code, context: newContext(searchDirs = @[], partials = doc.partials), output: "")
    blk.context["transformedCode"] = code
    doc.blocks.add blk
    doc.blk = blk

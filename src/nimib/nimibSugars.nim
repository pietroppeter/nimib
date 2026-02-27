import std / [macros, strutils, sequtils, genasts]

proc parseCallStmt(n: NimNode): tuple[lhs: string, rhs: NimNode] =
  n.expectKind nnkCall
  if n[1].len > 1: # toHtml case
    (n[0].strVal, n[1])
  else: # field case
    (n[0].strVal, n[1][0])

#[ this is what fields with default values look like
Call
    Ident "a"
    StmtList
      Asgn
        Ident "string"
        StrLit ""
]#

func getTypeFields*(typeSym: NimNode): seq[NimNode] =
  ## return seq[nnkIdentDefs]
  typeSym.expectKind nnkSym
  # add all own fields
  # look through typeSym.getImpl and look for OfInherit and recurse!
  let typeDef = typeSym.getImpl
  let ofInherit = typeDef[2][0][1]
  if ofInherit.kind == nnkOfInherit:
    let parentTypeSym = ofInherit[0]
    if parentTypeSym.strVal != "RootObj":
      result.add parentTypeSym.getTypeFields
  let recList = typeDef[2][0][2]
  result.add recList.children.toSeq

func removePostfix*(identDef: NimNode): NimNode =
  result = identDef.copyNimTree()
  if result[0].kind == nnkPostfix:
    result[0] = result[0][1]

macro generateBlockInitializer*(typeName: typed): untyped =
  var fieldsList = typeName.getTypeFields().mapIt(it.removePostfix).filterIt(it[0].strVal != "kind")
  for identDef in fieldsList:
    identDef[2] = genAst(fieldType = identDef[1]):
      default(typedesc[fieldType])

  let procParams = @[typeName] & fieldsList
  var objectConstructor = nnkObjConstr.newTree(
    typeName
  )
  objectConstructor.add newColonExpr(ident"kind", typeName.strVal.newLit)
  for identDef in fieldsList:
    let fieldName = identDef[0] 
    objectConstructor.add newColonExpr(fieldName, fieldName)
  let procBody = newStmtList(objectConstructor)
  let procName = postfix(ident("new" & typeName.strVal), "*")
  let initializer = newProc(procName, procParams, procBody)
  return initializer

macro newNbBlock*(typeName: untyped, body: untyped): untyped =
  # typeName is either `ident` or
  # Infix
  #   Ident "of"
  #   Ident "nbImage"
  #   Ident "NbBlock"

  let (typeNameStr, parentType) =
   if typeName.kind == nnkIdent:
     (typeName.strVal, "NbBlock".ident)
   else:
     (typeName[1].strVal, typeName[2])

  let capitalizedTypeName = typeNameStr.capitalizeAscii
  let lowercasedTypeName = typeNameStr.toLower

  # body is:
  # StmtList
  #   Call
  #     Ident "url"
  #     StmtList
  #       Ident "string"
  #   Call
  #     Ident "burl"
  #     StmtList
  #       Asgn
  #         Ident "int"
  #         IntLit 1
  #   Call
  #     Ident "toHtml"
  #     StmtList
  #       DotExpr
  #         Ident "blk"
  #         Ident "url"

  var fields: seq[tuple[fieldName: string, fieldType: NimNode]]
  var toHtmlBody: NimNode
  body.expectKind(nnkStmtList)
  for n in body:
    let (name, body) = n.parseCallStmt()
    if eqIdent(name, "toHtml"):
      toHtmlBody = body
    else:
      fields.add (name, body)

  var fieldsList: seq[NimNode]
  var exportedFieldsList = nnkRecList.newTree()
  for (fName, fType) in fields:
    fieldsList.add newIdentDefs(fName.ident, fType)
    exportedFieldsList.add newIdentDefs(postfix(fName.ident, "*"), fType)

  let typeDefinition = nnkTypeSection.newTree(nnkTypeDef.newTree(
    postfix(capitalizedTypeName.ident, "*"),
    newEmptyNode(), # generic
    nnkRefTy.newTree(
      nnkObjectTy.newTree(
        newEmptyNode(), # pragma
        nnkOfInherit.newTree(
          parentType
        ),
        exportedFieldsList
      )
    )
  ))

  # Next: generate initializer with prefilled kind
  let initializer = genAst(typeName = capitalizedTypeName.ident):
    generateBlockInitializer(typeName)

  # Next: generate nbImageToHtml from toHtmlBody
  let renderProcName = (lowercasedTypeName & "ToHtml").ident
  let renderProc = genAst(name = renderProcName, body = toHtmlBody, blk = ident"blk", nb = ident"nb", typeName=capitalizedTypeName.ident):
    proc name*(blk: NbBlock, nb: Nb): string =
      let blk = typeName(blk)
      body


  # Next: generate these lines:
  # nbToHtml.funcs["NbImage"] = nbImageToHtml
  # addNbBlockToJson(NbImage)
  let hookAssignements = genAst(key = capitalizedTypeName.newLit, f = renderProcName, typeName = capitalizedTypeName.ident):
    nbToHtml.funcs[key] = f
    addNbBlockToJson(typeName)

  result = newStmtList(
    typeDefinition,
    initializer,
    renderProc,
    hookAssignements
  )

macro withNewlines*(body: untyped): string =
  body.expectKind nnkStmtList

  let res = genSym(nskVar, "res")
  var stmts = newStmtList()
  stmts.add newVarStmt(res, "".newLit)

  proc processStmtList(targetStmts: var NimNode, stmtList: NimNode, res: NimNode) =
    for line in stmtList:
      case line.kind
      of nnkForStmt:
        # Rebuild the for loop with a transformed body that appends to res
        var forStmt = line.copy()
        let forBody = forStmt[^1]
        var newBody = newStmtList()
        if forBody.kind == nnkStmtList:
          processStmtList(newBody, forBody, res)
        else:
          processStmtList(newBody, newStmtList(forBody), res)
        forStmt[^1] = newBody
        discard targetStmts.add forStmt
      else:
        # If it's an if-statement without else, add an else returning ""
        if line.kind == nnkIfStmt and line.findChild(it.kind == nnkElse).isNil:
          line.add nnkElse.newTree("".newLit)
        # Append the line value to res, inserting a "\n" separator when needed
        let code = genAst(res=res, line=line):
          block:
            let lineVal = line
            if lineVal.len > 0:
              if res.len > 0 and res[^1] != '\n':
                res &= "\n"
              res &= lineVal
        discard targetStmts.add code

  processStmtList(stmts, body, res)

  stmts.add res
  result = stmts

  


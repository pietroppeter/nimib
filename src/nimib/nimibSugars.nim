import std / [macros, strutils, sequtils, genasts]

proc parseCallStmt(n: NimNode): tuple[lhs: string, rhs: NimNode] =
  n.expectKind nnkCall
  (n[0].strVal, n[1][0])

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

  echo "Body:\n", body.treeRepr

  var fields: seq[tuple[fieldName: string, fieldType: NimNode]]
  var toHtmlBody: NimNode
  body.expectKind(nnkStmtList)
  for n in body:
    let (name, body) = n.parseCallStmt()
    if eqIdent(name, "toHtml"):
      toHtmlBody = body
    else:
      fields.add (name, body)

  var fieldsList = nnkRecList.newTree()
  for (fName, fType) in fields:
    fieldsList.add newIdentDefs(fName.ident, fType)
  let typeDefinition = nnkTypeSection.newTree(nnkTypeDef.newTree(
    postfix(capitalizedTypeName.ident, "*"),
    newEmptyNode(), # generic
    nnkRefTy.newTree(
      nnkObjectTy.newTree(
        newEmptyNode(), # pragma
        nnkOfInherit.newTree(
          parentType
        ),
        fieldsList
      )
    )
  ))

  echo "Type:\n", typeDefinition.repr

  # Next: generate initializer with prefilled kind
  # Be vary of how we write the kind. SHould it be normalized or exactly like the user wrote it?
  # It's more predictable if it is like the user wrote it. But more reasonable to normalize it...

  var procParams = @[capitalizedTypeName.ident] & toSeq(fieldsList.children)
  var objectConstructor = nnkObjConstr.newTree(
    capitalizedTypeName.ident
  )
  objectConstructor.add newColonExpr(ident"kind", capitalizedTypeName.newLit)
  for (fName, _) in fields:
    objectConstructor.add newColonExpr(fName.ident, fName.ident)
  var procBody = newStmtList(objectConstructor)

  var procName = postfix(ident("new" & capitalizedTypeName), "*")
  let initializer = newProc(procName, procParams, procBody)

  echo "init:\n", initializer.repr

  # Next: generate nbImageToHtml from toHtmlBody
  let renderProcName = (lowercasedTypeName & "ToHtml").ident
  let renderProc = genAst(name = renderProcName, body = toHtmlBody, blk = ident"blk", nb = ident"nb", typeName=capitalizedTypeName.ident):
    proc name*(blk: NbBlock, nb: Nb): string =
      let blk = typeName(blk)
      body


  # Next: generate these lines:
  # nbToHtml.funcs["NbImage"] = nbImageToHtml
  # addNbBlockToJson(NbImage)
  # should we make this into a proc instead so it can be used in the non-sugar variant as well?
  let hookAssignements = genAst(key = capitalizedTypeName.newLit, f = renderProcName, typeName = capitalizedTypeName.ident):
    nbToHtml.funcs[key] = f
    addNbBlockToJson(typeName)

  result = newStmtList(
    typeDefinition,
    initializer,
    renderProc,
    hookAssignements
  )

  echo result.repr

  #assert false

macro withNewlines*(body: untyped) : string =
  body.expectKind nnkStmtList
  result = infix(body[0], "&", "\n".newLit)
  if body.len > 1:
    for line in body[1..^1]:
      # TODO: handle for loops
      # if it's an if-statement, check if it has an else-clause. Otherwise add one which returns ""
      if line.kind == nnkIfStmt and line.findChild(it.kind == nnkElse).isNil:
        line.add nnkElse.newTree("".newLit)
      result = infix(result, "&", line)
      result = infix(result, "&", "\n".newLit)
  #echo result.treerepr
  #echo result.repr

  


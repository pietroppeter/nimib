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
  #debugecho "typeDef of ", typeSym.repr, ":", typedef.repr
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

#[ var procParams = @[capitalizedTypeName.ident] & fieldsList
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
]#
macro generateBlockInitializer*(typeName: typed): untyped =
  var fieldsList = typeName.getTypeFields().mapIt(it.removePostfix).filterIt(it[0].strVal != "kind")
  for identDef in fieldsList:
    identDef[2] = genAst(fieldType = identDef[1]):
      default(typedesc[fieldType])
  #echo fieldsList.mapIt(it.repr)

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
  #echo "init:\n", initializer.repr
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

  #echo "Body:\n", body.treeRepr

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

  # TODO: add parent list of fields to fieldsList as well!
  # This probaly has to be done in a typed macro?
  # In that case, let the typed macro construct the initializer!

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

  #echo "Type:\n", typeDefinition.repr

  # Next: generate initializer with prefilled kind
  # Be vary of how we write the kind. SHould it be normalized or exactly like the user wrote it?
  # It's more predictable if it is like the user wrote it. But more reasonable to normalize it...

  let initializer = genAst(typeName = capitalizedTypeName.ident):
    generateBlockInitializer(typeName)

  #[ var procParams = @[capitalizedTypeName.ident] & fieldsList
  var objectConstructor = nnkObjConstr.newTree(
    capitalizedTypeName.ident
  )
  objectConstructor.add newColonExpr(ident"kind", capitalizedTypeName.newLit)
  for (fName, _) in fields:
    objectConstructor.add newColonExpr(fName.ident, fName.ident)
  var procBody = newStmtList(objectConstructor)

  var procName = postfix(ident("new" & capitalizedTypeName), "*")
  let initializer = newProc(procName, procParams, procBody)

  echo "init:\n", initializer.repr ]#

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

  #echo result.repr

  #assert false

macro withNewlines*(body: untyped) : string =
  body.expectKind nnkStmtList
  result = "".newLit
  if body.len > 0:
    for i, line in body:
      # TODO: handle for loops
      # if it's an if-statement, check if it has an else-clause. Otherwise add one which returns ""
      if line.kind == nnkIfStmt and line.findChild(it.kind == nnkElse).isNil:
        line.add nnkElse.newTree("".newLit)
      
      # Only add a newline if the line contains anything and isn't the last line
      # Also if it already ends with a newline we don't have to add one
      result = genAst(result=result, line=line, isLast=newLit(i==body.len-1)):
        let lineVal = line
        if not isLast and lineVal.len > 0 and lineVal[^1] != '\n':
          result & lineVal & "\n"
        else:
          result & lineVal


  


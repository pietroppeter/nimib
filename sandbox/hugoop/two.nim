import jsony, tables

type
  Nimib = ref object of RootObj
    a, b, c: int
    typename: string
  NimibChild = ref object of Nimib
    d, e: float

method dump(n: Nimib): string =
  n[].toJson()

method dump(n: NimibChild): string =
  n[].toJson()

proc dumpHook*(s: var string, v: Nimib) =
  s.add v.dump()

let n1: Nimib = Nimib(a: 1, b: 2, c: 3, typename: "Nimib")
let n2: Nimib = NimibChild(a: 100, d: 3.14, e: 4.56, typename: "NimibChild")

echo n1.toJson()
echo n2.toJson()

proc parseNimib(s: string, i: var int): Nimib =
  var v = Nimib()
  parseHook(s, i, v[])
  result = v

proc parseNimibChild(s: string, i: var int): Nimib =
  var v = NimibChild()
  parseHook(s, i, v[])
  result = v

let parseDefs = {
  "Nimib": parseNimib,
  "NimibChild": parseNimibChild
}.toTable()

proc parseHook*(s: string, i: var int, v: var Nimib) =
  var n: Nimib = Nimib()
  let current_i = i
  parseHook(s, i, n[])
  i = current_i
  let typename = n.typename
  v = parseDefs[typename](s, i)

let s1 = n1.toJson().fromJson(Nimib)
echo s1.toJson()
let s2 = n2.toJson().fromJson(Nimib)
echo s2.toJson()
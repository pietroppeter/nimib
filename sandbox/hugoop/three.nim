import jsony, tables

type
  Nimib = ref object of RootObj
    a, b, c: int
    typename: string
  NimibChild = ref object of Nimib
    d, e: float

var parseDefs: Table[string, proc (s: string, i: var int): Nimib]

template registerBlock(typename: untyped) =
  parseDefs[$typename] =
    proc (s: string, i: var int): Nimib =
      var v: typename
      new v
      parseHook(s, i, v[])
      result = v

  method dump(n: typename): string =
    n[].toJson()

proc parseHook*(s: string, i: var int, v: var Nimib) =
  # First parse the typename
  var n: Nimib = Nimib()
  let current_i = i
  parseHook(s, i, n[])
  # Reset i
  i = current_i
  # Parse the correct type
  let typename = n.typename
  v = parseDefs[typename](s, i)

registerBlock(Nimib)
registerBlock(NimibChild)

# moved this here, I do not need to add dummy dumphook
proc dumpHook*(s: var string, v: Nimib) =
  s.add v.dump()


let n1: Nimib = Nimib(a: 1, b: 2, c: 3, typename: "Nimib")
let n2: Nimib = NimibChild(a: 100, d: 3.14, e: 4.56, typename: "NimibChild")

echo n1.toJson()
echo n2.toJson()

let s1 = n1.toJson().fromJson(Nimib)
echo s1.toJson()
let s2 = n2.toJson().fromJson(Nimib)
echo s2.toJson()
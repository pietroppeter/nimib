import jsony

type
  Nimib = ref object of RootObj
    a, b, c: int
  NimibChild = ref object of Nimib
    d, e: float


method dump(n: Nimib): string =
  n[].toJson()

when not defined(noNimibChild): # essential, see below
  method dump(n: NimibChild): string =
    n[].toJson()

proc dumpHook*(s: var string, v: Nimib) =
  s.add v.dump()

let n1: Nimib = Nimib(a: 1, b: 2, c: 3)
let n2: Nimib = NimibChild(d: 3.14, e: 4.56)

echo n1.toJson()
echo n2.toJson()
#[ nim r one
{"a":1,"b":2,"c":3}
{"d":3.14,"e":4.56,"a":0,"b":0,"c":0}
]#
#[ nim -d:noNimibChild r one
{"a":1,"b":2,"c":3}
{"a":0,"b":0,"c":0}
]#
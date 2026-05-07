import jsony
import ./types, ./globals
export jsony

template addNbBlockToJson*(kind: untyped) =
  nbToJson[$kind] =
    proc (s: string, i: var int): NbBlock =
      var v: kind
      new v
      parseHook(s, i, v[])
      result = v

  method dump*(n: kind): string =
    jsony.toJson(n[])

proc parseHook*(s: string, i: var int, v: var NbBlock) =
  # First parse the typename
  var n: NbBlock = NbBlock()
  let current_i = i
  parseHook(s, i, n[])
  # Reset i
  i = current_i
  # Parse the correct type
  let kind = n.kind
  if kind notIn nbToJson:
    raise ValueError.newException "cannot find kind in nbToJson: \"" & kind & '"' 
  v = nbToJson[kind](s, i)

method dump*(n: NbBlock): string {.base.} =
    jsony.toJson(n[])

proc dumpHook*(s: var string, v: NbBlock) =
  s.add v.dump()

template dumpKey*(s: var string, v: string) =
  const v2 = jsony.toJson(v) & ":"
  s.add v2

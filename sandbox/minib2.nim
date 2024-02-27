import json

type
  NbBlock* = ref object
    command*: string
    blocks*: seq[NbBlock]
    data*: JsonNode
  NbCode* = distinct NbBlock

func code(b: NbCode): string =
  assert "code" in b.NbBlock.data
  assert b.NbBlock.data["code"].kind == JString

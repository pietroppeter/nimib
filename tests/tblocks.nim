import nimib
import std / [unittest, strutils]

newNbBlock(ReadCodeBlock):
  code: string
  toHtml:
    blk.code

suite "newNbBlock":
  nbInit
  test "readCode":
    template readCodeBlock(body: untyped) =
      let blk = newReadCodeBlock()
      blk.code = getCode(body)
      nb.add blk

    readCodeBlock:
      let a = 1.23

    check nb.blk.ReadCodeBlock.code == "let a = 1.23"



import nimib
import std / [unittest, strutils]

suite "newNbBlock":
  nbInit
  var blk: NbBlock
  test "readCode":
    template readCodeBlock(body: untyped) =
      newNbBlock("readCodeBlock", true, nb, blk):
        body
      do:
        discard

    template dontReadCodeBlock(body: untyped) =
      newNbBlock("dontReadCodeBlock", false, nb, blk):
        body
      do:
        discard
    
    readCodeBlock:
      let a = 1.23
    check blk.code == "let a = 1.23"

    dontReadCodeBlock:
      let b = 3.21
    check blk.code == ""

    fail()



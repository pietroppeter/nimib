import nimib
import std / [unittest, strutils, strformat]

newNbBlock(ReadCodeBlock):
  code: string
  toHtml:
    blk.code

template iCreateGensyms() =
  newNbBlock(NotGensymed):
    foo: int
    toHtml:
      let x = blk.foo
      &"x: {x}"

iCreateGensyms()
  

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



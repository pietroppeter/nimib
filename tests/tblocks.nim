import nimib
import std / [unittest, strutils]

suite "new block":
  nbInit
  var blk: NbBlock
  blk = newBlock("nbText"): "content"
  check blk.command == "nbText"
  check blk.code.strip == "\"content\"" # need strip since I am going to find new lines
  blk = newBlock("nbCode"): echo "hello"
  check blk.command == "nbCode"
  check blk.code.strip == "echo \"hello\"" # need strip since I am going to find new lines

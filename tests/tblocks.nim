import nimib
import std / [unittest, strutils]

suite "new block":
  nbInit
  var blk: NbBlock
  when not defined(nimibPreviewCodeAsInSource):
    # newBlock should be always called inside a template as below or it breaks with CodeAsInSource
    test "nbText":
      blk = newBlock("nbText"): "content"
      check blk.command == "nbText"
      check blk.code == "\"content\"" # need strip since I am going to find new lines
    test "nbCode":
      blk = newBlock("nbCode"): echo "hello"
      check blk.command == "nbCode"
      check blk.code == "echo \"hello\""
  # the following is how newBlock should be called (to have it work with codeAsinSource)
  test "nbMyBlock":
    template nbMyBlock(body: untyped) =
      blk = newBlock("nbMyBlock"): body
    nbMyBlock: "content"
    check blk.command == "nbMyBlock"
    check blk.code == "\"content\""
    nbMyBlock: echo "hello"
    check blk.command == "nbMyBlock"
    check blk.code == "echo \"hello\""

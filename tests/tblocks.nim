import nimib
import std / [unittest, strutils]

suite "newNbBlock":
  nbInit
  var blk: NbBlock
  when not defined(nimibPreviewCodeAsInSource):
    # newBlock should be always called inside a template as below or it breaks with CodeAsInSource
    test "nbTextLikeExample":
      newNbBlock("nbText", nb, blk):
        "content"
      do:
        discard
      check blk.command == "nbText"
      check blk.code == "\"content\"" # need strip since I am going to find new lines
    test "nbCodeLikeExample":
      newNbBlock("nbCode", nb, blk):
        echo "hello"
      do:
        discard
      check blk.command == "nbCode"
      check blk.code == "echo \"hello\""
  # the following is how newBlock should be called (to have it work with codeAsinSource)
  test "nbMyBlock":
    template nbMyBlock(body: untyped) =
      newNbBlock("nbMyBlock", nb, blk):
        body
      do:
        discard
    nbMyBlock: "content"
    check blk.command == "nbMyBlock"
    check blk.code == "\"content\""
    nbMyBlock: echo "hello"
    check blk.command == "nbMyBlock"
    check blk.code == "echo \"hello\""

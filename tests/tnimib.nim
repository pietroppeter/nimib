import nimib, strformat
import unittest

nbInit # todo: add a test suite for nbInit

suite "nbText":
  test "single line text string":
    nbText: "hi"
    doAssert nb.blk.code == "\"hi\""
    doAssert nb.blk.output == "hi"

  when not defined(nimibPreviewCodeAsInSource):
    test "single line text string with strformat":
      let name = "you"
      nbText: fmt"hi {name}"
      doAssert nb.blk.code == "fmt\"hi {name}\""
      doAssert nb.blk.output == "hi you"

    test "multi line text string":
      nbText: """hi
how are you?
"""
      doAssert nb.blk.code == "\"\"\"hi\nhow are you?\n\"\"\""
      doAssert nb.blk.output == """hi
how are you?
"""

    test "multi line text string with strformat":
      let
        name = "you"
        answer = "fine"
      nbText: &"""hi {name}
how are you? {answer}
"""
      doAssert nb.blk.code == "&\"\"\"hi {name}\nhow are you? {answer}\n\"\"\""
      doAssert nb.blk.output == """hi you
how are you? fine
"""

suite "nbCode":
  test "single line of code, no output":
    nbCode: discard
    doAssert nb.blk.code == "discard"
    doAssert nb.blk.output == ""

  test "single line of code, with output":
    nbCode: echo "hi"
    check nb.blk.code == "echo \"hi\""
    check nb.blk.output == "hi\n"

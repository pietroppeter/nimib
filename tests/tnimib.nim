import nimib, strformat
import unittest

nbInit # todo: add a test suite for nbInit

suite "nbText":
  test "single line text string":
    nbText: "hi"
    check nb.blk.code == "\"hi\""
    check nb.blk.output == "hi"

  when not defined(nimibPreviewCodeAsInSource):
    test "single line text string with strformat":
      let name = "you"
      nbText: fmt"hi {name}"
      check nb.blk.code == "fmt\"hi {name}\""
      check nb.blk.output == "hi you"

    test "multi line text string":
      nbText: """hi
how are you?
"""
      check nb.blk.code == "\"\"\"hi\nhow are you?\n\"\"\""
      check nb.blk.output == """hi
how are you?
"""

    test "multi line text string with strformat":
      let
        name = "you"
        answer = "fine"
      nbText: &"""hi {name}
how are you? {answer}
"""
      check nb.blk.code == "&\"\"\"hi {name}\nhow are you? {answer}\n\"\"\""
      check nb.blk.output == """hi you
how are you? fine
"""

suite "nbCode":
  test "single line of code, no output":
    nbCode: discard
    check nb.blk.code == "discard"
    check nb.blk.output == ""

  test "single line of code, with output":
    nbCode: echo "hi"
    check nb.blk.code == "echo \"hi\""
    check nb.blk.output == "hi\n"

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

suite "nbRawOutput":
  test "pure text":
    nbRawOutput: "Hello world!"
    check nb.blk.code == ""
    check nb.blk.output == "Hello world!"
  
  test "html tags":
    nbRawOutput: "<div> <span> div-span </span> </div>"
    check nb.blk.code == ""
    check nb.blk.output == "<div> <span> div-span </span> </div>"

  test "Use inside template":
    # codeAsInSource can't read the correct line if block is used inside a template
    # check that readCode is having effect and preventing the reading of code.
    template slide(body: untyped) =
      nbRawOutput: "<slide>"
      body
      nbRawOutput: "</slide>"
    
    slide:
      check nb.blk.code == ""
      check nb.blk.output == "<slide>"
    
    check nb.blk.code == ""
    check nb.blk.output == "</slide>"

suite "nbClearOutput":
  test "nbCode":
    nbCode:
      echo "Hello world!!!"
    check nb.blk.output == "Hello world!!!\n"
    check nb.blk.context["output"].vString == "Hello world!!!"
    nbClearOutput()
    check nb.blk.output == ""
    check nb.blk.context["output"].vString == ""

when moduleAvailable(nimpy):
  nbInitPython()
  suite "nbPython":
    test "nbPython string":
      let pyString = hlPy"""
s = [2*i for i in range(3)]
a = 3.14
print(s)
print(a)
"""
      nbPython: pyString
      check nb.blk.code == pyString
      check nb.blk.output == "[0, 2, 4]\n3.14\n"


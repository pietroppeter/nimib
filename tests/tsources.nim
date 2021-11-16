import nimib, strutils, strformat
import unittest

suite "test sources":
  template check =
    #echo &"---\n{nbBlock.code}\n"
    # the replace stuff needed on windows where the lines read from file will have windows native new lines
    test $currentTest:
      check nbBlock.code.replace("\c\l", "\n").replace("\c", "\n") == expected
    currentTest += 1

  var currentTest: int
  var expected, actual: string
  nbInit
  nbCode:
    # a comment
    let
      x = 1
  # a comment here means that on windows line 12 will read with a single \c instead of \c\l (if blank space here I will have \c\l)
  expected = """
# a comment
let
  x = 1
"""
  check

  nbCode:
    # a comment
    let  # and a comment with nbCode
      y = 1
  expected = """
# a comment
let  # and a comment with nbCode
  y = 1
"""
  check

  nbCode echo y
  expected = "echo y"
  check
  nbCode: echo y
  expected = "echo y"
  check
  nbCode(echo y)
  expected = "echo y"
  check
  nbCode ((echo ("( This is ( weird string)")))
  expected = "echo (\"( This is ( weird string)\")"
  check
import nimib, strformat, json
import unittest

suite "test sources":
  template checkCode(t: typedesc = NbCode) =
    #echo &"---\n{nbBlock.code}\n"
    # the replace stuff needed on windows where the lines read from file will have windows native new lines
    test $currentTest:
      actual = nb.blk.t.code
      check actual.nbNormalize == expected.nbNormalize
      if actual.nbNormalize != expected.nbNormalize:
        echo &"===\n---actual:\n{actual.repr}\n---expected\n{expected.repr}\n---\n==="
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
  checkCode()

  nbCode:
    # a comment
    let  # and a comment with nbCode
      y = 1
  expected = """
# a comment
let  # and a comment with nbCode
  y = 1
"""
  checkCode()

  nbCode echo y
  expected = "echo y"
  checkCode()
  nbCode: echo y
  expected = "echo y"
  checkCode()
  nbCode(echo y)
  expected = "echo y"
  checkCode()
  nbCode ((echo ("( This is ( weird string)")))
  expected = "echo (\"( This is ( weird string)\")"
  checkCode()

  nbTextWithCode: """problem
solution"""
  expected = "\"\"\"problem\nsolution\"\"\""
  checkCode(NbTextWithCode)

  template discardBlock(body: untyped) = discard

  nbCode: discardBlock:
    echo y
  
  expected = """
discardBlock:
  echo y
"""
  checkCode()

  nbCode:
    let garbage = 1
    let bigString = """start
  middle
end"""
  expected = "let garbage = 1\nlet bigString = \"\"\"start\n  middle\nend\"\"\""
  checkCode()

  nbCode:
    block:
      echo y
  expected = "block:\n  echo y"
  checkCode()

  when not defined(nimibCodeFromAst):
    nbCode:
      echo y
      # This should be included!
    expected = "echo y\n# This should be included!"
    checkCode()

    nbCode:
      echo y

      # Include this as well!
    expected = "echo y\n\n# Include this as well!"
    checkCode()

    nbCode:
      echo y
    # Don't include this!
    expected = "echo y"
    checkCode()

    nbCode:

      echo y
    # The newline at the beginning of the block!
    expected = "echo y"
    checkCode()

    nbCode:
      block:
        let
          b = 1

    expected = "block:\n  let\n    b = 1"
    checkCode()

    template notNbCode(body: untyped) =
      nbCode:
        body

    notNbCode:
      echo y

    expected = "echo y"
    checkCode()

    template `&`(a,b: int) = discard

    nbCode:
      1 &
        2

    expected = "1 &\n  2"
    checkCode()

    nbCode:
      nb.doc.context["no_source"] = %true

    expected = "nb.doc.context[\"no_source\"] = %true"
    checkCode()

    nbCode: discard
    expected = "discard"
    checkCode()

    nbCode:
      for n in 0 .. 1:
        discard
    expected = "for n in 0 .. 1:\n  discard"
    checkCode()

    template nbCodeInTemplate =
      nbCode:
        nb.doc.context["nbText"] = %["mdOutputToHtml"]

    nbCodeInTemplate()
    expected = """nb.doc.context["nbText"] = %["mdOutputToHtml"]"""
    checkCode()

    nbCode:
      type A = object
    expected = "type A = object"
    checkCode()
  
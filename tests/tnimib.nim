import std / [unittest, strformat, strutils]
import nimib

nbInit # todo: add a test suite for nbInit

suite "nbText":
  test "single line text string":
    nbText: "hi"
    check nb.blk.output == "hi"

  test "single line text string with strformat":
    let name = "you"
    nbText: fmt"hi {name}"
    check nb.blk.output == "hi you"

  test "multi line text string":
    nbText: """hi
how are you?
"""
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
    check nb.blk.output == """hi you
how are you? fine
"""

suite "nbTextWithCode":
  test "single line text string":
    nbTextWithCode: "hi"
    check nb.blk.code == "\"hi\""
    check nb.blk.output == "hi"

  test "single line text string with strformat":
      let name = "you"
      nbTextWithCode: fmt"hi {name}"
      check nb.blk.code == "fmt\"hi {name}\""
      check nb.blk.output == "hi you"

  test "multi line text string - variant 1":
    nbTextWithCode:
      """hi
how are you?
"""
    check nb.blk.code == "\"\"\"hi\nhow are you?\n\"\"\""
    check nb.blk.output == """hi
how are you?
"""


  test "multi line text string - variant 2":
    nbTextWithCode: """
hi
how are you?
"""
    when defined(nimibCodeFromAst):
      check nb.blk.code == "\"\"\"hi\nhow are you?\n\"\"\""
    else:
      check nb.blk.code == "\"\"\"\nhi\nhow are you?\n\"\"\""
    check nb.blk.output == """hi
how are you?
"""

  test "multi line text string - variant 3":
    nbTextWithCode: """hi
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
    nbTextWithCode: &"""hi {name}
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

suite "nbRawHtml":
  test "pure text":
    nbRawHtml: "Hello world!"
    check nb.blk.code == ""
    check nb.blk.output == "Hello world!"
  
  test "html tags":
    nbRawHtml: "<div> <span> div-span </span> </div>"
    check nb.blk.code == ""
    check nb.blk.output == "<div> <span> div-span </span> </div>"

  test "Use inside template":
    # codeAsInSource can't read the correct line if block is used inside a template
    # check that readCode is having effect and preventing the reading of code.
    template slide(body: untyped) =
      nbRawHtml: "<slide>"
      body
      nbRawHtml: "</slide>"
    
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

suite "nbCodeSkip":
  test "single line of code with output":
    nbCodeSkip:
      echo "random output..."

    check nb.blk.output == ""
    check nb.blk.code == "echo \"random output...\""

  test "destructive code":
    # Make sure the code is NOT executed

    nbCodeSkip:
      fail()
    
    check nb.blk.output == ""
    check nb.blk.code == "fail()"

suite "nbCapture":
  test "single line of code, with output":
    nbCapture:
      echo "captured output"

    check nb.blk.output == "captured output\n"

  test "single line of code, without output":
    nbCapture:
      discard

    check nb.blk.output == ""

when moduleAvailable(nimpy) and false:
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

when moduleAvailable(karax/kbase):
  suite "nbJs":
    test "nbJsFromString":
      nbJsFromString: hlNim"""
  let a = 1
  echo a
  """
      check nb.blk.code == """
  let a = 1
  echo a
  """
      check nb.blk.context["transformedCode"].vString.len > 0

    test "nbJsFromCode":
      nbJsFromCode:
        let a = 1
        echo a
      check nb.blk.context["transformedCode"].vString.len > 0
      check "a = 1" in nb.blk.context["transformedCode"].vString
      check "block:" notin nb.blk.context["transformedCode"].vString

    test "nbJsFromCode, capture variable":
      let a = 1
      nbJsFromCode(a):
        echo a
      check nb.blk.context["transformedCode"].vString.len > 0
      check "a = parseJson" in nb.blk.context["transformedCode"].vString

    test "nbJsFromCodeGlobal":
      nbJsFromCodeGlobal:
        import std / dom
        var x = 1
      check nb.blk.context["transformedCode"].vString.len > 0
      check "x = 1" in nb.blk.context["transformedCode"].vString
      check "block:" notin nb.blk.context["transformedCode"].vString

    test "nbJsFromCodeInBlock":
      nbJsFromCodeInBlock:
        let x = 3.14
        echo x
      check nb.blk.context["transformedCode"].vString.len > 0
      check "x = 3.14" in nb.blk.context["transformedCode"].vString
      check "block:" in nb.blk.context["transformedCode"].vString

    test "nbJsFromCodeOwnFile + exportc":
      nbJsFromCodeOwnFile:
        proc setup() {.exportc.} =
          echo 1
      check "setup()" in nb.blk.context["transformedCode"].vString

    test "nbKaraxCode":
      let x = 3.14
      nbKaraxCode(x):
        var message = "Pi is roughly " & $x
        karaxHtml:
          p:
            text message
      check nb.blk.code.len > 0
      check nb.blk.context["transformedCode"].vString.len > 0

    test "nbCodeDisplay":
      nbCodeDisplay(nbJsFromCode):
        import p5
        echo "hi p5"
        draw:
          ellipse(mouseX, mouseY, 20)
      check nb.blocks[^1].command == "nbCode"
      check nb.blocks[^2].command == "nbJsFromCode"
      check nb.blocks[^2].context["transformedCode"].vString.len > 0
      check "ellipse(mouseX, mouseY, 20)" in nb.blocks[^2].context["transformedCode"].vString
      when defined(nimibCodeFromAst):
        check nb.blocks[^1].code.startsWith("import\n  p5")
      else:
        check nb.blocks[^1].code.startsWith("import p5")
      check nb.blocks[^1].output == ""

    test "nbCodeAnd":
      nbCodeAnd(nbJsFromCode):
        let you = "me"
        echo "hi ", you
      check nb.blocks[^2].command == "nbCode"
      check nb.blocks[^1].command == "nbJsFromCode"
      check nb.blocks[^1].context["transformedCode"].vString.len > 0
      check "you = \"me\"" in nb.blocks[^1].context["transformedCode"].vString
      check nb.blocks[^2].code.startsWith("let you =")
      check nb.blocks[^2].output == "hi me\n"

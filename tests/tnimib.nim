import std / [unittest, strformat, strutils]
import nimib/config
import nimib

nbInit # todo: add a test suite for nbInit

suite "nbText":
  test "single line text string":
    nbText: "hi"
    check nb.blk.NbText.text == "hi"

  test "single line text string with strformat":
    let name = "you"
    nbText: fmt"hi {name}"
    check nb.blk.NbText.text == "hi you"

  test "multi line text string":
    nbText: """hi
how are you?
"""
    check nb.blk.NbText.text == """hi
how are you?
"""

  test "multi line text string with strformat":
    let
      name = "you"
      answer = "fine"
    nbText: &"""hi {name}
how are you? {answer}
"""
    check nb.blk.NbText.text == """hi you
how are you? fine
"""

suite "nbTextWithCode":
  test "single line text string":
    nbTextWithCode: "hi"
    check nb.blk.NbTextWithCode.code == "\"hi\""
    check nb.blk.NbTextWithCode.text == "hi"

  test "single line text string with strformat":
      let name = "you"
      nbTextWithCode: fmt"hi {name}"
      check nb.blk.NbTextWithCode.code == "fmt\"hi {name}\""
      check nb.blk.NbTextWithCode.text == "hi you"

  test "multi line text string - variant 1":
    nbTextWithCode:
      """hi
how are you?
"""
    check nb.blk.NbTextWithCode.code == "\"\"\"hi\nhow are you?\n\"\"\""
    check nb.blk.NbTextWithCode.text == """hi
how are you?
"""


  test "multi line text string - variant 2":
    nbTextWithCode: """
hi
how are you?
"""
    when defined(nimibCodeFromAst):
      check nb.blk.NbTextWithCode.code == "\"\"\"\nhi\nhow are you?\n\"\"\""
    else:
      check nb.blk.NbTextWithCode.code == "\"\"\"\nhi\nhow are you?\n\"\"\""
    check nb.blk.NbTextWithCode.text == """hi
how are you?
"""

  test "multi line text string - variant 3":
    nbTextWithCode: """hi
how are you?
"""
    check nb.blk.NbTextWithCode.code == "\"\"\"hi\nhow are you?\n\"\"\""
    check nb.blk.NbTextWithCode.text == """hi
how are you?
"""

  test "multi line text string with strformat":
    let
      name = "you"
      answer = "fine"
    nbTextWithCode: &"""hi {name}
how are you? {answer}
"""
    check nb.blk.NbTextWithCode.code == "&\"\"\"hi {name}\nhow are you? {answer}\n\"\"\""
    check nb.blk.NbTextWithCode.text == """hi you
how are you? fine
"""

suite "nbCode":
  test "single line of code, no output":
    nbCode: discard
    check nb.blk.NbCode.code == "discard"
    check nb.blk.NbCode.output == ""

  test "single line of code, with output":
    nbCode: echo "hi"
    check nb.blk.NbCode.code == "echo \"hi\""
    check nb.blk.NbCode.output == "hi\n"

suite "nbRawHtml":
  test "pure text":
    nbRawHtml: "Hello world!"
    check nb.blk.NbRawHtml.html == "Hello world!"
  
  test "html tags":
    nbRawHtml: "<div> <span> div-span </span> </div>"
    check nb.blk.NbRawHtml.html == "<div> <span> div-span </span> </div>"

  test "Use inside template":
    # codeAsInSource can't read the correct line if block is used inside a template
    # check that readCode is having effect and preventing the reading of code.
    template slide(body: untyped) =
      nbRawHtml: "<slide>"
      body
      nbRawHtml: "</slide>"
    
    slide:
      check nb.blk.NbRawHtml.html == "<slide>"
    
    check nb.blk.NbRawHtml.html == "</slide>"

suite "nbClearOutput":
  test "nbCode":
    nbCode:
      echo "Hello world!!!"
    check nb.blk.NbCode.output == "Hello world!!!\n"
    nbClearOutput()
    check nb.blk.NbCode.output == ""

suite "nbCodeSkip":
  test "single line of code with output":
    nbCodeSkip:
      echo "random output..."

    check nb.blk.NbCode.output == ""
    check nb.blk.NbCode.code == "echo \"random output...\"\n"

  test "destructive code":
    # Make sure the code is NOT executed

    nbCodeSkip:
      fail()
    
    check nb.blk.NbCode.output == ""
    check nb.blk.NbCode.code == "fail()\n"

suite "nbCapture":
  test "single line of code, with output":
    nbCapture:
      echo "captured output"

    check nb.blk.NbCode.output == "captured output\n"

  test "single line of code, without output":
    nbCapture:
      discard

    check nb.blk.NbCode.output == ""


suite "nbJs":
  test "nbJsFromString":
    nbJsFromString: hlNim"""
let a = 1
echo a
"""
    check nb.blk.NbJsFromCode.code == """
let a = 1
echo a
"""
    check nb.blk.NbJsFromCode.transformedCode.len > 0

  test "nbJsFromCode":
    nbJsFromCode:
      let a = 1
      echo a
    check nb.blk.NbJsFromCode.transformedCode.len > 0
    check "a = 1" in nb.blk.NbJsFromCode.transformedCode
    check "block:" notin nb.blk.NbJsFromCode.transformedCode

  test "nbJsFromCode, capture variable":
    let a = 1
    nbJsFromCode(a):
      echo a
    check nb.blk.NbJsFromCode.transformedCode.len > 0
    check "a = parseJson" in nb.blk.NbJsFromCode.transformedCode

  test "nbJsFromCodeGlobal":
    nbJsFromCodeGlobal:
      import std / dom
      var x = 1
    check nb.blk.NbJsFromCode.transformedCode.len > 0
    check "x = 1" in nb.blk.NbJsFromCode.transformedCode
    check "block:" notin nb.blk.NbJsFromCode.transformedCode

  test "nbJsFromCodeInBlock":
    nbJsFromCodeInBlock:
      let x = 3.14
      echo x
    check nb.blk.NbJsFromCode.transformedCode.len > 0
    check "x = 3.14" in nb.blk.NbJsFromCode.transformedCode
    check "block:" in nb.blk.NbJsFromCode.transformedCode

  test "nbJsFromCodeOwnFile + exportc":
    nbJsFromCodeOwnFile:
      proc setup() {.exportc.} =
        echo 1
    check "setup()" in nb.blk.NbJsFromCodeOwnFile.transformedCode

  test "nbCodeDisplay":
    nbCodeDisplay(nbJsFromCode):
      import p5
      echo "hi p5"
      draw:
        ellipse(mouseX, mouseY, 20)
    check nb.blocks[^1].kind == "NbCode"
    check nb.blocks[^2].kind == "NbJsFromCode"
    check nb.blocks[^2].NbJsFromCode.transformedCode.len > 0
    check "ellipse(mouseX, mouseY, 20)" in nb.blocks[^2].NbJsFromCode.transformedCode
    when defined(nimibCodeFromAst):
      check nb.blocks[^1].NbCode.code.startsWith("import p5")
    else:
      check nb.blocks[^1].NbCode.code.startsWith("import p5")
    check nb.blocks[^1].NbCode.output == ""

  test "nbCodeAnd":
    nbCodeAnd(nbJsFromCode):
      let you = "me"
      echo "hi ", you
    check nb.blocks[^2].kind == "NbCode"
    check nb.blocks[^1].kind == "NbJsFromCode"
    check nb.blocks[^1].NbJsFromCode.transformedCode.len > 0
    check "you = \"me\"" in nb.blocks[^1].NbJsFromCode.transformedCode
    check nb.blocks[^2].NbCode.code.startsWith("let you =")
    check nb.blocks[^2].NbCode.output == "hi me\n"

test "getNimibVersion()":
  let version = getNimibVersion()

  check version.count('.') == 2

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
      check nb.blk.NbPython.code == pyString
      check nb.blk.NbPython.output == "[0, 2, 4]\n3.14\n"

when moduleAvailable(karax/kbase):
  suite "nbKarax":
    test "nbKaraxCode":
      let x = 3.14
      nbKaraxCode(x):
        var message = "Pi is roughly " & $x
        karaxHtml:
          p:
            text message
      check nb.blk.NbJsFromCodeOwnFile.code.len > 0
      check nb.blk.NbJsFromCodeOwnFile.transformedCode.len > 0
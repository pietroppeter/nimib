import nimoji
import nimib
import std/[strutils, strformat]

nbInit

var nbToc: NbBlock

template addToc =
  newNbBlock("nbText", false, nb, nbToc, ""):
    nbToc.output = "## Table of Contents:\n\n"

template nbCodeBlock(name:string) =
  let anchorName = name.toLower.replace(" ", "-")
  nbText "<a name = \"" & anchorName & "\"></a>\n### " & name & "\n\n---"
  # see below, but any number works for a numbered list
  nbToc.output.add "1. <a href=\"#" & anchorName & "\">" & name & "</a>\n"

nbText: """
> This nimib document provides a brief description and example for 
> all blocks in nimib.
""".emojize

addToc()

nbCodeBlock: "nbText"
nbText: """
`nbText` is a block that displays text. It is the one you will use the most.
You can use markdown syntax to format your text.
The markdown syntax is explained in the [Markdown Cheatsheet](./cheatsheet.html).
"""
nimibCode:
  nbText: """
  #### Markdown Example
  My **text** is *formatted* with the 
  [Markdown](./cheatsheet.html) syntax.
  """

nbCodeBlock: "nbCode"
nbText: """
You can insert your Nim code in your text using the `nbCode` block.
It displays your code with highlighting, compiles it, runs it and captures any output that is `echo`ed.
"""

nimibCode:
  nbCode:
    echo "Hello World!"

nbCodeBlock: "nbCodeSkip"
nbText: """
Similar to `nbCode`, `nbCodeSkip` is a block that displays
highlighted code but does not run it.
It is useful to show erroneous code or code that takes too long to run.
> :warning: `nbCodeSkip` does not guarantee that the code you show will compile nor run.

Examples:
""".emojize

nimibCode:
  nbCodeSkip:
    while true:
      echo "Notice how there is no output?"
      echo "The code is not compiled or executed so no output is generated!"

  nbCodeSkip:
    exit() # even this won't execute!

nbCodeBlock: "nbCodeInBlock"
nbText: """
Sometimes, you want to show similar code snippets with the same variable names and you need to declare twice the same variables.
You can do so with `nbCodeInBlock` which nests your snippet inside a block.
"""

nimibCode:
  nbCode:
    var x = true # x is shared between all code blocks
  nbCodeInBlock:
    var y = 2 # y is local to this block
    echo x, ' ', y # The x variable comes from above
  nbCodeInBlock:
    var y = 3 # We have to redefine the variable y in this new CodeInBlock
    echo y
  when false:
    echo y # This would fail as defined in another scope
    var x = true # This would fail in nbCode, since it is a redefinition

nbCodeBlock: "nbCapture"
nbText: """

`nbCapture` is a block that only shows the captured output of a code block.
"""
nimibCode:
  nbCapture:
    echo "Captured!"

nbCodeBlock: "nbTextWithCode"
nbText: """
`nbText` only stores the string it is given, but it doesn't store the code passed to `nbText`. For example, `nbText: fmt"{1+1}"` only stores the string `"2"` but not the code `fmt"{1+1}"` that produced that string. `nbTextWithCode` works like `nbText` but it also stores the code in the created block. It can be accessed with `nb.blk.code` right after the `nbTextWithCode` call. See the end of 
[numerical](./numerical.html) for an example.
"""

nbCodeBlock: "nbImage"
nbText: """
`nbImage` enables to display your favorite pictures.

Most formats (.jpg, .png) are accepted. The caption is optional!
"""
nimibCode:
  nbImage(url="images/todd-cravens-nimib-unsplash.jpg", caption="Blue Whale (photograph by Todd Cravens)")

nbCodeBlock: "nbVideo"
nbText: """
`nbVideo` allows you to display videos within your nimib document. You may choose if the
video autoplays, loops, and/or is muted.

The `typ` parameter specifies the video's MIME type, and is optional!
"""

nimibCode:
  nbVideo(url="media/bad_apple!!.mp4", typ="video/mp4")

nbCodeBlock: "nbAudio"
nbText: """
`nbAudio` enables you to play audio in nimib. You may choose if the audio autoplays,
loops, and/or is muted.

The `typ` parameter is similar to `nbVideo`'s.
"""

nimibCode:
  nbAudio(url="media/bad_apple!!.webm", loop=true)

nbCodeBlock: "nbFile"
nbText: """
`nbFile` can save the contents of block into a file or display the contents of a file. 

To save to a file it takes two arguments: the name of the file and the content of the file.
The content can be a string or a code block.
"""
nimibCode:
  nbFile("exampleCode.nim"):
    echo "This code will be saved in the exampleCode.nim file."

nbText: """

To display a file, it takes one argument: the file's path.
"""
nimibCode:
  nbFile("../LICENSE")

nbCodeBlock: "nbRawHtml"
nbText: """
Certain things are not doable with pure Markdown. You can use raw HTML directly with the `nbRawHtml` block.

For example, you have to use HTML style attribute and inject CSS styling in a HTML tag to center your titles (that is a Markdown limitation).

Here is the source code and the centered title:
"""
nimibCode:
  nbRawHtml: """<h4 style="text-align: center">Centered title</h4>"""

nbCodeBlock: "nbShow"
nbText: """
Nimib allows to pretty-print objects by rendering them to HTML. If the object has an associated `toHtml()` procedure, it can be rendered with `nbShow`.
"""

nimibCode:
  import datamancer
  let s1: seq[int] = @[22, 54, 34]
  let s2: seq[float] = @[1.87, 1.75, 1.78]
  let s3: seq[string] = @["Mike", "Laura", "Sue"]
  let df = toDf({ "Age" : s1,
                  "Height" : s2,
                  "Name" : s3 })
  nbShow(df)

nbCodeBlock: "nbClearOutput"
nbText: """
Clears the output of the preceding code block if you do not want to show it. This block is useful if you produce too long output or you do not want to show it.
It comes in handy when you want to plot with `ggplotnim` without the additional output that the library produces.
"""

nimibCode:
  nbCode:
    var i = 0
    while i < 1000:
      echo i
      inc i
  nbClearOutput

nbText: """
No output !!
"""

nbCodeBlock: "nimibCode"
nbText: """
`nimibCode` (do not be confused with `nbCode`) is a special block designed for those that want to spread their love of nimib.
It displays the code of a nimib document (even nbCode blocks), compiles and runs the block, and displays the potential output.

By clicking on the "Show source" button, you can see the multiple usages of this block in this document.

Happy coding!
"""

nbSave

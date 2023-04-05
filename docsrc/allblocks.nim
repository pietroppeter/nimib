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
The markdown syntax is explained in the [Markdown Cheatsheet](https://pietroppeter.github.io/nimib/cheatsheet.html).
"""
nimibCode:
  nbText: """
  #### Markdown Example
  My **text** is *formatted* with the 
  [Markdown](https://pietroppeter.github.io/nimib/cheatsheet.html) syntax.
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

nbCodeBlock: "nbCapture"
nbText: """

`nbCapture` is a block that only shows the captured output of a code block.
"""
nimibCode:
  nbCapture:
    echo "Captured!"

nbCodeBlock: "nbImage"
nbText: """
`nbImage` enables to display your favorite pictures.

Most formats (.jpg, .png) are accepted. The caption is optional!
"""
nimibCode:
  nbImage(url="images/todd-cravens-nimib-unsplash.jpg", caption="Blue Whale (photograph by Todd Cravens)")

nbCodeBlock: "nbFile"
nbText: """
`nbFile` saves the content of the block into a file. It takes two arguments: the name of the file and the content of the file.
The content can be a string or a code block.
"""
nimibCode:
  nbFile("exampleCode.nim"):
    echo "This code will be saved in the exampleCode.nim file."

nbCodeBlock: "nbRawHtml"
nbText: """
Certain things are not doable with pure Markdown. You can use raw HTML directly with the `nbRawHtml` block.

For example, you have to use HTML style attribute and inject CSS styling in a HTML tag to center your titles (that is a Markdown limitation).

Here is the source code and the centered title:
"""
nimibCode:
  nbRawHtml: """<h4 style="text-align: center">Centered title</h4>"""

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

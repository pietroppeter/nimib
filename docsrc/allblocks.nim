import nimoji
import nimib
import nimpy
import std/[math, strutils, strformat]

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

:warning: **This document is not finished as of now.**
""".emojize

addToc()

nbCodeBlock:"nbCodeSkip"
nbText: """
Similar to `nbCode`, `nbCodeSkip` is a block that displays 
highlighted code but does not compile or run it.

Example(s):
"""

nbCodeSkip:
  echo "Notice how there's no output?"
  echo "The code is not compiled or executed so no output is generated!"

nbCodeSkip:
  exit() # even this won't execute!

nbCodeBlock:"nbCapture"
nbText: """

`nbCapture` is a block that only shows the captured output of a code block.

Example:

The source code is pasted here to avoid you looking it up:
```nim
nbCapture:
  echo "Captured!"
```
And below is the actual block:
"""

nbCapture:
  echo "Captured!"

nbCodeBlock:"nbImage"
nbText: """
`nbImage` enables to display your favorite pictures.
```nim
nbImage(url="images/todd-cravens-nimib-unsplash.jpg", caption="Blue Whale (photograph by Todd Cravens)")
```
Most formats are accepted. The caption is optional!
"""

nbImage(url="images/todd-cravens-nimib-unsplash.jpg", caption="Blue Whale (photograph by Todd Cravens)")

nbCodeBlock:"nbTextWithCode"
nbText:"""
You can run Nim code directly in your markdown text with this block. It may be of use for instance for computation inside tables. See `numerical.nim`.
You just have to enclose your code into brackets e.g. `{Math.PI}` !.
"""

nbTextWithCode:fmt"""
The *fifteen* first digits of pi are {math.PI}. This constant defines the *ratio* between the *diameter* and the *perimeter* of a circle.
"""

nbCodeBlock:"nbRawHtml"
nbText:"""
Certain things are not doable with pure Markdown. You can use raw HTML directly with the `nbRawHtml` block.

For example, you have to use HTML style attribute and inject CSS styling in a HTML tag to center your titles (that is a Markdown limitation).

Here is the source code:
```html
<h2 style="text-align: center">Centered title</h2>
```
and the centered title:
"""

nbRawHtml:"""<h2 style="text-align: center">Centered title</h2>"""

nbCodeBlock:"nbPython"
nbText:"""
Python is supported too !
There are two requirements for the `nbPython` block.
First you need to install [nimpy](https://github.com/yglukhov/nimpy) and import it in your nimib script.
Second, you need to call `nbInitPython()`.
"""

nbInitPython()
nbPython:"""
def fib(n):
    a, b = 0, 1
    while a < n:
        print(a, end=' ')
        a, b = b, a+b
    print()
fib(1000)
"""

nbCodeBlock:"nbClearOutput"
nbText:"""
Clears the output of the preceding code block, which is useful if you produce too long output.
"""
nbPython:"""
fib(100000)
"""
nbClearOutput()

nbSave

import nimoji
import nimib
import nimpy
import std/[math, strformat]

nbInit

nbText: """
> This nimib document provides a brief description and example for 
> all blocks in nimib.

:warning: **This document is not finished as of now.**
""".emojize

nbText: """
### nbCodeSkip

Similar to `nbCode`, `nbCodeSkip` is a block that displays 
highlighted code but does not compile or run it.

Example(s):
"""

nbCodeSkip:
  echo "Notice how there's no output?"
  echo "The code is not compiled or executed so no output is generated!"

nbCodeSkip:
  exit() # even this won't execute!

nbText: """
### nbCapture

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

nbText: """
### nbImage
`nbImage` enables to display your favorite pictures.
```nim
nbImage(url="images/todd-cravens-nimib-unsplash.jpg", caption="Blue Whale (photograph by Todd Cravens)")
```
Most formats are accepted. The caption is optional!
"""

nbImage(url="images/todd-cravens-nimib-unsplash.jpg", caption="Blue Whale (photograph by Todd Cravens)")

nbText:"""
### nbTextWithCode
You can run Nim code directly in your markdown text with this block. It may be of use for instance for computation inside tables. See `numerical.nim`.
You just have to enclose your code into brackets e.g. `{Math.PI}` !.
"""

nbTextWithCode:fmt"""
The *fifteen* first digits of pi are {math.PI}. This constant defines the *ratio* between the *diameter* and the *perimeter* of a circle.
"""

nbText:"""
### nbRawHtml
Certain things are not doable with pure Markdown. You can use raw HTML directly with the `nbRawHtml` block.

For example, you have to use HTML style attribute and inject CSS styling in a HTML tag to center your titles (that is a Markdown limitation).

Here is the source code:
```html
<h2 style="text-align: center">Centered title</h2>
```
and the centered title:
"""

nbRawHtml:"""<h2 style="text-align: center">Centered title</h2>"""

nbText:"""
### nbPython
Python is supported too !
There are two requirements for the `nbPython` block.
First you need to install `nimpy` and import it in your nimib script.
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

nbSave

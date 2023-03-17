import nimoji
import nimib

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

Example(s):
"""

nbCapture:
  echo "Captured!"

nbSave

import nimib

nbInit
nbText: """## Files in nimib

Here is a short example of using files in nimib.
The api to use is `nbFile`.
"""
nbFile("module.nim"): """
const myNumber* = 42
"""

nbFile("main.nim"): """
import module

echo myNumber
"""

nbCode:
  import osproc
  echo execProcess("nim r --verbosity:0 --hints:off main")
nbSave

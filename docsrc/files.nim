import nimib

nbInit
nbText: """## `nbFile`

The template `nbFile` can be called with a string
or with an untyped body.

"""
nbFile("module.nim"):
  const myNumber* = 42

nbFile("main.nim"): """
import module

echo myNumber
"""

nbCode:
  import osproc
  echo execProcess("nim r --verbosity:0 --hints:off main")
nbSave

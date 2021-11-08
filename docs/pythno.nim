import nimib
import strutils

proc camel2snake(ident: string): string =
  for c in ident:
    if c.isUpperAscii:
      result.add "_"
    result.add c.toLowerAscii

nbInit
nbText: """
> This nimib example document shows how to use `nbBlock.code` and `nbBlock.output`
> to modify code and output of a block after it has run.
>
> The code looks like a repeat function written in python but it is actually written in nim.
"""
nbText: "# Pythno"

nbCode:
  proc repeat(text: string, num: int): string =
    result = ""
    for i in 1 .. num:
      result &= text
    ## and if I forgot to return? None!
  
  echo repeat("ThisIsNotPython", 6)

nb.blk.output = camel2snake(nb.blk.output)
nb.blk.code = nb.blk.code.multiReplace([
  ("proc", "def"),
  ("string", "str"),
  (";", ","), # tricky one
  (": string =", " -> str:"),
  ("\"\"", "''"),
  ("1 .. num", "range(num)"),
  ("&=", "+="),
  ("## and if I forgot to return? None!", "return result"), # needs a documentation comment
  ("echo ", "print("),
  ("6)", "6))"),
  ("ThisIsNotPython", camel2snake("ThisIsNotPython"))
])

nbSave
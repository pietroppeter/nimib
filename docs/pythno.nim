import nimib
import strutils

proc camel2snake(ident: string): string =
  for c in ident:
    if c.isUpperAscii:
      result.add "_"
    result.add c.toLowerAscii

nbInit

nbText: "# Pythno"

nbCode:
  proc repeat(text: string, num: int): string =
    result = ""
    for i in 1 .. num:
      result &= text
    ## and if I forgot to return? None!
  
  echo repeat("ThisIsNotPython", 6)

nbBlock.output = camel2snake(nbBlock.output)
nbBlock.code = nbBlock.code.multiReplace([
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
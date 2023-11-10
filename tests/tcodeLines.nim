import nimib
import unittest

suite "test sources":
  nbInit()
  enableLineNumbersDoc()
  nbCode:
    # a comment
    let
      x = 1
  nbSave()

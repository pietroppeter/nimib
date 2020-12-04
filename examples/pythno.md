# Pythno
```nim
proc repeat(text: string; num: int): string =
  result = ""
  for i in 1 .. num:
    result &= text
  ## and if I forgot to return? None!
  
echo repeat("ThisIsNotPython", 6)
```

```
ThisIsNotPythonThisIsNotPythonThisIsNotPythonThisIsNotPythonThisIsNotPythonThisIsNotPython
```


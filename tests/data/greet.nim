import std/strutils

proc greet*(name: string): string =
  ## says hi
  "hi " & name

proc shout*(s: string): string =
  s.toUpperAscii & "!"

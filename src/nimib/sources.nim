import std/[macros, sugar]
import std/[
  parseutils, 
  strutils
  ]
import types



# Credits to @haxscramper for sharing his code on reading the line info
# And credits to @Yardanico for making a previous attempt which I have taken much inspiration from.

type
  Pos* = object
    line*: int
    column*: int

proc toPos*(info: LineInfo): Pos =
  Pos(line: info.line, column: info.column)

proc startPos*(node: NimNode): Pos =
  ## Has column info
  case node.kind:
    of nnkNone .. nnkNilLit, nnkDiscardStmt, nnkCommentStmt:
      result = toPos(node.lineInfoObj())

    else:
      result = node[0].startPos()

proc finishPos*(node: NimNode): Pos =
  ## Does not have column info
  case node.kind:
    of nnkNone .. nnkNilLit, nnkDiscardStmt, nnkCommentStmt:
      result = toPos(node.lineInfoObj())
      #result.column += len($node) - 1 doesn't work for all NimNode kinds

    else:
      if len(node) > 0:
        var idx = len(node) - 1
        while idx >= 0 and node[idx].kind in {nnkEmpty}:
          dec idx

        if idx >= 0:
          result = node[idx].finishPos()

        else:
          result = toPos(node.lineInfoObj())

      else:
        result = toPos(node.lineInfoObj())

proc isCommandLine*(s: string, command: string): bool =
  nimIdentNormalize(command) in nimIdentNormalize(s)

func getCodeBlock*(source: string, command: string, startPos, endPos: Pos): string =
  ## Called by getCodeAsInSource
  let lines = source.split("\n")
  debugecho "Start line: ", startPos.line
  var startLine = startPos.line - 1
  var endLine = endPos.line - 1

  var codeText: string
  if not lines[startLine].isCommandLine(command): # multiline case
    while 0 < startLine and not lines[startLine-1].isCommandLine(command):
      #[ cases like this reports the third line instead of the second line:
        nbCode:
          let # this is the line we want
            x = 1 # but this is the one we get
      ]#
      dec startLine

    let indent = skipWhile(lines[startLine], {' '})
    let indentStr = " ".repeat(indent)

    if lines[endLine].count("\"\"\"") == 1: # only opening of triple quoted string found. Rest is below it. 
      inc endLine # bump it to not trigger the loop to immediately break
      while endLine < lines.high and "\"\"\"" notin lines[endLine]:
        inc endLine
        debugecho "Triple quote: ", lines[endLine]

    while endLine < lines.high and (lines[endLine+1].startsWith(indentStr) or lines[endLine+1].isEmptyOrWhitespace):# and lines[endLine+1].strip().startsWith("#"):
      # Ending Comments should be included as well, but they won't be included in the AST -> endLine doesn't take them into account.
      # Block comments must be properly indented (including the content)
      inc endLine

    var codeLines = lines[startLine .. endLine]

    var notIndentLines: seq[int] # these lines are not to be adjusted for indentation. Eg content of triple quoted strings.
    var i: int
    while i < codeLines.len:
      if codeLines[i].count("\"\"\"") == 1:
        # We must do the identification of triple quoted string separatly from the endLine bumping because the triple strings
        # might not be the last expression in the code block.
        inc i # bump it to not trigger the loop to immediately break on the initial """
        notIndentLines.add i
        while i < codeLines.len and "\"\"\"" notin codeLines[i]:
          inc i
          notIndentLines.add i
      inc i
      


    let parsedLines = collect(newSeqOfCap(codeLines.len)):
      for i in 0 .. codeLines.high:
        if i in notIndentLines:
          codeLines[i]
        else:
          codeLines[i].substr(indent)
    codeText = parsedLines.join("\n")
    #codeText = codeLines.mapIt(it.substr(indent)).join("\n")

  else: # single line case, eg `nbCode: echo "Hello World"`
    let line = lines[startLine]
    codeText = line.split(":")[1 .. ^1].join(":").strip() # split at first ":" and take the rest as code and then strip it.
  return codeText

macro getCodeAsInSource*(source: static string, command: static string, body: untyped): static string =
  ## substitute for `toStr` in blocks.nim
  let startPos = startPos(body)
  let endPos = finishPos(body)
  let lObj = body.lineInfoObj()
  let codeText = getCodeBlock(source, command, startPos, endPos)
  result = newLit(codeText)
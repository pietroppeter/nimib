import std/[macros, sugar]
import std/[
  parseutils, 
  strutils
  ]
import types



# Credits to @haxscramper for sharing his code on reading the line info
# And credits to @Yardanico for making a previous attempt which @hugogranstrom have taken much inspiration from
# when implementing this.

type
  Pos* = object
    line*: int
    column*: int

proc toPos*(info: LineInfo): Pos =
  Pos(line: info.line, column: info.column)

proc startPos*(node: NimNode): Pos =
  ## Get the starting position of a NimNode. Corrections will be needed for certains cases though.
  # Has column info
  case node.kind:
    of nnkNone .. nnkNilLit, nnkDiscardStmt, nnkCommentStmt:
      result = toPos(node.lineInfoObj())

    else:
      result = node[0].startPos()

proc finishPos*(node: NimNode): Pos =
  ## Get the ending position of a NimNode. Corrections will be needed for certains cases though.
  # Does not have column info
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
  nimIdentNormalize(s.strip()).startsWith(nimIdentNormalize(command))

func getCodeBlock*(source: string, command: string, startPos, endPos: Pos): string =
  ## Extracts the code in source from startPos to endPos with additional processing to get the entire code block.
  let lines = source.split("\n")
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

  else: # single line case, eg `nbCode: echo "Hello World"`
    let line = lines[startLine]
    var extractedLine = line[startPos.column .. ^1].strip()
    if extractedLine.strip().endsWith(")"):
      # check if the ending ")" has a matching "(", otherwise remove it.
      var nOpen, nClose: int
      for c in extractedLine:
        if c == '(': nOpen += 1
        elif c == ')': nClose += 1
      if nOpen < nClose:
        # remove trailing ")" so that we get matching number of "()".
        # We trust the compiler to only give us valid code, thus we can assume all ")" are at the end as the missing "("
        # are expected to exist before line[startPos.column].
        let diff = nClose - nOpen
        extractedLine = extractedLine[0 .. ^(diff+1)]
    codeText = extractedLine
  return codeText

macro getCodeAsInSource*(source: string, command: static string, body: untyped): string =
  ## Returns string for the code in body from source. 
  # substitute for `toStr` in blocks.nim
  let startPos = startPos(body)
  let endPos = finishPos(body)
  result = quote do:
    getCodeBlock(`source`, `command`, `startPos`, `endPos`)
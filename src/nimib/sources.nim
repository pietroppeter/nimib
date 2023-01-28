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
    filename*: string
    line*: int
    column*: int

proc `<`*(p1, p2: Pos): bool =
  doAssert p1.filename == p2.filename, """
  Code from two different files were found in the same nbCode!
  If you want to mix code from different files in nbCode, use -d:nimibCodeFromAst instead. 
  If you are not mixing code from different files, please open an issue on nimib's Github with a minimal reproducible example."""
  (p1.line, p1.column) < (p2.line, p2.column)

proc toPos*(info: LineInfo): Pos =
  Pos(line: info.line, column: info.column, filename: info.filename)

proc startPos(node: NimNode): Pos =
  case node.kind
  of nnkStmtList:
    return node[0].startPos()
  else:
    result = toPos(node.lineInfoObj())
    for child in node.children:
      let childPos = child.startPos()
      # If we can't get the line info for some reason, skip it!
      if childPos.line == 0: continue
      
      if childPos < result:
        result = childPos


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

proc isCommentLine*(s: string): bool =
  s.strip.startsWith('#')

proc findStartLine*(source: seq[string], startPos: Pos): int =
  let line = source[startPos.line - 1]
  let preline = line[0 ..< startPos.column - 1]
  # Multiline, we need to check further up for comments
  if preline.isEmptyOrWhitespace:
    result = startPos.line - 1
    # Make sure we catch all comments
    while source[result-1].isCommentLine() or source[result-1].isEmptyOrWhitespace() or source[result-1].nimIdentNormalize.strip() == "type":
      dec result
    # Now remove all empty lines
    while source[result].isEmptyOrWhitespace():
      inc result
  else: # starts on same line as command
    return startPos.line - 1


proc findEndLine*(source: seq[string], command: string, startLine, endPos: int): int =
  result = endPos
  # Handle if line is an unclosed triple-quote string
  if source[endPos].count("\"\"\"") mod 2 == 1:
    inc result # bump it to not trigger the loop to immediately break
    while result < source.high and source[result].count("\"\"\"") mod 2 == 0:
      inc result
  # Handle if there are ending comments
  let startsOnCommandLine = source[startLine].isCommandLine(command)
  if result > startLine or not startsOnCommandLine:
    let baseIndent =
      if source[startLine].isCommandLine(command):
        skipWhile(source[startLine], {' '}) + 1 # we want to add indent here.
        # this is problematic because we don't know the indentation of the code block because
        # we don't know the indentation size used. So we just add 1 and check that it is larger or equal.
      else:
        skipWhile(source[startLine], {' '})
    let baseIndentStr = " ".repeat(baseIndent)
    while result < source.high and (source[result+1].startsWith(baseIndentStr) or source[result+1].isEmptyOrWhitespace):
      inc result

proc getCodeBlock*(source, command: string, startPos, endPos: Pos): string =
  ## Extracts the code in source from startPos to endPos with additional processing to get the entire code block.
  let rawLines = source.splitLines()
  let rawStartLine = startPos.line - 1
  let rawStartCol = startPos.column - 1
  var startLine = findStartLine(rawLines, startPos)
  var endLine = findEndLine(rawLines, command, startLine, endPos.line - 1)

  var lines = rawLines[startLine .. endLine]

  let startsOnCommandLine = block:
    let preline = lines[0][0 ..< rawStartCol]
    startLine == rawStartLine and (not preline.isEmptyOrWhitespace) and (not (preline.nimIdentNormalize.strip() in ["for", "type"]))
    
  if startsOnCommandLine:
    lines[0] = lines[0][rawStartCol .. ^1].strip()
  
  if startLine == endLine and startsOnCommandLine:
    # single line expression
    var line = lines[0] # doesn't include command, but includes opening parenthesis
    while line.startsWith('(') and line.endsWith(')'):
      line = line[1 .. ^2].strip()

    result = line
  else: # multi-line expression
    let baseIndent = skipWhile(rawLines[startLine], {' '})
    var preserveIndent: bool = false
    for i in 0 .. lines.high:
      let line = lines[i]
      let nonMatching = line.count("\"\"\"") mod 2 == 1
      if not preserveIndent and not (i == 0 and startsOnCommandLine): # don't de-indent first line if it starts on command line
        lines[i] = line.substr(baseIndent)
      if nonMatching: # there is a non-matching triple-quote string
        preserveIndent = not preserveIndent
    result = lines.join("\n")

macro getCodeAsInSource*(source: string, command: static string, body: untyped): string =
  ## Returns string for the code in body from source. 
  # substitute for `toStr` in blocks.nim
  let startPos = startPos(body)
  let filename = startPos.filename.newLit
  let endPos = finishPos(body)
  let endFilename = endPos.filename.newLit

  result = quote do:
    if `filename` notin nb.sourceFiles:
      nb.sourceFiles[`filename`] = readFile(`filename`)

    doAssert `endFilename` == `filename`, """
    Code from two different files were found in the same nbCode!
    If you want to mix code from different files in nbCode, use -d:nimibCodeFromAst instead. 
    If you are not mixing code from different files, please open an issue on nimib's Github with a minimal reproducible example."""

    getCodeBlock(nb.sourceFiles[`filename`], `command`, `startPos`, `endPos`)
import std/[macros, sugar]
import std/[
  parseutils, 
  strutils
  ]
import types



# Credits to @haxscramper for sharing his code on reading the line info
# And credits to @Yardanico for making a previous attempt which @hugogranstrom have taken much inspiration from
# when implementing this.

## TODO:
## Use add filename to LineInfo
## Use a table[filename, filecontent] to query for the lines of code.
## Find startLine is easy now, but we need to still do some analysis.
## Look to the left on the start line:
##  if empty: we are in a multiline block, check above for empty lines and comments until we reach non-empty non-comment line.
##  if something there: we start on the same line as command
## What if we have multiline expr that starts on the command line? Indentation?
## Are there cases other than triple-qouted strings that we won't catch using finishPos? If not, we check for unclosed strings.

type
  Pos* = object
    filename*: string
    line*: int
    column*: int

proc toPos*(info: LineInfo): Pos =
  Pos(line: info.line, column: info.column, filename: info.filename)

proc startPos*(node: NimNode): Pos =
  ## Get the starting position of a NimNode. Corrections will be needed for certains cases though.
  # Has column info
  case node.kind:
    of nnkNone .. nnkNilLit, nnkDiscardStmt, nnkCommentStmt:
      result = toPos(node.lineInfoObj())
    of nnkBlockStmt:
      result = node[1].startPos()
    else:
      result = node[0].startPos()

proc startPosNew(node: NimNode): Pos =
  case node.kind
  of nnkStmtList, nnkCall, nnkCommand, nnkCallStrLit, nnkAsgn, nnkDotExpr, nnkBracketExpr:
    # needed for it to work in templates.
    return node[0].startPosNew()
  of nnkInfix:
    return node[1].startPosNew()
  else:
    return toPos(node.lineInfoObj())

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

proc findStartLine*(source: seq[string], command: string, startPos: int): int =
  if source[startPos].isCommandLine(command):
    return startPos
  # The code is starting on a line below the command
  # Decrease result until it is on the line below the command
  result = startPos
  while not source[result-1].isCommandLine(command):
    dec result
  # Remove empty lines at the beginning of the block
  while source[result].isEmptyOrWhitespace:
    inc result


proc findStartLineNew*(source: seq[string], startPos: Pos): int =
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

proc getCodeBlockNew*(source, command: string, startPos, endPos: Pos): string =
  ## Extracts the code in source from startPos to endPos with additional processing to get the entire code block.
  let rawLines = source.splitLines()
  let rawStartLine = startPos.line - 1
  let rawStartCol = startPos.column - 1
  var startLine = findStartLineNew(rawLines, startPos)
  var endLine = findEndLine(rawLines, command, startLine, endPos.line - 1)

  var lines = rawLines[startLine .. endLine]

  let startsOnCommandLine = block:
    let preline = lines[0][0 ..< rawStartCol]
    startLine == rawStartLine and (not preline.isEmptyOrWhitespace) and (not (preline.nimIdentNormalize.strip() == "for"))
    
  if startsOnCommandLine:
    lines[0] = lines[0][rawStartCol .. ^1].strip()
  
  if startLine == endLine and startsOnCommandLine:
    # single line expression
    var line = lines[0] # doesn't include command, includes opening parenthesis
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
      
    


proc getCodeBlock*(source, command: string, startPos, endPos: Pos): string =
  ## Extracts the code in source from startPos to endPos with additional processing to get the entire code block.
  let rawLines = source.split("\n")
  var startLine = findStartLine(rawLines, command, startPos.line - 1)
  var endLine = findEndLine(rawLines, command, startLine, endPos.line - 1)

  var lines = rawLines[startLine .. endLine]

  let baseIndent = skipWhile(rawLines[startLine], {' '})

  let startsOnCommandLine = lines[0].isCommandLine(command) # is it nbCode: code or nbCode: <enter> code
  if startsOnCommandLine: # remove the command
    var startColumn = startPos.column
    # the "import"-part is not included in the startPos
    let startsWithImport = lines[0].find("import")
    if startsWithImport != -1:
      startColumn = startsWithImport
    lines[0] = lines[0][startColumn .. ^1].strip()

  var codeText: string
  if startLine == endLine and startsOnCommandLine: # single-line expression 
    # remove eventual unneccerary parenthesis
    let line = rawLines[startLine] # includes command and eventual opening parethesises
    var extractedLine = lines[0] # doesn't include command
    if extractedLine.endsWith(")"):
      # check if the ending ")" has a matching "(", otherwise remove it.
      var nOpen: int
      var i = startPos.column
      # count the number of opening brackets before code starts.
      while line[i-1] in Whitespace or line[i-1] == '(':
        if line[i-1] == '(':
          nOpen += 1
        i -= 1
      var nRemoved: int
      while nRemoved < nOpen: # remove last char until we have removed correct number of parentesis
                              # We assume we are given correct Nim code and thus won't have to check what we remove, it should either be Whitespace or ')'
        assert extractedLine[^1] in Whitespace or extractedLine[^1] == ')', "Unexpected ending of string during parsing. Single line expression ended with character that wasn't whitespace of ')'."
        if extractedLine[^1] == ')':
          nRemoved += 1
        extractedLine.setLen(extractedLine.len-1)
    codeText = extractedLine
  else: # multi-line expression
    var preserveIndent: bool = false
    for i in 0 .. lines.high:
      let line = lines[i]
      let nonMatching = line.count("\"\"\"") mod 2 == 1
      if not preserveIndent and not (i == 0 and startsOnCommandLine): # don't de-indent first line if it starts on command line
        lines[i] = line.substr(baseIndent)
      if nonMatching: # there is a non-matching triple-quote string
        preserveIndent = not preserveIndent
    codeText = lines.join("\n")
  result = codeText


  

func getCodeBlockOld*(source: string, command: string, startPos, endPos: Pos): string =
  ## Extracts the code in source from startPos to endPos with additional processing to get the entire code block.
  let lines = source.split("\n")
  var startLine = startPos.line - 1
  var endLine = endPos.line - 1
  debugecho "Start line: ", startLine + 1, startPos
  debugecho "End line: ", endLine + 1, endPos
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
  elif lines[startLine].isCommandLine(command) and "\"\"\"" in lines[startLine]: # potentially multiline string 
    discard
  else: # single line case, eg `nbCode: echo "Hello World"`
    let line = lines[startLine]
    var extractedLine = line[startPos.column .. ^1].strip()
    if extractedLine.strip().endsWith(")"):
      # check if the ending ")" has a matching "(", otherwise remove it.
      var nOpen: int
      var i = startPos.column
      # count the number of opening brackets before code starts.
      while line[i-1] in Whitespace or line[i-1] == '(':
        if line[i-1] == '(':
          nOpen += 1
        i -= 1
      var nRemoved: int
      while nRemoved < nOpen: # remove last char until we have removed correct number of parentesis
                              # We assume we are given correct Nim code and thus won't have to check what we remove, it should either be Whitespace or ')'
        assert extractedLine[^1] in Whitespace or extractedLine[^1] == ')', "Unexpected ending of string during parsing. Single line expression ended with character that wasn't whitespace of ')'."
        if extractedLine[^1] == ')':
          nRemoved += 1
        extractedLine.setLen(extractedLine.len-1)
    codeText = extractedLine
  return codeText

macro getCodeAsInSource*(source: string, command: static string, body: untyped): string =
  ## Returns string for the code in body from source. 
  # substitute for `toStr` in blocks.nim
  let startPos = startPosNew(body)
  let filename = startPos.filename.newLit
  let endPos = finishPos(body)
  result = quote do:
    if `filename` notin nb.sourceFiles:
      nb.sourceFiles[`filename`] = readFile(`filename`)
    getCodeBlockNew(nb.sourceFiles[`filename`], `command`, `startPos`, `endPos`)
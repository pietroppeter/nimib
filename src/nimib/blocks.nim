import macros
import types, capture

macro toStr*(body: untyped): string =
  (body.toStrLit)

proc newBlock*(kind: NbBlockKind, code: string): NbBlock =
  # I cannot use this directly in nbBlocks (nbText, nbCode, ...)
  # or it will substitute kind and body fields with their values
  NbBlock(kind: kind, code: code)

template manageErrors*(identBlock, body: untyped) =
  try:
    body
  except:
    let
      e = getCurrentException()
      msg = getCurrentExceptionMsg()
    identBlock.error = "ERROR: Got exception " & repr(e) & " with message " & msg

template nbTextBlock*(identBlock, identContainer, body: untyped) =
  # assume body is a string
  identBlock = newBlock(nbkText, toStr(body))  # nbDoc.flags.update(flags)
  identBlock.output = block:
    body
  when not defined(nimibQuiet):
    echo identBlock.output
  identContainer.blocks.add identBlock

proc echoCodeBlock(b: NbBlock) =
  when not defined(nimibQuiet):
    echo "```nim" & b.code & "\n```\n"
    if b.output != "":
      echo "```\n" & b.output & "```\n"


# Credits to @haxscramper for sharing his code on reading the line info
# And credits to @Yardanico for making a previous attempt which I have taken much inspiration from.

type
  Pos* = object
    line*: int
    column*: int

proc toPos(info: LineInfo): Pos =
  Pos(line: info.line, column: info.column)

proc startPos(node: NimNode): Pos =
  ## Has column info
  case node.kind:
    of nnkNone .. nnkNilLit, nnkDiscardStmt, nnkCommentStmt:
      result = toPos(node.lineInfoObj())

    else:
      result = node[0].startPos()

proc finishPos(node: NimNode): Pos =
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

import std/[
  sequtils,
  parseutils, 
  strutils
  ]
import std/unicode except strip
export
  strutils.split, strutils.contains, strutils.strip, strutils.join,
  unicode.toLower,
  sequtils.mapIt,
  parseutils.skipWhile

proc isNbCodeLine*(s: string): bool =
  "nbcode" in s.toLower

macro nbCodeBlock*(identBlock, identContainer, body: untyped) =
  let startPos = startPos(body)
  let endPos = finishPos(body)
  let lObj = body.lineInfoObj()
  let filename = body.lineInfoObj().filename
  #bind mapIt, skipWhile, toLower, split, contains
  result = quote do:
    const entireFile = staticRead(`filename`)
    let lines = entireFile.split("\n")
    echo "Filename: ", `lObj`
    echo "Start line: ", `startPos`.line
    var startLine = `startPos`.line - 1
    var endLine = `endPos`.line - 1
    if not lines[startLine].isNbCodeLine: # only check if not single.line case
      while 0 < startLine and not lines[startLine-1].isNbCodeLine:
        #[ cases like this reports the third line instead of the second line:
          nbCode:
            let # this is the line we want
              x = 1 # but this is the one we get
        ]#
        dec(startLine)
    var codeLines = lines[startLine .. endLine]
    var codeText: string
    if codeLines.len == 1 and codeLines[0].isNbCodeLine:
      # check if it is written single line: nbCode: echo "Hello World"
      let line = codeLines[0]
      codeText = line.split(":")[1 .. ^1].join(":").strip() # split at first ":" and take the rest as code and then strip it.
      echo "Single line after! ", codeText
    else:
      let indent = skipWhile(codeLines[0], {' '})
      echo "Indent: ", indent
      codeText = codeLines.mapIt(it.substr(indent)).join("\n")
    
    `identBlock` = newBlock(nbkCode, codeText)
    captureStdout(`identBlock`.output):
      `body`
    echoCodeBlock `identBlock`
    `identContainer`.blocks.add `identBlock`
  echo result.repr

#[
template nbCodeBlock*(identBlock, identContainer, body: untyped) =
  identBlock = newBlock(nbkCode, toStr(body))
  captureStdout(identBlock.output):
    body
  echoCodeBlock identBlock
  identContainer.blocks.add identBlock
]#
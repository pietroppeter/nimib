import std/[macros, sugar]
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

template nbCodeBlock*(identBlock, identContainer, body: untyped) =
  identBlock = newBlock(nbkCode, toStr(body))
  captureStdout(identBlock.output):
    body
  echoCodeBlock identBlock
  identContainer.blocks.add identBlock
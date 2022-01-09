import std / [macros, strutils, sugar]
import types, capture, sources

macro toStr*(body: untyped): string =
  (body.toStrLit)

func peekFirstLineOf*(text: string, maxChars=12): string =
  for i in 0 ..< min(text.len, maxChars):
    if text[i] in ['\n', '\c', '\l']:
      break
    result.add text[i]
  if result.len < text.len:
    result.add "..."

func nbNormalize*(text: string): string =
  text.replace("\c\l", "\n").replace("\c", "\n").strip # this could be made more efficient
# note that: '\c' == '\r' and '\l' == '\n'

template newNbBlock*(cmd: string, nbDoc, nbBlock, body, blockImpl: untyped) =
  stdout.write "[nimib] ", nbDoc.blocks.len, " ", cmd, ": "
  nbBlock = NbBlock(command: cmd, context: newContext(searchDirs = @[], partials = nbDoc.partials))
  nbBlock.code = nbNormalize:
    when defined(nimibPreviewCodeAsInSource):
      getCodeAsInSource(nbDoc.source, cmd, body)
    else:
      toStr(body)
  echo peekFirstLineOf(nbBlock.code)
  blockImpl
  if len(nbBlock.output) > 0: echo "     -> ", peekFirstLineOf(nbBlock.output)
  nbBlock.context["code"] = nbBlock.code
  nbBlock.context["output"] = nbBlock.output.dup(removeSuffix)
  nbDoc.blocks.add nbBlock

# refactor: to remove
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

template nbCodeBlock*(source: string, identBlock, identContainer, body: untyped) =
  var codeText: string
  when defined(nimibPreviewCodeAsInSource):
    codeText = getCodeAsInSource(source, "nbCode", body)
  else:
    codeText = toStr(body)
  identBlock = newBlock(nbkCode, codeText)
  captureStdout(identBlock.output):
    body
  echoCodeBlock identBlock
  identContainer.blocks.add identBlock
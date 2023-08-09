import std / [macros, strutils, sugar]
import types, sources, capture

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

template newNbBlock*(cmd: string, readCode: static[bool], nbDoc, nbBlock, body, blockImpl: untyped) =
  disableCaptureStdout:
    stdout.write "[nimib] ", nbDoc.blocks.len, " ", cmd, ": "
  nbBlock = NbBlock(command: cmd, context: newContext(searchDirs = @[], partials = nbDoc.partials))
  when readCode:
    nbBlock.code = nbNormalize:
      when defined(nimibCodeFromAst):
        toStr(body)
      else:
        getCodeAsInSource(nbDoc.source, cmd, body)
  disableCaptureStdout:
    echo peekFirstLineOf(nbBlock.code)
  blockImpl
  disableCaptureStdout:
    if len(nbBlock.output) > 0: echo "     -> ", peekFirstLineOf(nbBlock.output)
  nbBlock.context["code"] = nbBlock.code
  nbBlock.context["output"] = nbBlock.output.dup(removeSuffix)
  nbDoc.blocks.add nbBlock

when defined(nimibPreviewCodeAsInSource):
  {.warning: "-d:nimibPreviewCodeAsInSource is now default (since 0.3), old default is available with -d:nimibCodeFromAst".}

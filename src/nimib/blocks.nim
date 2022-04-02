import std / [macros, strutils, sugar]
import types, sources

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
  stdout.write "[nimib] ", nbDoc.blocks.len, " ", cmd, ": "
  nbBlock = NbBlock(command: cmd, context: newContext(searchDirs = @[], partials = nbDoc.partials))
  when readCode:
    nbBlock.code = nbNormalize:
      when defined(nimibPreviewCodeAsInSource):
        getCodeAsInSource(nbDoc.source, cmd, body)
      else:
        toStr(body)
  echo peekFirstLineOf(nbBlock.code)
  blockImpl
  echo "here"
  if len(nbBlock.output) > 0: echo "     -> ", peekFirstLineOf(nbBlock.output)
  echo "here2"
  nbBlock.context["code"] = nbBlock.code
  nbBlock.context["output"] = nbBlock.output.dup(removeSuffix)
  nbDoc.blocks.add nbBlock
  echo "here3"

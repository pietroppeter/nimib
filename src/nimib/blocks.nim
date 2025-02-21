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

proc add*(nb: var Nb, blk: NbBlock) =
  nb.blk = blk
  if nb.containers.len == 0:
    nb.doc.blocks.add blk
  else:
    nb.containers[^1].blocks.add blk

template withContainer*(nb: var Nb, container: NbContainer, body: untyped) =
  # nb.add container # should this be here?
  nb.containers.add container
  body
  discard nb.containers.pop

func blocksFlattened*(doc: NbContainer): seq[NbBlock] =
  for blk in doc.blocks:
    result.add blk
    if blk of NbContainer:
      result.add blk.NbContainer.blocksFlattened()

# do we need this anymore? How do we implement something similar now? I'm thinking mainly of the logging
# insert it into the newBlockName procs?
template newNbBlockOld*(cmd: string, readCode: static[bool], nbDoc, nbBlock, body, blockImpl: untyped) =
  stdout.write "[nimib] ", nbDoc.blocks.len, " ", cmd, ": "
  nbBlock = NbBlock(command: cmd, context: newContext(searchDirs = @[], partials = nbDoc.partials))
  when readCode:
    nbBlock.code = nbNormalize:
      when defined(nimibCodeFromAst):
        toStr(body)
      else:
        getCodeAsInSource(nbDoc.source, cmd, body)
  echo peekFirstLineOf(nbBlock.code)
  blockImpl
  if len(nbBlock.output) > 0: echo "     -> ", peekFirstLineOf(nbBlock.output)
  nbBlock.context["code"] = nbBlock.code
  nbBlock.context["output"] = nbBlock.output.dup(removeSuffix)
  nbDoc.blocks.add nbBlock

when defined(nimibPreviewCodeAsInSource):
  {.warning: "-d:nimibPreviewCodeAsInSource is now default (since 0.3), old default is available with -d:nimibCodeFromAst".}

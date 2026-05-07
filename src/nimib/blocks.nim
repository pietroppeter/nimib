import std / [macros, strutils, sugar]
import types, sources, logging

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
  nb.containers.add container
  body
  discard nb.containers.pop

func blocksFlattened*(doc: NbContainer): seq[NbBlock] =
  for blk in doc.blocks:
    result.add blk
    if blk of NbContainer:
      result.add blk.NbContainer.blocksFlattened()

when defined(nimibPreviewCodeAsInSource):
  {.warning: "-d:nimibPreviewCodeAsInSource is now default (since 0.3), old default is available with -d:nimibCodeFromAst".}

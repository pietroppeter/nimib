# types.nim
import tables

type
  NbBlock = ref object of RootObj
    kind: string
  NbRenderFunc = proc (blk: NbBlock, nb: Nb): string {. noSideEffect .}
  NbRender = object
    funcs: Table[string, NbRenderFunc] 
  NbDoc = ref object of NbBlock
    blocks: seq[NbBlock]
  Nb = object
    blk: NbBlock # last block processed
    doc: NbDoc # could be a NbBlock but we could give more guarantees with a NbDoc
    backend: NbRender

# this needs to be know for all container blocks
func render(nb: Nb, blk: NbBlock): string =
  if blk.kind in nb.backend.funcs:
    nb.backend.funcs[blk.kind](blk, nb)
  else:
    ""

# themes.nim
import std / strutils

func nbDocToHtml*(blk: NbBlock, nb: Nb): string =
  let blk = blk.NbDoc
  var blocks: seq[string]
  for b in blk.blocks:
    blocks.add nb.render(b)
  "<!DOCTYPE html>\n<html><head></head>\n<body>\n" & blocks.join("\n") & "\n</body>\n</html>"


# nimib.nim
import markdown

template nbInit* =
  var nb {. inject .}: Nb
  nb.doc = NbDoc()
  nb.doc.kind = "NbDoc"
  nbInitBackend

template nbSave* =
  echo nb.render nb.doc

# all other blocks are in a sense all custom blocks
# we could add sugar for common block creation
type
  NbText = ref object of NbBlock
    text: string
template nbText*(ttext: string) =
  nb.blk = NbText(text: ttext, kind: "NbText")
  nb.doc.blocks.add nb.blk
func nbTextToHtml*(blk: NbBlock, nb: Nb): string =
  let blk = blk.NbText
  {.cast(noSideEffect).}: # not sure why markdown is marked with side effects
    markdown(blk.text, config=initGfmConfig())
#[ the above could be shortened with sugar to:
newNbBlock(nbText):
  text: string
  toHtml:
    {.cast(noSideEffect).}: # not sure why markdown is marked with side effects
      markdown(blk.text, config=initGfmConfig())
]#



type
  NbImage = ref object of NbBlock
    url: string
template nbImage*(turl: string) =
  nb.blk = NbImage(url: turl, kind: "NbImage")
  nb.doc.blocks.add nb.blk
func nbImageToHtml*(blk: NbBlock, nb: Nb): string =
  let blk = blk.NbImage
  "<img src= '" & blk.url & "'>"
#[ the above could be shortened with sugar to:
newNbBlock(nbImage):
  url: string
  toHtml:
    "<img src= '" & blk.url & "'>"
]#



template addToBackend*(kind: string, f: NbRenderFunc) =
  nb.backend.funcs[kind] = f

template nbInitBackend* =
  addToBackend("NbImage", nbImageToHtml)
  addToBackend("NbText", nbTextToHtml)
  addToBackend("NbDoc", nbDocToHtml)

when isMainModule:
  import print
  # hello.nim
  nbInit
  nbText: "*hi*"
  nbImage("img.png")
  nbSave

  print nb
  print nb.doc.blocks[0]
  print nb.doc.blocks[0].NbText
  print nb.render nb.doc.blocks[0]
  # print nb.blocks[0].NbImage # correctly fails at runtime
  print nb.doc.blocks[1].NbImage
  print nb.render nb.doc.blocks[1]

  print nb.render nb.doc

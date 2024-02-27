# types.nim
import tables

type
  NbBlock = ref object of RootObj
  NbText = ref object of NbBlock
    text: string
  NbImage = ref object of NbBlock
    url: string
  NbDoc = ref object of NbBlock
    blocks: seq[NbBlock]
  Nb = object
    blk: NbBlock
    doc: NbDoc

# nimib.nim
template nbInit* =
  var nb {. inject .}: Nb
  nb.doc = NbDoc()

template nbText*(ttext: string) =
  nb.blk = NbText(text: ttext)
  nb.doc.blocks.add nb.blk

template nbImage*(turl: string) =
  nb.blk = NbImage(url: turl)
  nb.doc.blocks.add nb.blk

template nbSave* =
  discard

when isMainModule:
  import print
  # hello.nim
  nbInit
  nbText: "hi"
  nbImage("img.png")
  nbSave

  print nb
  print nb.doc.blocks[0]
  print nb.doc.blocks[0].NbText
  # print nb.blocks[0].NbImage # correctly fails at runtime
  print nb.doc.blocks[1].NbImage

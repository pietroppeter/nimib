# types.nim
type
  NbBlock = ref object of RootObj
  NbText = ref object of NbBlock
    text: string
  NbImage = ref object of NbBlock
    url: string
  NbDoc = object
    blk: NbBlock
    blocks: seq[NbBlock]

# nimib.nim
template nbInit* =
  var nb {. inject .}: NbDoc 

template nbText*(ttext: string) =
  nb.blk = NbText(text: ttext)
  nb.blocks.add nb.blk

template nbImage*(turl: string) =
  nb.blk = NbImage(url: turl)
  nb.blocks.add nb.blk

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
  print nb.blocks[0]
  print nb.blocks[0].NbText
  # print nb.blocks[0].NbImage # correctly fails at runtime
  print nb.blocks[1].NbImage

# types.nim
import tables

type
  NbBlock = ref object of RootObj
    kind: string
  NbText = ref object of NbBlock
    text: string
  NbImage = ref object of NbBlock
    url: string
  NbDoc = ref object of NbBlock
    blocks: seq[NbBlock]
  NbRenderFunc = proc (blk: NbBlock): string {. noSideEffect .}
  NbRender = object
    funcs: Table[string, NbRenderFunc] 
  Nb = object
    blk: NbBlock # last block processed
    doc: NbDoc
    backend: NbRender

# nimib.nim
import markdown

template nbInit* =
  var nb {. inject .}: Nb
  nb.doc = NbDoc()
  nb.doc.kind = "NbDoc"
  nbInitBackend

template nbText*(ttext: string) =
  nb.blk = NbText(text: ttext)
  nb.blk.kind = "NbText"
  nb.doc.blocks.add nb.blk

template nbImage*(turl: string) =
  nb.blk = NbImage(url: turl)
  nb.blk.kind = "NbImage"
  nb.doc.blocks.add nb.blk

func nbImageToHtml*(blk: NbBlock): string =
  let blk = blk.NbImage
  "<img src= '" & blk.url & "'>"

func nbTextToHtml*(blk: NbBlock): string =
  let blk = blk.NbText
  {.cast(noSideEffect).}: # not sure why markdown is marked with side effects
    markdown(blk.text, config=initGfmConfig())

template addToBackend*(kind: string, f: NbRenderFunc) =
  nb.backend.funcs[kind] = f

template nbInitBackend* =
  addToBackend("NbImage", nbImageToHtml)
  addToBackend("NbText", nbTextToHtml)

func render(nb: Nb, blk: NbBlock): string =
  if blk.kind in nb.backend.funcs:
    nb.backend.funcs[blk.kind](blk)
  else:
    ""

template nbSave* =
  discard

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
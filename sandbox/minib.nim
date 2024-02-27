# minib (a mini nimib)
import strformat, macros

macro toStr*(body: untyped): string =
  (body.toStrLit)

type
  NbBase* = ref object of RootObj
    partial*: string
  NbText* = ref object of NbBase
    text*: string
  NbCode* = ref object of NbBase
    code*: string
    output*: string
  NbImage* = ref object of NbBase
    url*: string
  NbSummaryDetails* = ref object of NbBase
    summary*: string
    details*: seq[NbBase]
  NbDoc* = object
    blocks*: seq[NbBase]

template nbInit =
  var nb {. inject .}: NbDoc

template nbImage(url2: string) =
  nb.blocks.add NbImage(
    url: url2,
    partial: "<img href=\"{{url}}\"><img>"
  )

# alternative api, similar to python, not used in nimib
proc image(nb: var NbDoc, url: string) =
  nb.blocks.add NbImage(url: url)

when isMainModule:
  import print

  nbInit
  nbImage: "img1"
  nb.image("img2")

  print nb
  print nb.blocks[0].NbImage.url
  print nb.blocks[1].NbImage.url
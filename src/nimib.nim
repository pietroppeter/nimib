import nimib / [types, blocks, docs]
export types, blocks, docs
# default setup:
import nimib / htmldefault
import os

template nbInit*(templateDirs= @["./", "./templates/"]) =
  var
    nbDoc: NbDoc
    nbBlock: NbBlock

  template nbText(body: untyped) =
    nbTextBlock(nbBlock, nbDoc, body)

  template nbCode(body: untyped) =
    nbCodeBlock(nbBlock, nbDoc, body)

  template nbSave =
    write nbDoc

  template nbShow =
    write nbDoc
    open nbDoc

  nbDoc.renderer = renderHtml
  nbDoc.searchDirs = templateDirs # error in template if name of field is templateDirs? how to fix this?
  nbDoc.sourceFilename = instantiationInfo(fullpaths=true).filename

  let params = commandLineParams()
  if params.len > 0:
    nbDoc.filename = changeFileExt(params[0], "html")
  else:
    nbDoc.filename = changeFileExt(nbDoc.sourceFilename, "html")



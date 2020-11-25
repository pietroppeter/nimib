import nimib / [types, blocks, docs]
export types, blocks, docs
# default setup:
import nimib / htmldefault
import os

template nbInit* =
  var
    nbDoc: NbDoc
    nbBlock: NbBlock

  template nbText(body: untyped) =
    nbTextBlock(nbBlock, nbDoc, body)

  template nbCode(body: untyped) =
    nbCodeBlock(nbBlock, nbDoc, body)
  
  template nbShow =
    write nbDoc
    open nbDoc

  nbDoc.renderer = renderHtml

  when false:  # not working
    nbDoc.sourceFilename = instantiationInfo().filename
    try:
      nbDoc.source = readFile(nbDoc.sourceFilename)
    except:
      echo "ERROR while reading source from: " & nbDoc.sourceFilename
  
  let params = commandLineParams()
  if params.len > 0:
    nbDoc.filename = changeFileExt(params[0], "html")
  else:
    nbDoc.filename = changeFileExt(nbDoc.sourceFilename, "html")



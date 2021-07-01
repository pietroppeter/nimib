import std/os
import browsers
import types

proc write*(doc: NbDoc) =
  let dir = doc.filename.splitFile().dir
  if not dir.dirExists:
    createDir(dir)
  writeFile(doc.filename, doc.render(doc))

proc open*(doc: NbDoc) =
  openDefaultBrowser(doc.filename)


import std/os
import browsers
import types
import nimib / renders

proc write*(nb: Nb) =
  echo "[nimib] current directory: ", getCurrentDir()
  let dir = nb.doc.filename.splitFile().dir
  if not dir.dirExists:
    echo "[nimib] creating directory: ", dir
    createDir(dir)
  echo "[nimib] saving file: ", nb.doc.filename
  writeFile(nb.doc.filename, nb.render(nb.doc))

proc open*(doc: NbDoc) =
  openDefaultBrowser(doc.filename)

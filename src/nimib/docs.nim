import std/os
import browsers
import types

proc write*(doc: NbDoc) =
  echo "[nimib] current directory: ", getCurrentDir()
  let dir = doc.filename.splitFile().dir
  if not dir.dirExists:
    echo "[nimib] creating directory: ", dir
    createDir(dir)
  echo "[nimib] saving file: ", doc.filename
  writeFile(doc.filename, doc.render(doc))

proc open*(doc: NbDoc) =
  openDefaultBrowser(doc.filename)

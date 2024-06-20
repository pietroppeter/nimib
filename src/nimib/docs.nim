import std/os
import browsers
import types, logging, renders

proc write*(doc: var NbDoc) =
  log "current directory: " & getCurrentDir()
  let dir = doc.filename.splitFile().dir
  if not dir.dirExists:
    log "creating directory: " & dir
    createDir(dir)
  log "saving file: " & doc.filename
  writeFile(doc.filename, render(doc))

proc open*(doc: NbDoc) =
  openDefaultBrowser(doc.filename)

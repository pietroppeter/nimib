import std/[os, json]
import std/uri
import browsers
import types, logging, renders

proc relToRoot*(doc: NbDoc, url: string): string =
  ## if url is relative, it is assumed as relative to root and adjusted for current document

  if isAbsolute(url) or isAbsolute(parseUri(url)):
    url
  else:
    doc.context{"path_to_root"}.getStr / url

proc write*(nb: Nb) =
  log "current directory: " & getCurrentDir()
  let dir = nb.doc.filename.splitFile().dir
  if not dir.dirExists:
    log "creating directory: " & dir
    createDir(dir)
  log "saving file: ", nb.doc.filename
  writeFile(nb.doc.filename, nb.render(nb.doc))

proc open*(doc: NbDoc) =
  openDefaultBrowser(doc.filename)

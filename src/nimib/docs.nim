import std/os
import browsers
import types
import nimib / renders

proc relToRoot*(doc: NbDoc, url: string): string =
  ## if url is relative, it is assumed as relative to root and adjusted for current document
  if isAbsolute(url) or url[0..3] == "http":
    url
  else:
    doc.context["path_to_root"].vString / url


proc write*(doc: var NbDoc) =
  echo "[nimib] current directory: ", getCurrentDir()
  let dir = doc.filename.splitFile().dir
  if not dir.dirExists:
    echo "[nimib] creating directory: ", dir
    createDir(dir)
  echo "[nimib] saving file: ", doc.filename
  writeFile(doc.filename, render(doc))

proc open*(doc: NbDoc) =
  openDefaultBrowser(doc.filename)

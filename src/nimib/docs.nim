import browsers
import types

proc write*(doc: NbDoc) =
  writeFile(doc.filename, doc.render(doc))

proc open*(doc: NbDoc) =
  openDefaultBrowser(doc.filename)


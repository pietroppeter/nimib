import browsers
import types

proc render*(doc: NbDoc): string =
  doc.renderer(doc)

proc write*(doc: NbDoc) =
  writeFile(doc.filename, doc.render)

proc open*(doc: NbDoc) =
  openDefaultBrowser(doc.filename)


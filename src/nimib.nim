import os
import nimib / [types, blocks, docs, renders, boost, config]
export types, blocks, docs, renders, boost
# types exports mustache, tables, paths

from nimib / themes import nil
export themes.useLatex, themes.darkMode, themes.`title=`

from mustachepkg/values import searchTable, searchDirs, castStr
export searchTable, searchDirs, castStr

template nbInit*(theme = themes.useDefault) =
  var nb {.inject.}: NbDoc

  # aliases to minimize breaking changes after refactoring nbDoc -> nb. Should be deprecated at some point?
  template nbDoc: NbDoc = nb
  template nbBlock: NbBlock = nb.blk
  template nbHomeDir: AbsoluteDir = nb.homeDir

  nb.initDir = getCurrentDir().AbsoluteDir

  nb.thisFile = instantiationInfo(-1, true).filename.AbsoluteFile
  nb.source = read(nb.thisFile)

  nb.render = renderHtml
  nb.filename = nb.thisFile.string.splitFile.name & ".html"

  loadCfg nb

  if nb.cfg.srcDir != "":
    echo "[nimib] srcDir: ", nb.srcDir
    nb.filename = (nb.thisDir.relativeTo nb.srcDir).string / nb.filename
    echo "[nimib] filename: ", nb.filename

  if nb.cfg.homeDir != "":
    echo "[nimib] setting current directory to nb.homeDir: ", nb.homeDir
    setCurrentDir nb.homeDir

  # how to change this to a better version using nb?
  proc relPath(path: AbsoluteFile | AbsoluteDir): string =
    (path.relativeTo nb.homeDir).string

  theme nb  # apply theme    

  template nbText(body: untyped) =
    nbTextBlock(nb.blk, nb, body)

  template nbCode(body: untyped) =
    nbCodeBlock(nb.blk, nb, body)

  template nbCodeInBlock(body: untyped) =
    block:
      nbCode:
        body

  template nbImage(url: string, caption = "") =
    if isAbsolute(url) or url[0..3] == "http":
      # Absolute URL or External URL
      nb.blk = NbBlock(kind: nbkImage, code: url)
    else:
      # Relative URL
      let relativeUrl = nb.context["home_path"].vString / url
      nb.blk = NbBlock(kind: nbkImage, code: relativeUrl)

    nb.blk.output = caption
    nb.blocks.add nb.blk

  template nbSave =
    # order if searchDirs/searchTable is relevant: directories have higher priority. rationale:
    #   - in memory partial contains default mustache assets
    #   - to override/customize (for a bunch of documents) the best way is to modify a version on file
    #   - in case you need to manage additional exceptions for a specific document add a new set of partials before calling nbSave
    nb.context.searchDirs(nb.templateDirs)
    nb.context.searchTable(nb.partials)

    write nb

  template nbShow =
    nbSave
    open nb

import os
import nimib / [types, blocks, docs, renders, boost]
export types, blocks, docs, renders, boost
# types exports mustache, tables, paths

from nimib / themes import nil
export themes.useLatex, themes.darkMode, themes.`title=`

from mustachepkg/values import searchTable, searchDirs, castStr
export searchTable, searchDirs, castStr

const nimibRootFindPattern {.strdefine.} = ""
const nimibHomeDir {.strdefine.} = ""
const nimibSrcDir {.strdefine.} = ""


template nbInit*(theme = themes.useDefault) =
  var nb {.inject.}: NbDoc

  # aliases to minimize breaking changes after refactoring nbDoc -> nb. Should be deprecated at some point?
  template nbDoc: NbDoc = nb
  template nbBlock: NbBlock = nb.blk
  template nbHomeDir: AbsoluteDir = nb.homeDir

  nb.thisFile = instantiationInfo(-1, true).filename.AbsoluteFile
  echo "[nimib] nb.thisFile: ", nb.thisFile
  nb.thisDir = nb.thisFile.splitFile.dir
  nb.initDir = getCurrentDir().AbsoluteDir
  nb.source = read(nb.thisFile)
  nb.render = renderHtml

  # todo: implement nimibRootFindPattern
  when defined(nimibRootFindPattern):
    nb.rootDir = findRootDir(startDir=nb.thisDir, pattern=nimibRootFindPattern)
    setCurrentDir nb.rootDir
  else:
    nb.rootDir = nb.initDir

  when defined(nimibHomeDir):
    nb.homeDir = nimibHomeDir.toAbsoluteDir # either absolute or relative to rootDir/initDir
    echo "[nimib] nb.homeDir: ", nb.homeDir
  else:
    nb.homeDir = nb.rootDir
  
  when defined(nimibSrcDir):
    nb.srcDir = nimibSrcDir.toAbsoluteDir # either absolute or relative to rootDir/initDir
    echo "[nimib] nb.srcDir: ", nb.srcDir
  else:
    nb.srcDir = nb.homeDir

  when defined(nimibHomeDir):
    echo "[nimib] setting current directory to nb.homeDir"
    setCurrentDir nb.homeDir

  when defined(nimibSrcDir):
    nb.filename = (nb.homeDir / nbThisFile.relativeTo nb.srcDir).string
  else:
    nb.filename = nb.thisfile.string
  nb.filename = changeFileExt(nb.filename, ".html")

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

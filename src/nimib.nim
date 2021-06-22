import os
import nimib / [types, blocks, docs, renders]
export types, blocks, docs, renders
# types exports mustache, tables, paths

from nimib/defaults import nil
export defaults.useLatex, defaults.darkMode

from mustachepkg/values import searchTable, searchDirs, castStr
export searchTable, searchDirs, castStr

const nimibRootFindPattern {.strdefine.} = ""
const nimibHomeDir {.strdefine.} = ""
const nimibSrcDir {.strdefine.} = ""


template nbInit*() =
  var nb {.inject.}: NbDoc
  nb.thisFile = instantiationInfo(-1, true).filename.AbsoluteFile
  nb.thisDir = nb.thisFile.splitFile.dir
  nb.initDir = getCurrentDir().AbsoluteDir
  nb.user = getUser()

  template nbDoc = nb
  template nbBlock = nb.blk

  when defined(nimibRootFindPattern):
    nb.rootDir = findRootDir(startDir=nb.thisDir, pattern=nimibRootFindPattern)
    setCurrentDir nb.rootDir
  else:
    nb.rootDir = nb.initDir

  when defined(nimibHomeDir):
    nb.homeDir = nimibHomeDir.toAbsoluteDir # either absolute or relative to rootDir/initDir
  else:
    nb.homeDir = nb.initDir
  
  when defined(nimibSrcDir):
    nb.srcDir = nimibSrcDir.toAbsoluteDir # either absolute or relative to rootDir/initDir
  else:
    nb.srcDir = nb.homeDir

  when defined(nimibHomeDir):
    setCurrentDir nb.homeDir

  nb.author = nb.user
  nb.filename = changeFileExt(nbThisFile.string, ".html")

  nb.render = renderHtml
  nb.templateDirs = @["./", "./templates/"]
  nb.partials = initTable[string, string]()
  nb.context = newContext(searchDirs = @[])
  nb.context["home_path"] = (nbHomeDir.relativeTo nbThisDir).string
  nb.context["here_path"] = (nbThisFile.relativeTo nbHomeDir).string
  nb.context["source"] = read(nbThisFile)

  defaults.init(nb)

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
    when defined(nimibSrcDir):
      if isAbsolute(nb.filename):
        nb.filename = (AbsoluteFile(nb.filename).relativeTo nimibSrcDirAbs).string
    withDir(nbHomeDir):
      write nb

  template nbShow =
    nbSave
    open nb

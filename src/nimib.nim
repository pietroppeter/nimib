import std/os
import nimib / [types, blocks, docs, renders, paths, boost]
export types, blocks, docs, renders, paths, boost
from nimib/defaults import nil
export defaults.useLatex, defaults.darkMode
# types exports mustache, tables
# paths exports pathutils
from mustachepkg/values import searchTable, searchDirs, castStr
export searchTable, searchDirs, castStr


template nbInit*() =
  # I think I want to migrate to a single global object nb
  # with nb.doc as nbDoc and nb.block (or nb.blk?) as nbBlock
  # the global object will also contain all those paths

  # all paths are absolute, use relPath to have path relative to Project directory
  let
    nbThisFile {.inject.} = instantiationInfo(-1, true).filename.AbsoluteFile
    thisTuple = nbThisFile.splitFile
    nbThisDir {.inject.}: AbsoluteDir = thisTuple.dir
    nbThisName {.inject, used.}: string = thisTuple.name
    nbThisExt {.inject, used.}: string = thisTuple.ext
    nbInitDir {.inject, used.} = getCurrentDir().AbsoluteDir # current directory at initialization
  var nbUser {.inject.}: string = getUser()

  const nimibOutDir {.strdefine, inject.} = "" # must inject otherwise it is always its default ""
  const nimibSrcDir {.strdefine, inject} = ""
  when defined(nimibSrcDir):
    let nimibSrcDirAbs = nimibSrcDir.toAbsoluteDir
  when defined(nimibOutDir):
    var nbHomeDir {.inject.}: AbsoluteDir = nimibOutDir.toAbsoluteDir
  else:
    var nbHomeDir {.inject.}: AbsoluteDir = findNimbleDir(nbThisDir)
    if dirExists(nbHomeDir / "docs".RelativeDir):
      nbHomeDir = nbHomeDir / "docs".RelativeDir
  setCurrentDir nbHomeDir

  # could change to nb.rel with nb global object
  proc relPath(path: AbsoluteFile | AbsoluteDir): string =
    (path.relativeTo nbHomeDir).string

  var
    nbDoc {.inject.}: NbDoc
    nbBlock {.inject.}: NbBlock

  nbDoc.author = nbUser  # never really used it yet, but probably could be a strdefine
  nbDoc.filename = changeFileExt(nbThisFile.string, ".html")

  nbDoc.render = renderHtml
  nbDoc.templateDirs = @["./", "./templates/"]
  nbDoc.partials = initTable[string, string]()
  nbDoc.context = newContext(searchDirs = @[])
  nbDoc.context["home_path"] = (nbHomeDir.relativeTo nbThisDir).string
  nbDoc.context["here_path"] = (nbThisFile.relativeTo nbHomeDir).string
  nbDoc.context["source"] = read(nbThisFile)

  defaults.init(nbDoc)

  when defined(nimibCustomPostInit):
    include nbPostInit

  template nbText(body: untyped) =
    nbTextBlock(nbBlock, nbDoc, body)

  template nbQuote(body: untyped) =
    nbTextQuote(nbBlock, nbDoc, body)

  template nbCode(body: untyped) =
    nbCodeBlock(nbBlock, nbDoc, body)

  template nbCodeInBlock(body: untyped) =
    block:
      nbCode:
        body

  template nbImage(url: string, caption = "") =
    if isAbsolute(url) or url[0..3] == "http":
      # Absolute URL or External URL
      nbBlock = NbBlock(kind: nbkImage, code: url)
    else:
      # Relative URL
      let relativeUrl = nbDoc.context["home_path"].vString / url
      nbBlock = NbBlock(kind: nbkImage, code: relativeUrl)

    nbBlock.output = caption
    nbDoc.blocks.add nbBlock

  template nbFile(name: string, body: string) =
    ## Generic string file
    block:
      let f = open(getCurrentDir() / name, fmWrite)
      f.write(body)
      f.close()
    nbText(name & ": ")
    nbTextQuote(body)

  template nbFile(name: string, body: untyped) =
    ## Nim code file
    block:
      let f = open(getCurrentDir() / name, fmWrite)
      f.write(body)
      f.close()
    nbText(name & ": ")
    nbCode(body)

  template nbSave =
    when defined(nimibCustomPreSave):
      include nbPreSave
    # order if searchDirs/searchTable is relevant: directories have higher priority. rationale:
    #   - in memory partial contain default mustache assets
    #   - to override/customize (for a bunch of documents) the best way is to modify a version on file
    #   - in case you need to manage additional exceptions for a specific document add a new set of partials before calling nbSave
    nbDoc.context.searchDirs(nbDoc.templateDirs)
    nbDoc.context.searchTable(nbDoc.partials)
    when defined(nimibSrcDir):
      if isAbsolute(nbDoc.filename):
        nbDoc.filename = (AbsoluteFile(nbDoc.filename).relativeTo nimibSrcDirAbs).string
    withDir(nbHomeDir):
      write nbDoc

  template nbShow =
    nbSave
    open nbDoc

import os
import nimib / [types, blocks, docs, renders, paths]
export types, blocks, docs, renders, paths
from nimib.defaults import nil
# types exports mustache, tables
# paths exports pathutils
from mustachepkg/values import searchTable, searchDirs
export searchTable, searchDirs


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
  var
    nbUser {.inject.}: string = getUser()
    nbProjDir {.inject.}: AbsoluteDir = findNimbleDir(nbThisDir)
  if dirExists(nbProjDir / "docs".RelativeDir):
    nbProjDir = nbProjDir / "docs".RelativeDir
  setCurrentDir nbProjDir

  proc relPath(path: AbsoluteFile | AbsoluteDir): string =
    (path.relativeTo nbProjDir).string
    
  var
    nbDoc {.inject.}: NbDoc
    nbBlock {.inject.}: NbBlock

  nbDoc.author = nbUser
  nbDoc.filename = changeFileExt(nbThisFile.string, ".html")

  nbDoc.render = renderHtml
  nbDoc.templateDirs = @["./", "./templates/"]
  nbDoc.partials = initTable[string, string]()
  nbDoc.context = newContext(searchDirs = @[])
  nbDoc.context["home_path"] = (nbProjDir.relativeTo nbThisDir).string
  nbDoc.context["here_path"] = (nbThisFile.relativeTo nbProjDir).string
  nbDoc.context["source"] = read(nbThisFile)

  defaults.init(nbDoc)

  template nbText(body: untyped) =
    nbTextBlock(nbBlock, nbDoc, body)

  template nbCode(body: untyped) =
    nbCodeBlock(nbBlock, nbDoc, body)
  
  template nbImage(url: string, caption = "") =
    # TODO: fix this workaround with refactoring of NbBlock
    nbBlock = NbBlock(kind: nbkImage, code: url)
    nbBlock.output = caption
    nbDoc.blocks.add nbBlock

  template nbSave =
    # order is relevant: directories have higher priority. rationale:
    #   - in memory partial contain default mustache assets
    #   - to override/customize (for a nuch of documents) the best way is to modify a version on file
    #   - in case you need to manage additional exceptions for a single document add a new set of partials before calling nbSave
    nbDoc.context.searchDirs(nbDoc.templateDirs)
    nbDoc.context.searchTable(nbDoc.partials)
    withDir(nbProjDir):
      write nbDoc

  template nbShow =
    nbSave
    open nbDoc

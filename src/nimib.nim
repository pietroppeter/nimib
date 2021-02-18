import nimib / [types, blocks, docs, renders, paths]
export types, blocks, docs, renders, paths
# types exports mustache, tables
# paths exports pathutils
import os
from mustachepkg/values import searchTable, searchDirs
export searchTable, searchDirs


# should I put used all around?
template nbInit*() =
  # if I make the template dirty I have to export all imports
  # the alternative is put inject in a lot of stuff

  # paths
  # all this stuff is absolute, relative directories will depend on the context (rel from projDir, thisDir, nbDoc.dir, ...)
  # Rel stuff is relative to what? curDir? thisDir? docDir? templateDirs?
  # or maybe it should be the other way around? Abs is not marked and Rel is stuff you compute on the go depending what you need.
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
    
  when defined(nbDebug):
    echo "nbThisFile: ", nbThisFile.string
    echo "nbInitDir : ", nbInitDir.string
    echo "nbUser    : ", nbUser
    echo "nbProjDir : ", nbProjDir

  var
    nbDoc {.inject.}: NbDoc
    nbBlock {.inject.}: NbBlock

  nbDoc.render = renderHtml
  nbDoc.context = newContext(searchDirs = @[])
  nbDoc.partials = initTable[string, string]()
  nbDoc.templateDirs = @["./", "./templates/"]
  # the rest could be actually be put directly in the context? (possibly keep the same API using dot setters and getters?)
  nbDoc.filename = changeFileExt(nbThisFile.string, ".html")
  # probably no for all those that I need to know the exact type. Filename for example I need to be a string
  # even so there could be workaround for this
  # for the moment anyway let's keep them here and declared in NbDoc type
  nbDoc.title = (nbThisFile.relativeTo nbProjDir).string
  nbDoc.author = nbUser

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
    # order is relevant: partials has higher priority
    nbDoc.context.searchTable(nbDoc.partials)
    nbDoc.context.searchDirs(nbDoc.templateDirs)
    withDir(nbProjDir):
      write nbDoc

  template nbUseLatex =
    nbDoc.context["use_latex"] = true

  template nbShow =
    nbSave
    open nbDoc

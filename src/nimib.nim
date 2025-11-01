import std/[os, strutils, sugar, strformat, macros, macrocache, sequtils, json]
import std / jsonutils except toJson
export jsonutils except toJson
import markdown
import nimib / [types, blocks, docs, boost, config, options, capture, jsons, globals, jsutils, nimibSugars, sources, highlight, logging, renders, builtinBlocks] 
export types, blocks, docs, boost, sugar, globals, nimibSugars, jsutils, sources, highlight, jsons, renders, builtinBlocks
# types exports mustache, tables, paths

from nimib / themes import nil
export themes.useLatex, themes.darkMode, themes.`title=`, themes.disableHighlightJs

from mustachepkg/values import searchTable, searchDirs, castStr
export searchTable, searchDirs, castStr

template nbInit*(theme: proc (nb: var Nb) = themes.useDefault, renderer: NbRender = nbToHtml, thisFileRel = "") =
  var nb {.inject.}: Nb
  nb.doc = NbDoc(kind: "NbDoc")
  nb.doc.initDir = getCurrentDir().AbsoluteDir
  loadOptions nb.doc
  loadCfg nb.doc

  # nbInit can be called not from inside the correct file (e.g. when rendering markdown files in nimibook)
  if thisFileRel == "":
    nb.doc.thisFile = instantiationInfo(-1, true).filename.AbsoluteFile
  else:
    nb.doc.thisFile = nb.doc.srcDir / thisFileRel.RelativeFile
    log "thisFile: " & $nb.doc.thisFile

  try:
    nb.doc.source = read(nb.doc.thisFile)
  except IOError:
    log "cannot read source"

  if nb.doc.options.filename == "":
    nb.doc.filename = nb.doc.thisFile.string.splitFile.name & ".html"
  else:
    nb.doc.filename = nb.doc.options.filename

  if nb.doc.cfg.srcDir != "":
    log "srcDir: " & $nb.doc.srcDir
    nb.doc.filename = (nb.doc.thisDir.relativeTo nb.doc.srcDir).string / nb.doc.filename
    log "filename: " & nb.doc.filename

  if nb.doc.cfg.homeDir != "":
    if not dirExists(nb.doc.homeDir):
      log "creating nb.homeDir: " & $nb.doc.homeDir
      createDir(nb.doc.homeDir)

    log "setting current directory to nb.doc.homeDir: " & $nb.doc.homeDir
    setCurrentDir nb.doc.homeDir

  # can be overriden by theme, but it is better to initialize this anyway
  #nb.templateDirs = @["./", "./templates/"]
  #nb.partials = initTable[string, string]()
  nb.doc.context = newJObject() #newContext(searchDirs = @[]) # templateDirs and partials added during nbSave

  # apply render backend (default backend can be overriden by theme)
  nb.backend = renderer

  # apply theme
  theme nb # how do we handle themes?

template nbInitMd*(thisFileRel = "") = 
  var tfr = if thisFileRel == "":
      instantiationInfo(-1).filename
    else:
      thisFileRel

  nbInit(renderer=nbToMd, theme=themes.noTheme, tfr)

  if nb.options.filename == "":
    nb.doc.filename = nb.doc.filename.splitFile.name & ".md"

#[ # block generation templates
template newNbCodeBlock*(cmd: string, body, blockImpl: untyped) =
  newNbBlock(cmd, true, nb, nb.blk, body, blockImpl)

template newNbSlimBlock*(cmd: string, blockImpl: untyped) =
  # a slim block is a block with no body
  newNbBlock(cmd, false, nb, nb.blk, "", blockImpl) ]#



template nbSave* =
  # order if searchDirs/searchTable is relevant: directories have higher priority. rationale:
  #   - in memory partial contains default mustache assets
  #   - to override/customize (for a bunch of documents) the best way is to modify a version on file
  #   - in case you need to manage additional exceptions for a specific document add a new set of partials before calling nbSave
  nb.nbCollectAllNbJs()

  #nb.context.searchDirs(nb.templateDirs)
  #nb.context.searchTable(nb.partials)

  write nb
  if nb.doc.options.show:
    open nb.doc

# how to change this to a better version using nb?
template relPath*(path: AbsoluteFile | AbsoluteDir): string =
  (path.relativeTo nb.doc.homeDir).string

# aliases to minimize breaking changes after refactoring nbDoc -> nb. Should be deprecated at some point?
#[ template nbDoc*: NbDoc = nb
template nbBlock*: NbBlock = nb.blk
template nbHomeDir*: AbsoluteDir = nb.homeDir ]#

# use --nbShow runtime option instead of this
template nbShow* =
  nbSave
  open nb

# the following does not affect user imports but only imports not exported in this module
{. warning[UnusedImport]:off .}

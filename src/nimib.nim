import std/[os, strutils, sugar, strformat, macros, macrocache, sequtils, json]
import std / jsonutils except toJson
export jsonutils except toJson
import markdown
import nimib / [types, blocks, docs, boost, config, options, capture, jsons, globals, jsutils, nimibSugars, sources, highlight, logging, renders, builtinBlocks] 
export types, blocks, docs, boost, sugar, globals, nimibSugars, jsutils, sources, highlight, jsons, renders, builtinBlocks

from nimib / themes import nil
export themes.useLatex, themes.darkMode, themes.`title=`, themes.disableHighlightJs

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

  nb.doc.context = newJObject()

  # apply render backend (default backend can be overriden by theme)
  nb.backend = renderer

  # apply theme
  theme nb

template nbInitMd*(thisFileRel = "") = 
  var tfr = if thisFileRel == "":
      instantiationInfo(-1).filename
    else:
      thisFileRel

  nbInit(renderer=nbToMd, theme=themes.noTheme, tfr)

  if nb.doc.options.filename == "":
    nb.doc.filename = nb.doc.filename.splitFile.name & ".md"

template nbSave* =
  nb.nbCollectAllNbJs()

  write nb
  if nb.doc.options.show:
    open nb.doc

# how to change this to a better version using nb?
template relPath*(path: AbsoluteFile | AbsoluteDir): string =
  (path.relativeTo nb.doc.homeDir).string

# use --nbShow runtime option instead of this
template nbShow* =
  nbSave
  open nb

# the following does not affect user imports but only imports not exported in this module
{. warning[UnusedImport]:off .}

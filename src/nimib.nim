import std/[os, strutils]
import nimib / [types, blocks, docs, boost, config, options, capture]
export types, blocks, docs, boost
# types exports mustache, tables, paths

from nimib / themes import nil
export themes.useLatex, themes.darkMode, themes.`title=`

from nimib / renders import nil

from mustachepkg/values import searchTable, searchDirs, castStr
export searchTable, searchDirs, castStr

template nbInit*(theme = themes.useDefault, backend = renders.useHtmlBackend, thisFileRel = "") =
  var nb {.inject.}: NbDoc

  nb.initDir = getCurrentDir().AbsoluteDir
  loadOptions nb
  loadCfg nb

  # nbInit can be called not from inside the correct file (e.g. when rendering markdown files in nimibook)
  if thisFileRel == "":
    nb.thisFile = instantiationInfo(-1, true).filename.AbsoluteFile
  else:
    nb.thisFile = nb.srcDir / thisFileRel.RelativeFile
    echo "[nimib] thisFile: ", nb.thisFile

  try:
    nb.source = read(nb.thisFile)
  except IOError:
    echo "[nimib] cannot read source"

  if nb.options.filename == "":
    nb.filename = nb.thisFile.string.splitFile.name & ".html"
  else:
    nb.filename = nb.options.filename

  if nb.cfg.srcDir != "":
    echo "[nimib] srcDir: ", nb.srcDir
    nb.filename = (nb.thisDir.relativeTo nb.srcDir).string / nb.filename
    echo "[nimib] filename: ", nb.filename

  if nb.cfg.homeDir != "":
    echo "[nimib] setting current directory to nb.homeDir: ", nb.homeDir
    setCurrentDir nb.homeDir

  # can be overriden by theme, but it is better to initialize this anyway
  nb.templateDirs = @["./", "./templates/"]
  nb.partials = initTable[string, string]()
  nb.context = newContext(searchDirs = @[]) # templateDirs and partials added during nbSave

  # apply render backend (default backend can be overriden by theme)
  backend nb

  # apply theme
  theme nb

template nbText*(body: untyped) =
  newNbBlock("nbText", nb, nb.blk, body):
    nb.blk.output = block:
      body

template nbCode*(body: untyped) =
  newNbBlock("nbCode", nb, nb.blk, body):
    captureStdout(nb.blk.output):
      body

template nbCodeInBlock*(body: untyped): untyped =
  block:
    nbCode:
      body

template nbImage*(url: string, caption = "") =
  if isAbsolute(url) or url[0..3] == "http":
    # Absolute URL or External URL
    nb.blk = NbBlock(kind: nbkImage, code: url)
  else:
    # Relative URL
    let relativeUrl = nb.context["path_to_root"].vString / url
    nb.blk = NbBlock(kind: nbkImage, code: relativeUrl)

  nb.blk.output = caption
  nb.blocks.add nb.blk

template nbFile*(name: string, body: string) =
  ## Generic string file
  block:
    let f = open(getCurrentDir() / name, fmWrite)
    f.write(body)
    f.close()

  var r = name.splitFile()
  r.ext.removePrefix('.')
  nbText("Writing file `" & name & "` :")
  let newbody = "```" & r.ext & "\n" & body & "```"
  nbText(newbody)

template nbFile*(name: string, body: untyped) =
  ## Nim code file
  block:
    let f = open(getCurrentDir() / name, fmWrite)
    f.write(body)
    f.close()
  nbText("Writing file `" & name & "` :")
  identBlock = newBlock(nbkCode, toStr(body))
  identContainer.blocks.add identBlock

template nbSave* =
  # order if searchDirs/searchTable is relevant: directories have higher priority. rationale:
  #   - in memory partial contains default mustache assets
  #   - to override/customize (for a bunch of documents) the best way is to modify a version on file
  #   - in case you need to manage additional exceptions for a specific document add a new set of partials before calling nbSave
  nb.context.searchDirs(nb.templateDirs)
  nb.context.searchTable(nb.partials)

  write nb
  if nb.options.show:
    open nb

# how to change this to a better version using nb?
template relPath*(path: AbsoluteFile | AbsoluteDir): string =
  (path.relativeTo nb.homeDir).string

# aliases to minimize breaking changes after refactoring nbDoc -> nb. Should be deprecated at some point?
template nbDoc*: NbDoc = nb
template nbBlock*: NbBlock = nb.blk
template nbHomeDir*: AbsoluteDir = nb.homeDir

template nbShow* =
  nbSave
  open nb

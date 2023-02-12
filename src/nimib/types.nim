import mustache, std / tables, nimib / paths, std / parseopt
export mustache, tables, paths
import std / [os]

type
  NbBlock* = ref object
    command*: string
    code*: string
    output*: string
    context*: Context
    blocks*: seq[NbBlock]
  NbOptions* = object
    skipCfg*: bool
    cfgName*, srcDir*, homeDir*, filename*: string
    show*: bool
    other*: seq[tuple[kind: CmdLineKind; name, value: string]]
  NbConfig* = object
    srcDir*, homeDir*: string
  NbRenderProc* = proc (doc: var NbDoc, blk: var NbBlock) {. nimcall .}
  NbDoc* = object
    thisFile*: AbsoluteFile
    filename*: string
    source*: string
    sourceFiles*: Table[string, string]
    initDir*: AbsoluteDir
    options*: NbOptions
    cfg*: NbConfig
    cfgDir*: AbsoluteDir
    rawCfg*: string
    blk*: NbBlock  ## current block being processed
    blocks*: seq[NbBlock]
    context*: Context
    partials*: Table[string, string]
    templateDirs*: seq[string]
    renderPlans*: Table[string, seq[string]]
    renderProcs*: Table[string, NbRenderProc]
    id: int
    nbJsCounter*: int
    currentStdout*, originalStdout*: FileHandle

proc thisDir*(doc: NbDoc): AbsoluteDir = doc.thisFile.splitFile.dir
proc srcDir*(doc: NbDoc): AbsoluteDir =
  if doc.cfg.srcDir.isAbsolute:
    doc.cfg.srcDir.AbsoluteDir
  else:
    doc.cfgDir / doc.cfg.srcDir.RelativeDir
proc homeDir*(doc: NbDoc): AbsoluteDir =
  if doc.cfg.homeDir.isAbsolute:
    doc.cfg.homeDir.AbsoluteDir
  else:
    doc.cfgDir / doc.cfg.homeDir.RelativeDir
proc thisFileRel*(doc: NbDoc): RelativeFile = doc.thisFile.relativeTo doc.srcDir
proc srcDirRel*(doc: NbDoc): RelativeDir = doc.srcDir.relativeTo doc.thisDir
proc newId*(doc: var NbDoc): int =
  ## Provides a unique integer each time it is called
  result = doc.id
  inc doc.id
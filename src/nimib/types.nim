import mustache, std / tables, nimib / paths, std / parseopt
export mustache, tables, paths
import std / os

type
  NbBlockKind* = enum
    nbkText = "nbText", nbkCode = "nbCode", nbkImage = "nbimage"
  NbBlock* = ref object
    command*: string
    kind*: NbBlockKind # refactor: to remove
    code*: string
    output*: string
    context*: Context
    #error*: string # have not used this one yet
  NbOptions* = object
    skipCfg*: bool
    cfgName*, srcDir*, homeDir*, filename*: string
    show*: bool
    other*: seq[tuple[kind: CmdLineKind; name, value: string]]
  NbConfig* = object
    srcDir*, homeDir*: string
  NbDoc* = object
    thisFile*: AbsoluteFile
    filename*: string
    source*: string
    initDir*: AbsoluteDir
    options*: NbOptions
    cfg*: NbConfig
    cfgDir*: AbsoluteDir
    rawCfg*: string
    blk*: NbBlock  ## current block being processed
    blocks*: seq[NbBlock]
    render*: proc (doc: NbDoc): string {.closure.}
    context*: Context
    partials*: Table[string, string]
    templateDirs*: seq[string]

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
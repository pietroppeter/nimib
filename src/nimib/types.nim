import mustache, std / tables, nimib / paths 
export mustache, tables, paths

type
  NbBlockKind* = enum
    nbkText = "nbText", nbkCode = "nbCode", nbkImage = "nbimage"
  NbBlock* = ref object
    kind*: NbBlockKind
    code*: string
    output*: string
    #error*: string # have not used this one yet
  NbConfig* = object
    srcDir*, homeDir*: string
  NbDoc* = object
    thisFile*: AbsoluteFile
    filename*: string
    source*: string
    initDir*: AbsoluteDir
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
proc srcDir*(doc: NbDoc): AbsoluteDir = doc.cfgDir / doc.cfg.srcDir.RelativeDir
proc homeDir*(doc: NbDoc): AbsoluteDir = doc.cfgDir / doc.cfg.homeDir.RelativeDir
proc thisFileRel*(doc: NbDoc): RelativeFile = doc.thisFile.relativeTo doc.srcDir
proc homeDirRel*(doc: NbDoc): RelativeDir = doc.homeDir.relativeTo doc.thisDir
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
  NbConfig = object
    raw*: string
    cfgDir*: AbsoluteDir
    srcDir*, homeDir*: string # or RelativeDir?
    filename*: string
  NbDoc* = object
    thisFile*: AbsoluteFile
    source*: string
    initDir*: AbsoluteDir
    cfg*: NbConfig 
    blk*: NbBlock  ## current block being processed
    blocks*: seq[NbBlock]
    render*: proc (doc: NbDoc): string {.closure.}
    context*: Context
    partials*: Table[string, string]
    templateDirs*: seq[string]

proc homeDir*(doc: NbDoc): AbsoluteDir = doc.cfg.homeDir
proc srcDir*(doc: NbDoc): AbsoluteDir = doc.cfg.srcDir
proc filename*(doc: NbDoc): string = doc.cfg.filename
proc `filename=`*(doc: NbDoc, filename: string) = doc.cfg.filename = filename

proc thisDir*(doc: NbDoc): AbsoluteDir = doc.thisFile.splitFile.dir

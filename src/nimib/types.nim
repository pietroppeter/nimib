import mustache, std / tables, nimib / paths, std / parseopt
export mustache, tables, paths
import std / [os, json]

type
  NbBlock* = ref object of RootObj
    kind*: string
  NbOptions* = object
    skipCfg*: bool
    cfgName*, srcDir*, homeDir*, filename*: string
    show*: bool
    other*: seq[tuple[kind: CmdLineKind; name, value: string]]
  NbConfig* = object
    srcDir*, homeDir*: string
  NbRenderFunc* = proc (blk: NbBlock, nb: Nb): string {. noSideEffect .}
  NbRender* = ref object of RootObj
    funcs*: Table[string, NbRenderFunc]
  NbContainer* = ref object of NbBlock
    blocks*: seq[NbBlock]
  NbDoc* = ref object of NbContainer
    thisFile*: AbsoluteFile
    filename*: string
    source*: string
    sourceFiles*: Table[string, string]
    initDir*: AbsoluteDir
    options*: NbOptions
    cfg*: NbConfig
    cfgDir*: AbsoluteDir
    rawCfg*: string
    context*: JsonNode
    id*: int
    nbJsCounter*: int
  Nb* = object
    # TODO: which fields should be moved from NbDoc to Nb?
    # As little as possible?
    # NbDoc should contain all info relevant to rendering the page and
    # Nb should just contain stuff needed for producing the NbDoc (like id and nbJsCounter)
    blk*: NbBlock # last block processed
    doc*: NbDoc # could be a NbBlock but we could give more guarantees with a NbDoc
    containers*: seq[NbContainer] # current container
    backend*: NbRender # current backend

proc `$`*(blk: NbBlock): string  = $blk[]

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

func render*(nb: Nb, blk: NbBlock): string =
  debugecho "REndering block: ", blk[]
  if blk.kind in nb.backend.funcs:
    nb.backend.funcs[blk.kind](blk, nb)
  else:
    ""
import mustache, tables
export mustache, tables

type
  NbBlockRenderProc* = proc (blk: var NbBlock, res: var string) {. nimcall .}
  NbDocRenderProc* = proc (blk: var NbDoc, res: var string) {. nimcall .}
  NbBlockBackend* = ref object
    partials*: Table[string, string]
    renderProc*: Table[string, NbBlockRenderProc]
  NbDocBackend* = ref object
    partials*: Table[string, string]
    renderProc*: Table[string, NbDocRenderProc]
    blockBackend*: NbBlockBackend
  NbBlockKind* = enum # remove this
    nbkText = "nbText", nbkCode = "nbCode", nbkImage = "nbimage"
  NbBlock* = ref object
    command*: string
    code*: string
    output*: string
    context*: Context
    renderPlan*: seq[string]
    #remove the following:
    kind*: NbBlockKind
    partials*: Table[string, string]
    renderProc*: Table[string, NbBlockRenderProc]
  NbDoc* = object
    filename*: string
    title*: string
    author*: string
    blocks*: seq[NbBlock]
    context*: Context
    renderPlan*: seq[string]
    # remove the following
    render*: proc (doc: NbDoc): string {.closure.}
    partials*: Table[string, string]
    templateDirs*: seq[string]
    renderProc*: Table[string, NbDocRenderProc]

  # next generalizarion would be to have a single NbUnit that can be of NbBlock type or NbContainer type.
  # Or maybe it is the Block type that can be of kind nbkSingle (nbkItem?) or kind nbkContainer
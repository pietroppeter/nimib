import mustache, tables
export mustache, tables

type
  NbBlockRenderProc* = proc (blk: NbBlock, res: var string) {. nimcall .}
  NbDocRenderProc* = proc (blk: NbDoc, res: var string) {. nimcall .}
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
    blocks*: seq[NbBlock]
    context*: Context
    partials*: Table[string, string]
    renderPlan*: seq[string]
    #remove the following:
    command*: string
    code*: string
    output*: string
    kind*: NbBlockKind
    renderProc*: Table[string, NbBlockRenderProc]
  NbDoc* = object # this will become a nbBlock
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

  # next generalization would be to have a single NbUnit that can be of NbBlock type or NbContainer type.
  # Or maybe it is the Block type that can be of kind nbkSingle (nbkItem?) or kind nbkContainer
  # or even better **all blocks can be containers** (they all have a seq[blocks] field);
  # **nbDoc is a specialization of nbBlock** with a specific render plan
  # also other fields like command, code, output, filename, title, ... should be moved inside the context object.
  # to keep the api some (all?) of those fields should have setters and getters (like this: https://forum.nim-lang.org/t/5359#33562)
  # in the end the generic nbBlock is jut context + partials + blocks + renderPlan (another name for this last one?)
  # (nbrProc as type name instead of NbBlockRenderProc? rplan instead of renderPlan?)
  # ah, I should also add a backend string field and all backends should be in a global (mutable) hastables of backends
  # (in fact nbDoc and nbBlock will be different also from this backend field; this makes sense to NOT put it in the context)

  #[
    type
      NbRenderProc* = proc (blk: NbBlock, res: var string) {. nimcall .}
      NbBackend = ref object
        partials*: Table[string, string]
        procs*: Table[string, NbRenderProc]
    var # globals in renders
      backends = Table[string, NbBackend]
      defaultPlans = Table[string, seq[string]]
  
  render of a block:
    - derive a new context for rendering from given context.
    - actually I think all block context should be derived from container context if there is a container. we also should track the container in the block!
  ]#
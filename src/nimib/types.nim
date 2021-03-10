import mustache, tables
export mustache, tables

type
  NbBlockRenderProc* = proc (b: var NbBlock, s: var string) {. closure .}
  NbDocRenderProc* = proc (b: var NbDoc, s: var string) {. closure .}
  NbBlockKind* = enum
    nbkText = "nbText", nbkCode = "nbCode", nbkImage = "nbimage"
  NbBlock* = ref object
    kind*: NbBlockKind
    code*: string
    output*: string
    context*: Context
    partials*: Table[string, string]
    renderProc*: Table[string, NbBlockRenderProc]
    renderPlan*: seq[string]
    #error*: string # have not used this one yet
  NbDoc* = object
    filename*, title*, author*: string
    blocks*: seq[NbBlock]
    render*: proc (doc: NbDoc): string {.closure.}
    context*: Context
    partials*: Table[string, string]
    templateDirs*: seq[string]
    renderProc*: Table[string, NbDocRenderProc]
    renderPlan*: seq[string]

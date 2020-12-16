import mustache

type
  NbBlockKind* = enum
    nbkText = "nbText", nbkCode = "nbCode"
  NbBlock* = ref object
    kind*: NbBlockKind
    body*: string
    output*: string
    error*: string
  NbDoc* = object
    filename*, title*, author*: string
    blocks*: seq[NbBlock]
    render*: proc (doc: NbDoc): string {.closure.}
    context*: Context

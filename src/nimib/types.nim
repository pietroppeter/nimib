import mustache, tables
export mustache, tables

type
  NbBlockKind* = enum
    nbkText = "nbText", nbkCode = "nbCode", nbkImage = "nbimage"
  NbBlock* = ref object
    kind*: NbBlockKind
    body*: string
    output*: string
    #error*: string # have not used this one yet
  NbDoc* = object
    filename*, title*, author*: string
    blocks*: seq[NbBlock]
    render*: proc (doc: NbDoc): string {.closure.}
    context*: Context
    partials*: Table[string, string]
    templateDirs*: seq[string]

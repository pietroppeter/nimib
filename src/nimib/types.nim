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
  NbDoc* = object
    thisFile*: AbsoluteFile
    thisDir*, initDir*, homeDir*, srcDir*, rootDir*: AbsoluteDir
    source*: string
    filename*: string
    blk*: NbBlock  ## current block being processed
    blocks*: seq[NbBlock]
    render*: proc (doc: NbDoc): string {.closure.}
    context*: Context
    partials*: Table[string, string]
    templateDirs*: seq[string]

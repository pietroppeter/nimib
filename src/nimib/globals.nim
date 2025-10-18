import ./types

var nbToJson*: Table[string, proc (s: string, i: var int): NbBlock]
var nbToHtml* = NbRender() # since we need it for json, let's make it also for html
var nbToMd* = NbRender()
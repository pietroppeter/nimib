import ./types

var nbToJson*: Table[string, proc (s: string, i: var int): NbBlock]
var nbToHtml* = NbRender()
var nbToMd* = NbRender()
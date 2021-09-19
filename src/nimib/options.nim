import types

proc loadOptions*(doc: var NbDoc) =
  doc.options.cfgName = "nimib.toml" # default
  discard

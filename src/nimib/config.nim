import types, os, toml_serialization

proc hasCfg*(doc: var NbDoc): bool = doc.cfgDir.string != ""

proc useDefaultCfg*(doc: var NbDoc) =
  doc.cfgDir = doc.initDir
  doc.cfg.srcDir = "."
  doc.cfg.homeDir = "."

proc optOverride*(doc: var NbDoc) =
  if doc.options.srcDir != "":
    doc.cfg.srcDir = doc.options.srcDir
  if doc.options.homeDir != "":
    doc.cfg.homeDir = doc.options.homeDir

proc loadCfg*(doc: var NbDoc) =
  let cfgName = doc.options.cfgName
  if not doc.options.skipCfg:
    for dir in parentDirs(getCurrentDir()):
      if fileExists(dir / cfgName):
        doc.cfgDir = dir.AbsoluteDir
        echo "[nimib] config file found: ", dir / cfgName
        break
  if doc.hasCfg:
    doc.rawCfg = readFile(doc.cfgDir.string / cfgName)
    doc.cfg = Toml.decode(doc.rawCfg, NbConfig, "nimib")
  else:
    echo "[nimib] using default config"
    doc.useDefaultCfg
  doc.optOverride


when isMainModule:
  import sugar
  var doc: NbDoc
  loadCfg doc
  dump doc.cfgDir
  dump doc.rawCfg
  dump doc.cfg
  dump doc.srcDir
  dump doc.homeDir
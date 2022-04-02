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

proc loadNimibCfg*(cfgName: string): tuple[found: bool, dir: AbsoluteDir, raw: string, nb: NbConfig] =
  for dir in parentDirs(getCurrentDir()):
    if fileExists(dir / cfgName):
      result.dir = dir.AbsoluteDir
      echo "[nimib] config file found: ", dir / cfgName
      result.found = true
      break
  if result.found:
    result.raw = readFile(result.dir.string / cfgName)
    result.nb = Toml.decode(result.raw, NbConfig, "nimib")

proc loadCfg*(doc: var NbDoc) =
  if not doc.options.skipCfg:
    let cfg = loadNimibCfg(doc.options.cfgName)
    doc.cfgDir = cfg.dir
    doc.rawCfg = cfg.raw
    doc.cfg = cfg.nb
  if not doc.hasCfg:
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
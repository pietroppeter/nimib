import types, os, toml_serialization

proc hasCfg*(doc: var NbDoc): bool = doc.cfgDir.string != ""

proc loadCfg*(doc: var NbDoc, cfgName = "nimib.toml") =
    # locate nimib.toml
    for dir in parentDirs(getCurrentDir()):
      if fileExists(dir / cfgName):
        doc.cfgDir = dir.AbsoluteDir
        echo "[nimib] config file found: ", dir / cfgName
        break
    if not doc.hasCfg:
      doc.cfgDir = doc.initDir
      return
    doc.rawCfg = readFile(doc.cfgDir.string / cfgName)
    doc.cfg = Toml.decode(doc.rawCfg, NbConfig, "nimib")

when isMainModule:
  import sugar
  var doc: NbDoc
  loadCfg doc
  dump doc.cfgDir
  dump doc.rawCfg
  dump doc.cfg
  dump doc.srcDir
  dump doc.homeDir
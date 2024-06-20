import types, logging, parsetoml, jsony, std / [json, os, osproc, math, sequtils]

proc getNimibVersion*(): string = 
  var dir = currentSourcePath().parentDir().parentDir()

  if dir.splitPath().tail == "src":
    dir = dir.parentDir()

  let dumpedJson = execProcess("nimble dump --silent --json", dir) 

  result = parseJson(dumpedJson)["version"].getStr()

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


proc customToJson*(table: parsetoml.TomlTableRef): JsonNode

proc customToJson*(value: parsetoml.TomlValueRef): JsonNode =
  case value.kind:
    of TomlValueKind.Int:
      %* value.intVal
    of TomlValueKind.Float:
      if classify(value.floatVal) == fcNan:
        if value.forcedSign != Pos:
          %* value.floatVal
        else:
          %* value.floatVal
      else:
        %* value.floatVal
    of TomlValueKind.Bool:
      %* $value.boolVal
    of TomlValueKind.Datetime:
      if value.dateTimeVal.shift == false:
        %* value.dateTimeVal
      else:
        %* value.dateTimeVal
    of TomlValueKind.Date:
      %* value.dateVal
    of TomlValueKind.Time:
      %* value.timeVal
    of TomlValueKind.String:
      %* value.stringVal
    of TomlValueKind.Array:
      if value.arrayVal.len == 0:
        when defined(newtestsuite):
          %[]
        else:
          %* []
      elif value.arrayVal[0].kind == TomlValueKind.Table:
        %value.arrayVal.map(customToJson)
      else:
        when defined(newtestsuite):
          %*value.arrayVal.map(customToJson)
        else:
          %* value.arrayVal.map(customToJson)
    of TomlValueKind.Table:
      value.tableVal.customToJson()
    of TomlValueKind.None:
      %*{"type": "ERROR"}

proc customToJson*(table: parsetoml.TomlTableRef): JsonNode =
  result = newJObject()
  for key, value in pairs(table):
    result[key] = value.customToJson


proc loadTomlSection*[T](content, section: string, _: typedesc[T]): T =
  let toml = parsetoml.parseString(content)
  result = T()
  if section in toml:
    result = ($toml[section].customToJson()).fromJson(T)

proc loadNimibCfg*(cfgName: string): tuple[found: bool, dir: AbsoluteDir, raw: string, nb: NbConfig] =
  for dir in parentDirs(getCurrentDir()):
    if fileExists(dir / cfgName):
      result.dir = dir.AbsoluteDir
      log "config file found: " & dir / cfgName
      result.found = true
      break
  if result.found:
    result.raw = readFile(result.dir.string / cfgName)
    result.nb = loadTomlSection(result.raw, "nimib", NbConfig)

proc loadCfg*(doc: var NbDoc) =
  if not doc.options.skipCfg:
    let cfg = loadNimibCfg(doc.options.cfgName)
    doc.cfgDir = cfg.dir
    doc.rawCfg = cfg.raw
    doc.cfg = cfg.nb
  if not doc.hasCfg:
    log "using default config"
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

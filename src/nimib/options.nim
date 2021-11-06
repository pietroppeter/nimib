import types
import std / [parseopt, strutils]

const nimibHelp = """
Nimib options:

  --nbHelp,     --nimibHelp                 print this help
  --nbSkipCfg,  --nimibSkipCfg              skip nimib config file
  --nbCfgName,  --nimibCfgName              change name of config file (default "nimib.toml")
  --nbSrcDir,   --nimibSrcDir               set srcDir as relative (to CfgDir) or absolute; overrides config 
  --nbHomeDir,  --nimibHomeDir              set homeDir as relative (to CfgDir) or absolute; overrides config 
  --nbFilename, --nimibFilename             overrides name of output file (e.g. somefile --nbFilename:othername.html)
  --nbShow,     --nimibShow                 open in browser at the end of nbSave
"""

proc loadOptions*(doc: var NbDoc) =
  doc.options.cfgName = "nimib.toml" # default
  var parsingNimibOptions = true
  for kind, key, val in getopt():
    if parsingNimibOptions:
      case key.normalize()
      of "nbhomedir", "nimibhomedir":
        assert kind == cmdLongOption
        doc.options.homeDir = val
      of "nbsrcdir", "nimibsrcdir":
        assert kind == cmdLongOption
        doc.options.srcDir = val
      of "nbcfgname", "nimibcfgname":
        assert kind == cmdLongOption
        doc.options.cfgName = val
      of "nbskipcfg", "nimibskipcfg":
        assert kind == cmdLongOption and val == ""
        doc.options.skipCfg = true
      of "nbfilename", "nimibfilename":
        assert kind == cmdLongOption
        doc.options.filename = val
      of "nbshow", "nimibshow":
        assert kind == cmdLongOption and val == ""
        doc.options.show = true
      of "nbhelp", "nimibhelp":
        assert kind == cmdLongOption and val == ""
        echo nimibHelp
        quit()
      else:
        parsingNimibOptions = false
        doc.options.other.add (kind, key, val)
    else:
      doc.options.other.add (kind, key, val)
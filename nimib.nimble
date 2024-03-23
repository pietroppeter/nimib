# Package

version       = "0.3.12"
author        = "Pietro Peterlongo & Hugo Granström"
description   = "nimib 🐳 - nim 👑 driven ⛵ publishing ✍"
license       = "MIT"
srcDir        = "src"

# Dependencies

requires "nim >= 1.4.0"
requires "fusion >= 1.2"
requires "markdown >= 0.8.1"
requires "mustache >= 0.2.1"
requires "parsetoml >= 0.7.0"
requires "jsony >= 1.1.5"

task docsdeps, "install dependendencies required for doc building":
  exec "nimble -y install ggplotnim@0.5.9 numericalnim@0.8.8 nimoji nimpy karax@1.2.2 happyx@2.0.0"

task test, "General tests":
  for file in ["tsources.nim", "tblocks.nim", "tnimib.nim", "trenders.nim"]:
    exec "nim r --hints:off tests/" & file
  for file in ["tblocks.nim", "tnimib.nim", "trenders.nim"]:
    exec "nim r --hints:off -d:nimibCodeFromAst tests/" & file

task readme, "update readme":
  exec "nim -d:mdOutput r docsrc/index.nim"  

task docs, "Build documentation":
  for file in ["allblocks", "hello", "mostaccio", "numerical", "nolan",
    "pythno", "cheatsheet", "files", "index",
    "interactivity", "counters", "caesar"]:
    exec "nim r --hints:off docsrc/" & file & ".nim"
  when not defined(nimibDocsSkipPenguins):
    exec "nim r --hints:off docsrc/penguins.nim"
  exec "nimble readme"  

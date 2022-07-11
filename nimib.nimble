# Package

version       = "0.3.0"
author        = "Pietro Peterlongo"
description   = "nimib 🐳 - nim 👑 driven ⛵ publishing ✍"
license       = "MIT"
srcDir        = "src"

# Dependencies

requires "nim >= 1.4.0"
requires "tempfile >= 0.1.6"
requires "markdown >= 0.8.1"
requires "mustache >= 0.2.1"
requires "toml_serialization >= 0.2.0"

task docsdeps, "install dependendencies required for doc building":
  exec "nimble -y install ggplotnim@0.4.9 numericalnim@0.6.1 nimoji nimpy karax@1.2.2"

task test, "General tests":
  exec "nim r tests/tsources.nim"
  exec "nim r tests/tblocks.nim"
  exec "nim r -d:nimibCodeFromAst tests/tblocks.nim"
  exec "nim r tests/tnimib.nim"
  exec "nim r -d:nimibCodeFromAst tests/tnimib.nim"
  exec "nim r tests/trenders.nim"
  exec "nim r -d:nimibCodeFromAst tests/trenders.nim"

task readme, "update readme":
  exec "nim -d:mdOutput r docsrc/index.nim"  

task docs, "Build documentation":
  exec "nim r docsrc/hello.nim"
  exec "nim r docsrc/mostaccio.nim"
  exec "nim r docsrc/numerical.nim"
  exec "nim r docsrc/nolan.nim"
  exec "nim r docsrc/pythno.nim"
  exec "nim r docsrc/cheatsheet.nim"
  exec "nim r docsrc/files.nim"
  exec "nim r docsrc/index.nim"
  exec "nim r docsrc/interactivity.nim"
  exec "nim r docsrc/counters.nim"
  exec "nim r docsrc/caesar.nim"
  when not defined(nimibDocsSkipPenguins):
    exec "nim r docsrc/penguins.nim"
  exec "nimble readme"  

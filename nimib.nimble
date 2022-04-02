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

task deps, "install dependendencies": # task created for CI, not sure how to avoid this
  exec """nimble -y install tempfile@">= 0.1.6" markdown@">= 0.8.1" mustache@">= 0.2.1" toml_serialization@">= 0.2.0""""

task tdeps, "install dependendencies required for testing":
  exec "nimble -y install ggplotnim@0.4.9 numericalnim@0.6.1 nimoji"

task test, "General tests":
  exec "nim r -d:nimibPreviewCodeAsInSource tests/tsources.nim"
  exec "nim r tests/tblocks.nim"
  exec "nim r -d:nimibPreviewCodeAsInSource tests/tblocks.nim"
  exec "nim r tests/tnimib.nim"
  exec "nim r -d:nimibPreviewCodeAsInSource tests/tnimib.nim"
  exec "nim r tests/trenders.nim"
  exec "nim r -d:nimibPreviewCodeAsInSource tests/trenders.nim"

task docs, "Build documentation":
  exec "nim r docs/hello.nim"
  exec "nim r docs/mostaccio.nim"
  exec "nim r docs/numerical.nim"
  exec "nim r docs/nolan.nim"
  exec "nim r docs/pythno.nim"
  exec "nim r docs/cheatsheet.nim"
  exec "nim r docs/files.nim"
  exec "nim r docs/index.nim"
  exec "nim -d:useMdBackend r docs/index.nim"  
  when not defined(nimibDocsSkipPenguins):
    exec "nim r docs/penguins.nim"

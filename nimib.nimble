# Package

version       = "0.2.4"
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

task ptest, "test with ptest":
  exec "nim r docs/ptest"

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

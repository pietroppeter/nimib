# Package

version       = "0.1"
author        = "Pietro Peterlongo"
description   = "nimib 🐳 - nim 👑 driven ⛵ publishing ✍"
license       = "MIT"
srcDir        = "src"

# Dependencies

requires "nim >= 1.4.0"
requires "tempfile >= 0.1.6"
requires "markdown >= 0.8.1"
requires "mustache >= 0.2.1"

task deps, "install dependendencies": # task created for CI, not sure how to avoid this
  exec """nimble -y install tempfile@">= 0.1.6" markdown@">= 0.8.1" mustache@">= 0.2.1""""

task tdeps, "install dependendencies required for testing":
  exec "nimble -y install ggplotnim@0.3.25 numericalnim@0.6.1"

task ptest, "test with ptest":
  exec "nim r docs/ptest"
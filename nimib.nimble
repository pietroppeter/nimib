# Package

version       = "0.1.0"
author        = "Pietro Peterlongo"
description   = "nimib 🐳 - nim 👑 driven 🚗 documents 📝"
license       = "MIT"
srcDir        = "src"



# Dependencies

requires "nim >= 1.0.0"
requires "tempfile >= 0.1.6"
requires "markdown >= 0.8.1"

task hello, "generate hello world example":
  exec "nim c examples\\hello\\world"
  "examples\\hello\\world.md".writeFile(staticExec("examples\\hello\\world docs\\hello_nimib.html"))
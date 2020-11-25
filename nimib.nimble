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

task hello, "generate hello nimib example":
  exec "nim c examples\\hello_nimib"
  "examples\\hello_nimib.md".writeFile(staticExec("examples\\hello_nimib docs\\hello_nimib.html"))

task readme, "generate readme and docs index":
  exec "nim c readme"
  "README.md".writeFile(staticExec("readme docs\\index.html"))
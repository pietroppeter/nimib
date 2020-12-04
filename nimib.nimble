# Package

version       = "0.0.4"
author        = "Pietro Peterlongo"
description   = "nimib 🐳 - nim 👑 driven ⛵ publishing ✍"
license       = "MIT"
srcDir        = "src"



# Dependencies

requires "nim >= 1.0.0"
requires "tempfile >= 0.1.6"
requires "markdown >= 0.8.1"
requires "mustache >= 0.2.1"

task readme, "generate readme and docs index":
  exec "nim c readme"
  "README.md".writeFile(staticExec("readme docs\\index.html"))

# template exampleTask(name: string) =

task hello, "generate hello nimib example":
  exec "nim c examples\\hello_nimib"
  "examples\\hello_nimib.md".writeFile(staticExec("examples\\hello_nimib docs\\hello_nimib.html"))

task nolan, "generate nolan example":
  exec "nim c examples\\nolan"
  "examples\\nolan.md".writeFile(staticExec("examples\\nolan docs\\nolan.html"))

task pythno, "generate pythno example":
  exec "nim c examples\\pythno"
  "examples\\pythno.md".writeFile(staticExec("examples\\pythno docs\\pythno.html"))

# placeholder for nimib
import os
for path in walkDirRec("."):
  let (dir, name, ext) = path.splitFile()
  if ext == ".nim" and name not_in ["nbPostInit"]:
    echo "building ", path
    selfExec("r " & path)
# placeholder for nimib
task genbook, "genbook":
import os
for path in walkDirRec("."):
  let (dir, name, ext) = path.splitFile()
    if ext == ".nim":
      echo "building ", path
      selfExec("r " & path)
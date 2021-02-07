import "$nim/compiler/pathutils"
export pathutils
import os, strutils, hashes

proc findNimbleDir*(dir: AbsoluteDir): AbsoluteDir =
  ## finds a directory containing a .nimble file starting from `dir` and looking in parent directories.
  ## if no .nimble file is found it will return `dir`.
  result = dir
  for d in parentDirs(dir.string):
    for f in walkFiles( d / "*.nimble"):
      # stops at first nimble files it finds
      return d.AbsoluteDir

proc getUser*: string =
  # from discord
  # https://github.com/tanpero/getUserName/blob/master/src/getUserName.cc
  # also see alternative python's getpass.getuser: https://docs.python.org/3/library/getpass.html
  getHomeDir().splitPath.head.splitPath.tail

proc setCurrentDir*(dir: AbsoluteDir) =
  dir.string.setCurrentDir

proc readFile*(file: AbsoluteFile | RelativeFile): string = readFile(file.string)

iterator walkDirRec*(dir: AbsoluteDir): AbsoluteFile {.tags: [ReadDirEffect].} =
  for file in walkDirRec(dir.string, relative=false):
    yield file.AbsoluteFile

func endsWith*(file: AbsoluteFile | RelativeFile, suffix: string): bool = # can I do {. borrow .}? probably, so
  (file.string).endsWith(suffix)

func startsWith*(file: AbsoluteFile | RelativeFile, suffix: string): bool = # can I do {. borrow .}? probably, so
  (file.string).startsWith(suffix)

func name*(file: AbsoluteFile): string =
  file.splitFile.name

func hash*(file: AnyPath): Hash = hash(file.string)

# ported from fusion/scripting 
template withDir*(dir: AbsoluteDir, body: untyped): untyped =
  let curDir = getCurrentDir()
  try:
    setCurrentDir(dir)
    body
  finally:
    setCurrentDir(curDir)
# git related utilities
import std / [os, osproc, strutils]
import nimib / paths

proc isGitAvailable*: bool =
  execCmdEx("git --version", options={poUsePath}).exitcode == 0

proc getGitRootDirectory*: AbsoluteDir =
  # https://stackoverflow.com/a/957978/4178189
  execProcess("git", args=["rev-parse", "--show-toplevel"], options={poUsePath}).strip.AbsoluteDir

proc getGitRemoteUrl*: string =
  # https://stackoverflow.com/a/4089452/4178189
  result = execProcess("git", args=["config", "--get", "remote.origin.url"], options={poUsePath}).strip
  # Convert ssh GitHub origins into https ones
  result = result.replace("git@github.com:", "https://github.com/")
  result = changeFileExt(result, "")

proc isOnGithub*: bool =
  getGitRemoteUrl().startsWith("https://github.com")

proc getGitRelativeUrl*(file: AbsoluteFile, branch="main"): string =
  result = "/blob/" & branch & "/" 
  result.add replace((file.relativeTo getGitRootDirectory()).string, "\\", "/")

proc getGitRemoteUrl*(file: AbsoluteFile, branch="main"): string =
  result = getGitRemoteUrl()
  result.add getGitRelativeUrl(file, branch)

# the following come from ptest and are even lower quality than the above
# they kinda work though...
proc isGitTracked*(file: AbsoluteFile): bool =
  # https://stackoverflow.com/questions/2405305/how-to-tell-if-a-file-is-git-tracked-by-shell-exit-code
  let (_, err) = execCmdEx("git ls-files --error-unmatch " & file.string)
  err == 0

proc gitChangedFiles* : seq[AbsoluteFile] =
  let
    (output, err) = execCmdEx("git status -s")
    dir = getCurrentDir()
  if err > 0: return
  for line in output.splitlines:
    if line.len < 4:
      continue
    result.add (dir / line[3..^1]).AbsoluteFile

proc isGitChanged*(file: AbsoluteFile): bool =
  for f in gitChangedFiles():
    if f == file: return true

when isMainModule:
  import sugar
  dump getGitRootDirectory()
  dump getGitRemoteUrl()
  assert getGitRemoteUrl() == "https://github.com/pietroppeter/nimib"

  import nimib
  nbInit
  dump nbThisFile.getGitRelativeUrl
  dump nbThisFile.getGitRemoteUrl
  assert nbThisFile.getGitRemoteUrl == "https://github.com/pietroppeter/nimib/blob/main/src/nimib/gits.nim"

  assert isGitAvailable()
  assert isOnGithub()
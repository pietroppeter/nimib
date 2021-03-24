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
  result = changeFileExt(result, "")

proc isOnGithub*: bool =
  getGitRemoteUrl().startsWith("https://github.com")

proc getGitRelativeUrl*(file: AbsoluteFile, branch="main"): string =
  result = "/blob/" & branch & "/" 
  result.add replace((file.relativeTo getGitRootDirectory()).string, "\\", "/")

proc getGitRemoteUrl*(file: AbsoluteFile, branch="main"): string =
  result = getGitRemoteUrl()
  result.add getGitRelativeUrl(file, branch)

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
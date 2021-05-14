import nimib
nbInit # this will also put me in docs folder

nbText: """# Print-testing for nimib

What is print-testing? Testing by comparing printed output of a file with a versioned reference (see [treeform/ptest](https://github.com/treeform/ptest)). 
"""
nbText: """## Test Results"""
var resultsBlock = nbBlock  # I will add to it at the end

nbText: """---
# Implementation

The following is an adaption of [treeform's ptest.nim](https://github.com/treeform/ptest/blob/master/src/ptest.nim)
taking into account specifics of nimib files: they already produce an output (html file).

Imports and global variables:
"""
nbCode:
  import os, osproc, strformat, strutils, nimib / paths, nimib / gits

  type
    SkipReason* = enum
      srNotSkipped, srNotTrackedInGit, srNoHtmlFound, srChangedInGit
    TestCase* = ref object  ## ref to make it easy to mutate while in a container
      file*: AbsoluteFile
      skip*: bool
      skipReason*: SkipReason
      fail*: bool

  func find*(s: seq[TestCase], file: AbsoluteFile, test: var TestCase): bool =
    for t in s:
      if t.file == file:
        test = t
        return true

  # this do not work anymore with the new code output escape. will need to fix
  func spanColor*(text, color: string): string = "<span style=\"color:" & color & "\">" & text & "</span>"
  func aLink*(text, link: string): string = "<a href=\"" & link & "\">" & text & "</a>"

  func stats*(tests: seq[TestCase]): tuple[skip, fail, pass: int] =
    for test in tests:
      if test.skip:
        inc result.skip
        continue
      elif test.fail:
        inc result.fail
      else:
        inc result.pass

  var
    test: TestCase
    tests: seq[TestCase]

when defined(nbDebug):
  nbText: "Current directory as results of calling nbInit:"
  nbCode: echo getCurrentDir()

nbText: """### test cases
for every file ending in nim (and not starting with ptest) in nbHomeDir (test cases)
- a test case will be skipped if it is not tracked in git
- a test case will be skipped if it does not have a corresponding html
- a test case will be skipped if it is modified/added in git
"""
nbCode:
  for file in walkDirRec(nbHomeDir):
    ## note that file is an AbsoluteFile (since nbHomeDir is an AbsoluteDir)
    let (dir, name, ext) = file.splitFile()
    if "book" in dir.string: # hacky fix to exclude book stuff 
      continue
    if file.endsWith(".nim") and not file.name.startsWith("ptest"):
      test = TestCase(file: file)
      stdout.write "added test candidate: ", file.relPath
    else:
      continue
    let html = changeFileExt(file, ".html")
    if not file.isGitTracked:
      test.skip = true
      test.skipReason = srNotTrackedInGit
      echo " -> skipped since it is not tracked in git"
    elif not html.fileExists or not html.isGitTracked:
      test.skip = true
      test.skipReason = srNoHtmlFound
      echo " -> skipped since it does not have a corresponding (git tracked) html file"
    elif file.isGitChanged:
      test.skip = true
      test.skipReason = srChangedInGit
      echo " -> skipped since it is changed in git"
    else:
      echo ""
    tests.add test

  # for file in gitChangedFiles():
  #   if tests.find(file, test) and not test.skip:
  #     test.skip = true
  #     test.skipReason = srChangedInGit
  #     echo " -> skipped since it is changed in git", file.relPath

nbText: """### performing test
for every non-skipped test case:
- if the corresponding html output is changed in git the test is failed
- copy the corresponding html to a tmp file
- find and execute the corresponding nim file
- if an error is found while compiling/executing, report a failure
- if a difference is reported between the corresponding html file and the temporary copy a failure is reported
- if no failure has been reported the test is reported as passed (and the temporary file is cleaned up)
"""
nbCode:
  for test in tests:
    var
      output: string
      err: int
    let
      html = test.file.changeFileExt(".html")
      tmp = test.file.changeFileExt(".tmp.html")
      fileWithLink = test.file.relPath.aLink html.relPath
    if test.skip:
      stdout.write "[SKIP]".spanColor "blue"
      echo " " & fileWithLink
      continue
    if html.isGitChanged:
      test.fail = true
      stdout.write "[FAIL]".spanColor "red"
      echo " " & fileWithLink
      echo "html file is changed in git. commit or revert and rerun test"
      continue
    copyFile(source=html, dest=tmp)
    (output, err) = execCmdEx &"nim --verbosity:0 --hints:off r {test.file}"
    if err != 0:
      test.fail = true
      stdout.write "[FAIL]".spanColor "red"
      echo " " & fileWithLink
      echo "Error during compile/run"
      echo "output\n:", output
      echo "err\n:", err
      continue
    (output, err) = execCmdEx(&"git diff --no-index {html} {tmp}")
    if err != 0:
      test.fail = true
      stdout.write "[FAIL]".spanColor "red"
      echo " " & fileWithLink
      echo "Differences found in html file"
      echo "output\n:", output
      echo "err\n:", err
      continue
    stdout.write "[OK]".spanColor "green"
    echo "   " & fileWithLink
    removeFile(tmp)
  
let details = nbBlock.output

nbText: "results are appended to previously save resultsBlock"
nbCode:
  let (skip, fail, pass) = tests.stats
  if fail > 0:
    resultsBlock.output.add " ❌" # slug for this? now emoji.muan is not helpful anymore...
  else:
    resultsBlock.output.add " ✅"
  let
    skipHeader = "skip".spanColor "blue"
    failHeader = "fail".spanColor "red"
    passHeader = "pass".spanColor "green"
  resultsBlock.output.add &"\n|{skipHeader}|{failHeader}|{passHeader}|total|"
  resultsBlock.output.add &"\n|---|---|---|---|"
  resultsBlock.output.add &"\n|{skip}|{fail}|{pass}|{skip + fail + pass}|"
  resultsBlock.output.add &"\n\n{details.renderHtmlCodeOutput}"

nbSave
quit(fail)
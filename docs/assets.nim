import nimib

nbInit
nbText: """# Assets"""
nbCode:
  import strformat, strutils
nbText: """
List of assets that should be available in order to be able to create
a working html document starting from a single nim file and nothing else:
"""
# note that ideally highlighting of nim could be done avoiding js and during rendering!
nbCode:
  let assetFiles: seq[(string, RelativeFile)] = @[
      ("highlightJs", "./static/highlight.nim.js".RelativeFile),
      ("highlightCss", "./static/atom-one-light.css".RelativeFile),
      ("doc", "./templates/doc.mustache".RelativeFile),
      ("head", "./templates/head.mustache".RelativeFile)
    ]
nbText: """
In order to have them available from the library I need to generate
the `nimib\assets.nim` module reading from this files.
"""
nbCode:
  let assetModuleFile = "../src/nimib/assets.nim".RelativeFile
  let
    tripleQuote = "\"\"\""
    tripleQuoteReplacement = tripleQuote & &" & \"\\\"\\\"\\\"\" & " & tripleQuote
  var assetModuleContent: string
  for (name, file) in assetFiles:
    let content = file.read.replace(tripleQuote, tripleQuoteReplacement)
    assetModuleContent.add fmt"""
let {name}* = {tripleQuote}
{content}{tripleQuote}
"""
  assetModuleFile.write assetModuleContent

# add test for asset.nim that checks content is same as original file
nbSave
#[
  changes:
    - [X] NbDoc type will have fields templateDirs and partials:
      they will be added to Context during nbSave.
      In this way partial can be changed and overwritten.
    - [ ] if highlight files are found as static they are used as static,
      otherwise their content is copied in the html.
    - [ ] templates instead are just copied in memory in the partials
      (no need to use them as static). They should be written to file
      only in case you need to customize them for multiple files
      (in that case remember to drop them from partial table).
]#
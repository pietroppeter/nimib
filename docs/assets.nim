import nimib

nbInit
nbText: """# Assets"""
nbCode:
  import strformat
nbText: """
List of assets that should be available in order to be able to create
a working html document starting from a single nim file and nothing else:
"""
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
  let tripleQuote = "\"\"\""
  var assetContent: string
  for (name, file) in assetFiles:
    assetContent.add fmt"""
let {name}* = {tripleQuote}
{file.read}
{tripleQuote}
"""
  assetModuleFile.write assetContent

nbSave
#[
  changes:
    - NbDoc type will have fields templateDirs and partials:
      they will be added to Context during nbSave.
      In this way partial can be changed and overwritten.
    - if highlight files are found as static they are used as static,
      otherwise their content is copied in the html.
    - templates instead are just copied in memory in the partials
      (no need to use them as static). They should be written to file
      only in case you need to customize them for multiple files.
]#
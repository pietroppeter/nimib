import types, strformat, strutils, markdown

proc render*(blk: NbBlock): string =
  case blk.kind
  of nbkText:
    result = markdown(blk.output.strip)
  of nbkCode:
    result = fmt"""<pre><code class="nim">{blk.body.strip}</code></pre>""" & "\n"
    if blk.output != "":
      result.add fmt"<pre><samp>{blk.output.strip}</samp></pre>" & "\n"

proc renderHtml*(doc: NbDoc): string =
  var body: string
  for blk in doc.data:
    body.add blk.render
  result = fmt"""<!DOCTYPE html>
<html>
<head>
  <meta content="text/html; charset=utf-8" http-equiv="content-type">
  <title>{doc.sourceFilename}</title>
  <meta content="width=device-width, initial-scale=1" name="viewport">
  <link rel='stylesheet' href='https://unpkg.com/normalize.css/' type='text/css'>
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/kognise/water.css@latest/dist/light.min.css">
</head>
<body>
{body.strip}
</body>
</html>
"""
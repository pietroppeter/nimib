import types, strformat, strutils, markdown, mustache

proc render*(blk: NbBlock): string =
  case blk.kind
  of nbkText:
    result = markdown(blk.output.strip)
  of nbkCode:
    result = fmt"""<pre><code class="nim">{blk.body.strip}</code></pre>""" & "\n"
    if blk.output != "":
      result.add fmt"<pre><samp>{blk.output.strip}</samp></pre>" & "\n"

proc renderHtml*(doc: NbDoc): string =
  var blocks: string
  for blk in doc.blocks:
    blocks.add blk.render
  let c = newContext(searchDirs=doc.searchDirs)
  c["blocks"] = blocks
  c["filename"] = doc.filename
  return "{{> doc}}".render(c)
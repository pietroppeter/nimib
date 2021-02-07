import types, strformat, strutils, markdown, mustache

let mdCfg = initGfmConfig()

proc renderMarkdown*(text: string): string =
  markdown(text, config=mdCfg)

proc renderHtmlTextOutput*(output: string): string =
  # why complain if func? because I am using mdCfg?
  renderMarkdown(output.strip)

func renderHtmlCodeBodyEscapeTag*(body: string): string =
  fmt"""<pre><code class="nim">{body.strip.escapeTag}</code></pre>""" & "\n"

func renderHtmlCodeBody*(body: string): string =
  fmt"""<pre><code class="nim">{body.strip}</code></pre>""" & "\n"

func renderHtmlCodeOutput*(output: string): string =
  fmt"<pre><samp>{output.strip}</samp></pre>" & "\n"

proc renderHtmlBlock*(blk: NbBlock): string =
  case blk.kind
  of nbkText:
    result = blk.output.renderHtmlTextOutput
  of nbkCode:
    result = blk.body.renderHtmlCodeBody
    if blk.output != "":
      result.add blk.output.renderHtmlCodeOutput

proc renderHtmlBlocks*(doc: NbDoc): string =
  for blk in doc.blocks:
    result.add blk.renderHtmlBlock

proc renderHtml*(doc: NbDoc): string =
  let blocks = doc.renderHtmlBlocks
  doc.context["blocks"] = blocks
  doc.context["title"] = doc.title
  # I need to put a protection here. doc MUST exist and this should fail if it does not!
  return "{{> doc}}".render(doc.context)

proc renderMarkBlock(blk: NbBlock) : string =
  case blk.kind:
    of nbkCode:
      # these two lines currently taken from blocks.nim; should be removed from there
      result.add "```nim" & blk.body & "\n```\n\n"
      if blk.output != "":
        result.add "```\n" & blk.output & "```\n\n"
    of nbkText:
      result = blk.output & "\n"

proc renderMarkBlocks(doc: NbDoc) : string =
  for blk in doc.blocks:
    result.add blk.renderMarkBlock & "\n"

proc renderMark*(doc: NbDoc): string =
  # I might want to add a frontmatter later
  return doc.renderMarkBlocks

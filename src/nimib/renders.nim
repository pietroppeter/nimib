import types, strformat, strutils, markdown, mustache, sugar
export escapeTag # where is this used? why do I export? a better solution is to use xmlEncode
import tables
import highlight
from std/cgi import xmlEncode

let mdCfg = initGfmConfig() # remove (cannot be made const)

proc mdOutputToHtml(doc: var NbDoc, blk: var NbBlock) =
  blk.context["outputToHtml"] = markdown(blk.output, config=initGfmConfig()).dup(removeSuffix)

proc highlightCode(doc: var NbDoc, blk: var NbBlock) =
  blk.context["codeHighlighted"] = highlightNim(blk.code)

proc useHtmlBackend*(doc: var NbDoc) =
  doc.partials["nbText"] = "{{&outputToHtml}}"
  doc.partials["nbCode"] = """
{{>nbCodeSource}}
{{>nbCodeOutput}}"""
  doc.partials["nbCodeSource"] = "<pre><code class=\"nim hljs\">{{&codeHighlighted}}</code></pre>"
  doc.partials["nbCodeOutput"] = "{{#output}}<pre><samp>{{output}}</samp></pre>{{/output}}"

  # I prefer to initialize here instead of in nimib (each backend should re-initialize)
  doc.renderPlans = initTable[string, seq[string]]()
  doc.renderPlans["nbText"] = @["mdOutputToHtml"]
  doc.renderPlans["nbCode"] = @["highlightCode"] # default partial automatically escapes output (code is escaped when highlighting)

  doc.renderProcs = initTable[string, NbRenderProc]()
  doc.renderProcs["mdOutputToHtml"] = mdOutputToHtml
  doc.renderProcs["highlightCode"] = highlightCode

proc render*(nb: var NbDoc, blk: var NbBlock): string =
  if blk.command not_in nb.partials:
    echo "[nimib.warning] no partial found for block ", blk.command
    return
  else:
    if blk.command in nb.renderPlans:
      for step in nb.renderPlans[blk.command]:
        if step in nb.renderProcs:
          nb.renderProcs[step](nb, blk)
    blk.context.searchTable(nb.partials)
    result = nb.partials[blk.command].render(blk.context)

proc render*(nb: var NbDoc): string =
  var blocks: seq[string]
  for blk in nb.blocks.mitems:
    blocks.add nb.render(blk)
  nb.context["blocks"] = blocks
  return "{{> document}}".render(nb.context)

# todo: starting from here it should all become obsolete and to be removed
proc renderMarkdown*(text: string): string =
  markdown(text, config=mdCfg)

proc renderHtmlTextOutput*(output: string): string =
  # why complain if func? because I am using mdCfg?
  renderMarkdown(output.strip)

func renderHtmlCodeBodyEscapeTag*(code: string): string =
  fmt"""<pre><code class="nim">{code.strip.xmlEncode}</code></pre>""" & "\n"

proc renderHtmlCodeBody*(code: string): string =
  let highlit = highlightNim(code)
  result = fmt"""<pre><code class="nim hljs">{highlit.strip}</code></pre>""" & "\n"

func renderHtmlCodeOutput*(output: string): string =
  fmt"<pre><samp>{output.xmlEncode}</samp></pre>" & "\n"

proc renderHtmlBlock*(blk: NbBlock): string =
  case blk.kind
  of nbkText:
    result = blk.output.renderHtmlTextOutput
  of nbkCode:
    result = blk.code.renderHtmlCodeBody
    if blk.output != "":
      result.add blk.output.renderHtmlCodeOutput
  of nbkImage:
    let
      image_url = blk.code
      caption = blk.output
    result = fmt"""
<figure>
<img src="{image_url}" alt="{caption}">
<figcaption>{caption}</figcaption>
</figure>
""" & "\n"

proc renderHtmlBlocks*(doc: NbDoc): string =
  for blk in doc.blocks:
    result.add blk.renderHtmlBlock

proc renderHtml*(doc: NbDoc): string =
  let blocks = doc.renderHtmlBlocks
  doc.context["blocks"] = blocks
  return "{{> document}}".render(doc.context)

proc renderMarkBlock(blk: NbBlock) : string =
  case blk.kind:
    of nbkCode:
      # these two lines currently taken from blocks.nim; should be removed from there
      result.add "```nim" & blk.code & "\n```\n\n"
      if blk.output != "":
        result.add "```\n" & blk.output & "```\n\n"
    of nbkText:
      result = blk.output & "\n"
    of nbkImage:
      let
        image_url = blk.code
        alt_text = blk.output
      result = "![" & alt_text & "](" & image_url & ")"

proc renderMarkBlocks(doc: NbDoc) : string =
  for blk in doc.blocks:
    result.add blk.renderMarkBlock & "\n"

proc renderMark*(doc: NbDoc): string =
  # I might want to add a frontmatter later
  return doc.renderMarkBlocks

#[
  Notes for planned refactoring on rendering:
    - RenderPlan complex object
    - table of single render procs (name -> closure)
    - list of names (e.g. code, output, block)
    - rendering is:
      + go through names in the list, apply closure and save result in context
      + last context name is final output of rendering
  Comments:
    - table allows customizing a single step of renderPlan
    - list allows easy skipping of plan, adding new steps to plan
  Example:

  Also to refactor nbImage, I think I should have a nbFree (or another name) block which:
    - executes code creating nbBlock object but does not capture stdout (same as nbCode but with no Capture)
    - also by default it should not be displayed
    - and rendering images should be something that updates context and renderPlan but nothing else
    - nbImage could be a template that ultimately reduces to a nbFree
  nbFile should be a block that writes to a file (from scratch the first time it appears, in append mode adding a newline later times),
  -> executing a file should be a separate command.
]#

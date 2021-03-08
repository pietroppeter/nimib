import types, strformat, strutils, markdown, mustache
export escapeTag
import tables
import highlight

let mdCfg = initGfmConfig()

proc renderMarkdown*(text: string): string =
  markdown(text, config=mdCfg)

proc renderHtmlTextOutput*(output: string): string =
  # why complain if func? because I am using mdCfg?
  renderMarkdown(output.strip)

func renderHtmlCodeBodyEscapeTag*(code: string): string =
  fmt"""<pre><code class="nim">{code.strip.escapeTag}</code></pre>""" & "\n"

proc renderHtmlCodeBody*(code: string): string =
  let highlit = highlightNim(code)
  result = fmt"""<pre><code class="nim hljs">{highlit.strip}</code></pre>""" & "\n"

func renderHtmlCodeOutput*(output: string): string =
  fmt"<pre><samp>{output.strip}</samp></pre>" & "\n"

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
  doc.context["title"] = doc.title
  # I need to put a protection here. doc MUST exist and this should fail if it does not!
  return "{{> doc}}".render(doc.context)

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
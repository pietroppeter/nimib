import types, strutils, markdown, mustache
export escapeTag
import tables
import highlight
from mustachepkg/values import searchTable
import std / with

# generic render functions
proc render*(blk: NbBlock, backend: NbBlockBackend): string =
  # if both partial and proc are present in backend, both are applied
  # (first the partial, then the proc)
  # if step not present in backend, nothing is done
  blk.context.searchTable(backend.partials)
  for step in blk.renderPlan:
    if step in backend.partials:
      let partial = "{{> " & step & " }}"
      result.add partial.render(blk.context)
    if step in backend.renderProc:
      backend.renderProc[step](blk, result)

proc render*(doc: NbDoc, backend: NbDocBackend): string =
  doc.context.searchTable(backend.partials)
  for step in doc.renderPlan:
    if step in backend.partials:
      result.add backend.partials[step].render(doc.context)
    if step in backend.renderProc:
      backend.renderProc[step](doc, result)

# default is html backend
var
  nbBlockBackend* = new NbBlockBackend
  nbDocBackend* = new NbDocBackend
  nbBlockBackendMd* = new NbBlockBackend
  nbDocBackendMd* = new NbDocBackend
  nbCodeBlockDefaultSteps* = @[
    "codeHighlighted",
    "outputEscaped",
    "addCode",
    "addOutput"
  ]
  nbTextBlockDefaultSteps* = @[
    "addOutputMdToHtml"
  ]

# procs needed for html block backend
proc renderMarkdown*(text: string): string =
  # I was not able to put mdToHtml in renderProc table
  # unless I put mdCfg inside here
  # (even changing type NbBlockRenderProc to closure)
  let mdCfg = initGfmConfig()
  markdown(text, config=mdCfg)

proc addOutputMdToHtml*(blk: NbBlock, res: var string) =
  res.add renderMarkdown(blk.output.strip)

proc codeHighlighted*(blk: NbBlock, res: var string) =
  blk.context["code"] = highlightNim(blk.code).strip

proc outputEscaped*(blk: NbBlock, res: var string) =
  blk.context["output"] = blk.output.escapeCode.strip

with nbBlockBackend:
  partials = {
      "addCode": """
{{#code}}<pre><code class="nim hljs">{{{code}}}</code></pre>{{/code}}
""",
      "addOutput": """
{{#output}}<pre><samp>{{{output}}}</samp></pre>{{/output}}
""",
      # should change to addImage with image.url and image.caption
      # also I will add an addImages (to show multiple images through a code block)
      "partialImageSingle": """
<figure>
<img src="{{url}}" alt="{{caption}}">
<figcaption>{{{caption}}}</figcaption>
</figure>
"""
  }.toTable
  renderProc = {
    "codeHighlighted": codeHighlighted,
    "outputEscaped": outputEscaped,
    "addOutputMdToHtml": addOutputMdToHtml
  }.toTable

# procs needed for html doc backend
proc renderHtmlBlocks*(doc: NbDoc): string =
  for blk in doc.blocks:
    result.add render(blk, nbBlockBackend)

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
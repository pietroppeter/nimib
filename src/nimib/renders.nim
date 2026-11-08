import std / [strutils, tables, sugar, os, strformat, sequtils, json]
import ./types, markdown, ./jsutils, ./nimibSugars, ./themes, ./globals, ./jsons, ./logging

import highlight
from std/jsonutils import nil

func nbDocToHtml*(blk: NbBlock, nb: Nb): string =
  let doc = blk.NbDoc
  let docJson = %[] # it's unused
  result = withNewlines:
    "<!DOCTYPE html>"
    """<html lang="en-us">"""
    nb.renderPartial("head", docJson)
    "<body>"
    nb.renderPartial("header", docJson)
    nb.renderPartial("left", docJson)
    mainToHtml(doc, nb)
    nb.renderPartial("right", docJson)
    nb.renderPartial("footer", docJson)
    "</body>"

addNbBlockToJson(NbDoc)
nbToHtml.funcs["NbDoc"] = nbDocToHtml

func preCodeTag*(lang: string, code: string, highlight: bool = true): string =
  let highlightString = if not highlight: "nohighlight" else: ""
  &"""<pre><code class="{highlightString} {lang} hljs">{code}</code></pre>"""

func nbCodeSourcePartial*(blk: JsonNode, nb: Nb): string =
  let code = blk{"code"}.getStr
  if code.len > 0:
    preCodeTag(lang="nim", code=code.highlightNim, highlight=false)
  else:
    ""

nbToHtml.partials["nbCodeSource"] = nbCodeSourcePartial

func nbCodeOutputPartial*(blk: JsonNode, nb: Nb): string =
  let output = blk{"output"}.getStr
  if output.len > 0:
    &"<pre class=\"nb-output\">{output}</pre>"
  else:
    ""

nbToHtml.partials["nbCodeOutput"] = nbCodeOutputPartial

func markdownToHtml*(markdownText: string): string =
  {.cast(noSideEffect).}: # not sure why markdown is marked with side effects
    markdown(markdownText, config=initGfmConfig())

func unescapeHtml(s: string): string =
  s.multiReplace(("&lt;", "<"), ("&gt;", ">"), ("&quot;", "\""), ("&#39;", "'"), ("&amp;", "&"))

func highlightNimFences*(html: string): string =
  ## Highlights the ```nim fences of rendered markdown when the page is built,
  ## like nbCode blocks, so they do not depend on highlight.js (or a CDN).
  const open = """<pre><code class="language-nim">"""
  const close = "</code></pre>"
  var i = 0
  while true:
    let a = html.find(open, i)
    if a < 0: break
    let b = html.find(close, a + open.len)
    if b < 0: break
    result.add html[i ..< a]
    var code = html[a + open.len ..< b].unescapeHtml
    code.removeSuffix('\n')
    result.add preCodeTag(lang="nim", code=code.highlightNim, highlight=false)
    i = b + close.len
  result.add html[i .. ^1]

func nbTextPartial*(blk: JsonNode, nb: Nb): string =
  let text = blk{"text"}.getStr
  markdownToHtml(text).highlightNimFences

nbToHtml.partials["nbText"] = nbTextPartial

func nbFilePartial(blk: JsonNode, nb: Nb): string =
  let filename = blk{"filename"}.getStr
  withNewlines:
      &"<pre>{filename}</pre>"
      preCodeTag(lang=blk{"ext"}.getStr, code=blk{"content"}.getStr)

nbToHtml.partials["nbFile"] = nbFilePartial


proc useHtmlBackend*(nb: var Nb) =
  nb.backend = nbToHtml

func nbDocToMd*(blk: NbBlock, nb: Nb): string =
  let doc = blk.NbDoc
  let docJson = %[] # it's unused
  result = withNewlines:
    nbContainerToMd(doc, nb)

nbToMd.funcs["NbDoc"] = nbDocToMd

proc useMdBackend*(nb: var Nb) =
  nb.backend = nbToMd

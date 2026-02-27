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

func nbCodeSourcePartial*(blk: JsonNode, nb: Nb): string =
  let code = blk{"code"}.getStr
  if code.len > 0:
    &"<pre><code class=\"nohighlight hljs nim\">{code.highlightNim}</code></pre>"
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

func nbTextPartial*(blk: JsonNode, nb: Nb): string =
  let text = blk{"text"}.getStr
  markdownToHtml(text)

nbToHtml.partials["nbText"] = nbTextPartial

func preCodeTag*(lang: string, code: string): string =
  &"""<pre><code class="{lang} hljs">{code}</code></pre>"""

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

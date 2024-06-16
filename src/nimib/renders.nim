import std / [strutils, tables, sugar, os, strformat, sequtils]
import ./types, ./jsutils, ./logging, markdown, mustache

import highlight
import mustachepkg/values

proc mdOutputToHtml(doc: var NbDoc, blk: var NbBlock) =
  blk.context["outputToHtml"] = markdown(blk.output, config=initGfmConfig()).dup(removeSuffix)

proc highlightCode(doc: var NbDoc, blk: var NbBlock) =
  blk.context["codeHighlighted"] = highlightNim(blk.code)


proc useHtmlBackend*(doc: var NbDoc) =
  doc.partials["nbText"] = "{{&outputToHtml}}"
  doc.partials["nbCode"] = """
{{>nbCodeSource}}
{{>nbCodeOutput}}"""
  doc.partials["nbCodeSkip"] = """{{>nbCodeSource}}"""
  doc.partials["nbCapture"] = """{{>nbCodeOutput}}"""
  doc.partials["nbCodeSource"] = "<pre><code class=\"nohighlight hljs nim\">{{&codeHighlighted}}</code></pre>"
  doc.partials["nbCodeOutput"] = """{{#output}}<pre class="nb-output">{{output}}</pre>{{/output}}"""
  doc.partials["nimibCode"] = doc.partials["nbCode"]
  doc.partials["nbImage"] = """<figure>
<img src="{{url}}" alt="{{alt_text}}">
<figcaption>{{caption}}</figcaption>
</figure>"""
  doc.partials["nbRawHtml"] = "{{&output}}"
  doc.partials["nbPython"] = """
<pre><code class="python hljs">{{&code}}</code></pre>
{{#output}}<pre><samp>{{&output}}</samp></pre>{{/output}}
"""
  doc.partials["nbFile"] = """
<pre>{{filename}}</pre>
<pre><code class="{{ext}} hljs">{{content}}</code></pre>
"""

  doc.partials["nbJsFromCode"] = "{{>nbJsScriptNimSource}}" # the script is handled by collector block
  doc.partials["nbJsFromCodeOwnFile"] = """
{{>nbJsScriptNimSource}}
{{>nbJsScript}}"""
  doc.partials["nbJsScriptNimSource"] = "{{#js_show_nim_source}}{{#js_show_nim_source_message}}<p>{{js_show_nim_source_message}}</p>{{/js_show_nim_source_message}}{{>nbCodeSource}}{{/js_show_nim_source}}"
  doc.partials["nbJsScript"] = "<script defer>{{&output}}</script>"

  # I prefer to initialize here instead of in nimib (each backend should re-initialize)
  doc.renderPlans = initTable[string, seq[string]]()
  doc.renderPlans["nbText"] = @["mdOutputToHtml"]
  doc.renderPlans["nbCode"] = @["highlightCode"] # default partial automatically escapes output (code is escaped when highlighting)
  doc.renderPlans["nbCodeSkip"] = @["highlightCode"]
  doc.renderPlans["nbJsFromCodeOwnFile"] = @["compileNimToJs", "highlightCode"]
  doc.renderPlans["nbJsFromCode"] = @["highlightCode"]
  doc.renderPlans["nimibCode"] = doc.renderPlans["nbCode"]

  doc.renderProcs = initTable[string, NbRenderProc]()
  doc.renderProcs["mdOutputToHtml"] = mdOutputToHtml
  doc.renderProcs["highlightCode"] = highlightCode
  doc.renderProcs["compileNimToJs"] = compileNimToJs

proc useMdBackend*(doc: var NbDoc) =
  doc.partials["document"] = """
{{#blocks}}

{{&.}}

{{/blocks}}"""
  doc.partials["nbText"] = "{{&output}}"
  doc.partials["nbCode"] = """
{{>nbCodeSource}}
{{>nbCodeOutput}}"""
  doc.partials["nbCodeSkip"] = """{{>nbCodeSource}}"""
  doc.partials["nbCapture"] = """{{>nbCodeOutput}}"""
  doc.partials["nbCodeSource"] = """

```nim
{{&code}}
```

"""
  doc.partials["nbCodeOutput"] = """{{#output}}

```
{{&output}}
```

{{/output}}
"""
  doc.partials["nimibCode"] = doc.partials["nbCode"]
  doc.partials["nbImage"] = """
![{{&alt_text}}]({{&url}})

{{#caption}}
**Figure:** {{&caption}}
{{/caption}}
"""
  doc.partials["nbPython"] = """
```python
{{&code}}
```
{{#output}}
```
{{&output}}
```
{{/output}}
"""

  # no need for special treatment
  doc.renderPlans = initTable[string, seq[string]]()
  doc.renderProcs = initTable[string, NbRenderProc]()

template debugRender(message: string) =
  when defined(nimibDebugRender):
    log "debugRender", message

proc render*(nb: var NbDoc, blk: var NbBlock): string =
  debugRender "rendering block " & blk.command
  if blk.command not_in nb.partials:
    warning "no partial found for block " & blk.command
    return
  else:
    if blk.command in nb.renderPlans:
      debugRender "renderPlan " & $nb.renderPlans[blk.command]
      for step in nb.renderPlans[blk.command]:
        if step in nb.renderProcs:
          nb.renderProcs[step](nb, blk)
    blk.context.searchTable(nb.partials)
    debugRender "partial " & nb.partials[blk.command]
    result = nb.partials[blk.command].render(blk.context)

proc render*(nb: var NbDoc): string =
  var blocks: seq[string]
  for blk in nb.blocks.mitems:
    blocks.add nb.render(blk)
  nb.context["blocks"] = blocks
  return "{{> document}}".render(nb.context)

import std / [strutils, tables, sugar, os, strformat, sequtils]
import types, markdown, mustache
export escapeTag # where is this used? why do I export? a better solution is to use xmlEncode
import highlight
import mustachepkg/values

proc mdOutputToHtml(doc: var NbDoc, blk: var NbBlock) =
  blk.context["outputToHtml"] = markdown(blk.output, config=initGfmConfig()).dup(removeSuffix)

proc highlightCode(doc: var NbDoc, blk: var NbBlock) =
  blk.context["codeHighlighted"] = highlightNim(blk.code)

proc compileNimToJs(doc: var NbDoc, blk: var NbBlock) =
  let tempdir = getTempDir() / "nimib"
  createDir(tempdir)
  let (dir, filename, ext) = doc.thisFile.splitFile()
  let nimfile = dir / (filename & "_nbCodeToJs_" & $doc.newId() & ext).RelativeFile
  let jsfile = tempdir / "out.js"
  writeFile(nimfile, blk.context["transformedCode"].vString)
  let kxiname = "nimib_kxi_" & $doc.newId()
  let errorCode = execShellCmd(&"nim js -d:danger -d:kxiname=\"{kxiname}\" -o:{jsfile} {nimfile}")
  if errorCode != 0:
    raise newException(OSError, "The compilation of a javascript file failed! Did you remember to capture all needed variables?\n" & $nimfile)
  removeFile(nimfile)
  let jscode = readFile(jsfile)
  removeFile(jsfile)
  blk.output = jscode
  blk.context["output"] = jscode

proc useHtmlBackend*(doc: var NbDoc) =
  doc.partials["nbText"] = "{{&outputToHtml}}"
  doc.partials["nbCode"] = """
{{>nbCodeSource}}
{{>nbCodeOutput}}"""
  doc.partials["nbCodeSource"] = "<pre><code class=\"nim hljs\">{{&codeHighlighted}}</code></pre>"
  doc.partials["nbCodeOutput"] = "{{#output}}<pre><samp>{{output}}</samp></pre>{{/output}}"
  doc.partials["nbImage"] = """<figure>
<img src="{{url}}" alt="{{caption}}">
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

  doc.partials["nbCodeToJs"] = """
{{>nbJsScriptNimSource}}
{{>nbJsScript}}"""
  doc.partials["nbJsScriptNimSource"] = "{{#js_show_nim_source}}{{#js_show_nim_source_message}}<p>{{js_show_nim_source_message}}</p>{{/js_show_nim_source_message}}{{>nbCodeSource}}{{/js_show_nim_source}}"
  doc.partials["nbJsScript"] = "<script defer>{{&output}}</script>"

  # I prefer to initialize here instead of in nimib (each backend should re-initialize)
  doc.renderPlans = initTable[string, seq[string]]()
  doc.renderPlans["nbText"] = @["mdOutputToHtml"]
  doc.renderPlans["nbCode"] = @["highlightCode"] # default partial automatically escapes output (code is escaped when highlighting)
  doc.renderPlans["nbCodeToJs"] = @["compileNimToJs", "highlightCode"]

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
  doc.partials["nbCodeSource"] = """

```nim
{{code}}
```

"""
  doc.partials["nbCodeOutput"] = """{{#output}}

```
{{output}}
```

{{/output}}
"""
  doc.partials["nbImage"] = """
![{{caption}}]({{url}})

**Figure:** {{caption}}
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
    echo "[nimib.debugRender] ", message

proc render*(nb: var NbDoc, blk: var NbBlock): string =
  debugRender "rendering block " & blk.command
  if blk.command not_in nb.partials:
    echo "[nimib.warning] no partial found for block ", blk.command
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

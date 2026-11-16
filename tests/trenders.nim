import nimib
import unittest, strutils

nbInit

suite "render (block), html default backend":
  test "nbText":
    nbText: "hi"
    check nb.render(nb.blk).strip == "<p>hi</p>"

  test "nbCode without output":
    nbCode: discard
    check nb.render(nb.blk).strip == """<pre><code class="nohighlight nim hljs"><span class="hljs-keyword">discard</span></code></pre>"""

  test "nbCode with output":
    nbCode: echo "hi"
    check nb.render(nb.blk).strip == """
<pre><code class="nohighlight nim hljs"><span class="hljs-keyword">echo</span> <span class="hljs-string">&quot;hi&quot;</span></code></pre>
<pre class="nb-output">hi
</pre>"""

  test "nbImage":
    nbImage("https://nim-lang.org/assets/img/logo_bw.png", "nim-lang.org favicon")
    check nb.render(nb.blk).strip == """
<figure>
  <img src="https://nim-lang.org/assets/img/logo_bw.png" alt="nim-lang.org favicon">
  <figcaption>nim-lang.org favicon</figcaption>
</figure>""".strip

  test "nbImage with width":
    nbImage("https://nim-lang.org/assets/img/logo_bw.png", "nim-lang.org favicon", width="200")
    check nb.render(nb.blk).strip == """
<figure>
  <img src="https://nim-lang.org/assets/img/logo_bw.png" alt="nim-lang.org favicon" width="200">
  <figcaption>nim-lang.org favicon</figcaption>
</figure>""".strip

  test "nbImage with width and height":
    nbImage("https://nim-lang.org/assets/img/logo_bw.png", "nim-lang.org favicon", width="200", height="100")
    check nb.render(nb.blk).strip == """
<figure>
  <img src="https://nim-lang.org/assets/img/logo_bw.png" alt="nim-lang.org favicon" width="200" height="100">
  <figcaption>nim-lang.org favicon</figcaption>
</figure>""".strip

  test "nbFile shows a file, escaped":
    nbFile("data/ops.txt")
    check nb.render(nb.blk).strip == """
<pre>data/ops.txt</pre>
<pre><code class=" txt hljs">a &lt; b &amp;&amp; c &gt; d
</code></pre>"""

  test "nbFile highlights Nim at build time":
    nbFile("data/greet.nim", start = "proc shout")
    check nb.render(nb.blk).strip == """
<pre>data/greet.nim</pre>
<pre><code class="nohighlight nim hljs"><span class="hljs-keyword">proc</span> shout*(s: <span class="hljs-built_in">string</span>): <span class="hljs-built_in">string</span> =
  s.toUpperAscii &amp; <span class="hljs-string">&quot;!&quot;</span>
</code></pre>"""

  test "nbFile folded, with a part of the file":
    nbFile("data/greet.nim", fold = true, start = "proc greet", stop = "proc shout")
    check nb.render(nb.blk).strip.splitLines[0] ==
      """<details class="nb-file"><summary><code>data/greet.nim</code> <span class="nb-small">3 lines</span></summary>"""
    check nb.render(nb.blk).strip.endsWith("</code></pre>\n</details>")

  test "nbFile folded under a title":
    nbFile("data/ops.txt", fold = true, title = "The `ops`")
    check nb.render(nb.blk).strip.splitLines[0] ==
      """<details class="nb-file"><summary>The <code>ops</code> <span class="nb-small">1 line</span></summary>"""

  test "nbFile: start not found":
    expect ValueError:
      nbFile("data/ops.txt", start = "nowhere")

# switch to markdown backend
useMdBackend nb

suite "render (block), markdown backend":
  test "nbText":
    nbText: "hi"
    check nb.render(nb.blk) == "hi"

  test "nbCode without output":
    nbCode: discard
    check nb.render(nb.blk).strip() == """
```nim
discard
```
""".strip()

  test "nbCode with output":
    nbCode: echo "hi"
    check nb.render(nb.blk).strip() == """

```nim
echo "hi"
```
```
hi
```
""".strip()

  test "nbImage with caption":
    nbImage("https://nim-lang.org/assets/img/logo_bw.png", "nim-lang.org favicon")
    check nb.render(nb.blk).strip == """
![nim-lang.org favicon](https://nim-lang.org/assets/img/logo_bw.png)
**Figure:** nim-lang.org favicon
""".strip

  test "nbImage without caption":
    nbImage("https://nim-lang.org/assets/img/logo_bw.png")
    check nb.render(nb.blk) == """
![](https://nim-lang.org/assets/img/logo_bw.png)"""

  test "nbImage with alt text":
    nbImage("https://nim-lang.org/assets/img/logo_bw.png", alt="nim-lang.org favicon")
    check nb.render(nb.blk).strip == """
![nim-lang.org favicon](https://nim-lang.org/assets/img/logo_bw.png)
""".strip

  test "nbImage with width and height (ignored in markdown)":
    nbImage("https://nim-lang.org/assets/img/logo_bw.png", "nim-lang.org favicon", width="200", height="100")
    check nb.render(nb.blk).strip == """
![nim-lang.org favicon](https://nim-lang.org/assets/img/logo_bw.png)
**Figure:** nim-lang.org favicon
""".strip

  test "nbFile":
    nbFile("data/ops.txt")
    check nb.render(nb.blk).strip == """
`data/ops.txt`

```txt
a < b && c > d
```""".strip

  test "nbFile folded":
    nbFile("data/greet.nim", fold = true, start = "proc shout")
    check nb.render(nb.blk).strip == """
<details><summary>`data/greet.nim` (2 lines)</summary>

```nim
proc shout*(s: string): string =
  s.toUpperAscii & "!"
```

</details>""".strip

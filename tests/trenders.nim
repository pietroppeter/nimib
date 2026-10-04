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

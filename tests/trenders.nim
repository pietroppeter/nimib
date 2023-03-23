import nimib
import nimib / renders
import unittest, strutils

nbInit

suite "render (block), html default backend":
  test "nbText":
    nbText: "hi"
    check nb.render(nb.blk).strip == "<p>hi</p>"

  test "nbCode without output":
    nbCode: discard
    check nb.render(nb.blk).strip == """<pre><code class="nohighlight hljs nim"><span class="hljs-keyword">discard</span></code></pre>"""

  test "nbCode with output":
    nbCode: echo "hi"
    check nb.render(nb.blk).strip == """
<pre><code class="nohighlight hljs nim"><span class="hljs-keyword">echo</span> <span class="hljs-string">&quot;hi&quot;</span></code></pre><pre class="nb-output">hi</pre>"""

# switch to markdown backend
useMdBackend nb

suite "render (block), markdown backend":
  test "nbText":
    nbText: "hi"
    check nb.render(nb.blk) == "hi"

  test "nbCode without output":
    nbCode: discard
    check nb.render(nb.blk) == """

```nim
discard
```

"""

  test "nbCode with output":
    nbCode: echo "hi"
    check nb.render(nb.blk) == """

```nim
echo "hi"
```


```
hi
```

"""

  test "nbImage with caption":
    nbImage("https://nim-lang.org/assets/img/logo_bw.png", "nim-lang.org favicon")
    check nb.render(nb.blk) == """
![nim-lang.org favicon](https://nim-lang.org/assets/img/logo_bw.png)

**Figure:** nim-lang.org favicon
"""

  test "nbImage without caption":
    nbImage("https://nim-lang.org/assets/img/logo_bw.png")
    check nb.render(nb.blk) == """
![](https://nim-lang.org/assets/img/logo_bw.png)

"""

  test "nbImage with alt text":
    nbImage("https://nim-lang.org/assets/img/logo_bw.png", alt="nim-lang.org favicon")
    check nb.render(nb.blk) == """
![nim-lang.org favicon](https://nim-lang.org/assets/img/logo_bw.png)

"""

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
    check nb.render(nb.blk).strip == """<pre><code class="nim hljs"><span class="hljs-keyword">discard</span></code></pre>"""

  test "nbCode with output":
    nbCode: echo "hi"
    check nb.render(nb.blk).strip == """
<pre><code class="nim hljs"><span class="hljs-keyword">echo</span> <span class="hljs-string">&quot;hi&quot;</span></code></pre><pre><samp>hi</samp></pre>"""

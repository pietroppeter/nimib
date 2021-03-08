## Markdown cheatsheet with nimib 
import nimib, nimoji, std/strutils

nbInit
#[
  This notebook shows how to:
    - create custom blocks (a nbTextWithSource)
    - add a Table of Contents
    - customize source highlighting
]#

# customize source highlighting:
nbDoc.partials["highlight"] = """
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/10.5.0/styles/default.min.css">
<script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/10.5.0/highlight.min.js"></script>
<script>hljs.initHighlightingOnLoad();</script>"""
nbDoc.context["no_default_highlight_css"] = true

# how to create a custom block:
func wrapMarkdown(code: string): string =
  "<pre><code class=\"language-markdown\">" & code & "</code></pre>" 

template nbTextWithSource(escapeHtml: bool, body: untyped) =
  nbText(body)
  let toWrap = if escapeHtml: nbBlock.output.replace("<", "&lt;") else: nbBlock.output
  nbBlock.output = wrapMarkdown(toWrap) & "\n\n" & nbBlock.output

# arguments with default do not work well in templates, overloading is a common trick
template nbTextWithSource(body: untyped) =
  nbTextWithSource(false, body)

# how to add a ToC
var
  nbToc: NbBlock

template addToc =
  nbTextBlock(nbToc, nbDoc, "# Table of Contents:\n\n")

template nbSection(name:string) =
  let anchorName = name.toLower.replace(" ", "-")
  nbText "<a name = \"" & anchorName & "\"></a>\n# " & name & "\n\n---"
  # see below, but any number works for a numbered list
  nbToc.output.add "1. <a href=\"#" & anchorName & "\">" & name & "</a>\n" 

nbText """
# Markdown Cheatsheet
Quick reference for markdown.
**Original source** (License [CC-BY](https://creativecommons.org/licenses/by/3.0/))
is from [markdown-here wiki](https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet).

Built in [nim](https://nim-lang.org/) :crown: with [nimib](https://github.com/pietroppeter/nimib) :whale:
and [a beautiful markdown parser in the nim world](https://github.com/soasme/nim-markdown).

Default styling for nimib is provided by [Water.css](https://github.com/kognise/water.css) :ocean:.

> I will use quoted sections to mention differences with **original source**
>
> This notebook also shows 3 customization techniques for nimib:
>   1. customization of code highlighting
>   2. custom NbBlock (a text block that shows Markdown source)
>   3. a table of contents
""".emojize

addToc()

nbSection "Headers"
nbTextWithSource: """
# H1
## H2
### H3
#### H4
##### H5
###### H6

Alternatively, for H1 and H2, an underline-ish style:

Alt-H1
======

Alt-H2
------
"""

nbSection "Emphasis"
nbTextWithSource """
Emphasis, aka italics, with *asterisks* or _underscores_.

Strong emphasis, aka bold, with **asterisks** or __underscores__.

Combined emphasis with **asterisks and _underscores_**.

Strikethrough uses two tildes. ~~Scratch this.~~
"""
#nbText "> Strikethrough is supported only in GFM mode:"
#nbCode:
#  echo markdown("~~Scratch this.~~", initGfmConfig())

nbSection "Lists"
nbText "(In this example, leading and trailing spaces are shown with with dots: ⋅)"
const dot = "⋅"
let source = """1. First ordered list item
2. Another item
⋅⋅⋅⋅* Unordered sub-list. 
1. Actual numbers don't matter, just that it's a number
⋅⋅⋅⋅1. Ordered sub-list
4. And another item.

⋅⋅⋅You can have properly indented paragraphs within list items. Notice the blank line above, and the leading spaces (at least one, but we'll use three here to also align the raw Markdown).

⋅⋅⋅To have a line break without a paragraph, you will need to use two trailing spaces.⋅⋅
⋅⋅⋅Note that this line is separate, but within the same paragraph.⋅⋅
⋅⋅⋅(This is contrary to the typical GFM line break behaviour, where trailing spaces are not required.)

* Unordered list can use asterisks
- Or minuses
+ Or pluses"""
nbText wrapMarkdown(source)
nbText source.replace(dot, " ")
nbText """
> in ordered to have the ordered sublist work correctly
> (it is not working on linked original) I increased indent from 2 to 4,
> see also [GFM spec](https://github.github.com/gfm/#why-is-a-spec-needed-)"""

nbSection "Links"
nbText "There are two ways to create links, inline and reference."  # specify which two
nbTextWithSource """
[I'm an inline-style link](https://www.google.com)

[I'm an inline-style link with title](https://www.google.com "Google's Homepage")

[I'm a reference-style link][Arbitrary case-insensitive reference text]

[I'm a relative reference to a repository file](../blob/master/LICENSE)

[You can use numbers for reference-style link definitions][1]

Or leave it empty and use the [link text itself].

URLs and URLs in angle brackets will automatically get turned into links. 
http://www.example.com or <http://www.example.com> and sometimes 
example.com (but not on Github, for example).

Some text to show that the reference links can follow later.

[arbitrary case-insensitive reference text]: https://www.mozilla.org
[1]: http://slashdot.org
[link text itself]: http://www.reddit.com
""" 
nbText "> only URL with angle brackets are turned into links here"

nbSection "Images"
nbTextWithSource """
Here's our logo (hover to see the title text):

Inline-style: 
![alt text](https://nim-lang.org/assets/img/logo.svg "Logo Title Text 1")

Reference-style: 
![alt text][logo]

[logo]: https://nim-lang.org/assets/img/logo.svg "Logo Title Text 2"
"""

nbSection "Code and Syntax Highlighting"
nbText """
Code blocks are part of the Markdown spec, but syntax highlighting isn't.
However, many renderers -- like Github's and Markdown Here -- support syntax highlighting.
Which languages are supported and how those language names should be written
will vary from renderer to renderer. Markdown Here supports highlighting
for dozens of languages (and not-really-languages, like diffs and HTTP headers);
to see the complete list, and how to write the language names,
see the [highlight.js demo page](http://softwaremaniacs.org/media/soft/highlight/test.html).
"""
nbTextWithSource "Inline `code` has `back-ticks around` it."
nbText """
Blocks of code are either fenced by lines with three back-ticks ```,
or are indented with four spaces.
I recommend only using the fenced code blocks -- they're easier
and only they support syntax highlighting."""
nbTextWithSource """
```javascript
var s = "JavaScript syntax highlighting";
alert(s);
```
 
```python
s = "Python syntax highlighting"
print s
```
 
```
No language indicated, so no syntax highlighting. 
But let's throw in a <b>tag</b>.
```
"""
nbText """> default syntax highlighting in nimib is for nim code only.
> The highlighting of Markdown, Javascript and Python was obtained through custom load of highlight.js library.
> note that last blocks of code is automatically detected by highlight.js to be YAML (!)
"""

nbSection "Tables"
nbText """
Tables aren't part of the core Markdown spec,
but they are part of GFM and Markdown Here supports them.
They are an easy way of adding tables to your email -- a task
that would otherwise require copy-pasting from another application."""
nbTextWithSource """
Colons can be used to align columns.

| Tables        | Are           | Cool  |
| ------------- |:-------------:| -----:|
| col 3 is      | right-aligned | $1600 |
| col 2 is      | centered      |   $12 |
| zebra stripes | are neat      |    $1 |

There must be at least 3 dashes separating each header cell.
The outer pipes (|) are optional, and you don't need to make the 
raw Markdown line up prettily. You can also use inline Markdown.

Markdown | Less | Pretty
--- | --- | ---
*Still* | `renders` | **nicely**
1 | 2 | 3
"""

nbSection "Blockquotes"
nbTextWithSource """> Blockquotes are very handy in email to emulate reply text.
> This line is part of the same quote.

Quote break.

> This is a very long line that will still be quoted properly when it wraps. Oh boy let's keep writing to make sure this is long enough to actually wrap for everyone. Oh, you can *put* **Markdown** into a blockquote. """

nbSection "Inline HTML"
nbText "You can also use raw HTML in your Markdown, and it'll mostly work pretty well."
nbTextWithSource(escapeHtml=true): """<dl>
  <dt>Definition list</dt>
  <dd>Is something people use sometimes.</dd>

  <dt>Markdown in HTML</dt>
  <dd>Does *not* work **very** well. Use HTML <em>tags</em>.</dd>
</dl>"""

nbSection "Horizontal Rule"
nbTextWithSource """Three or more...

---

Hyphens

***

Asterisks

___

Underscores"""

nbSection "Line Breaks"
nbText """
My basic recommendation for learning how line breaks work
is to experiment and discover -- hit <Enter> once
(i.e., insert one newline), then hit it twice (i.e., insert two newlines),
see what happens. You'll soon learn to get what you want.
"Markdown Toggle" is your friend.

Here are some things to try out:"""
nbTextWithSource """Here's a line for us to start with.

This line is separated from the one above by two newlines, so it will be a *separate paragraph*.

This line is also a separate paragraph, but...
This line is only separated by a single newline, so it's a separate line in the *same paragraph*."""
nbText "> note that last two lines do not have a line break in between as the original"

nbSection "YouTube Videos"
nbText "They can't be added directly but you can add an image with a link to the video like this:"
nbTextWithSource(escapeHtml=true): """<a href="http://www.youtube.com/watch?feature=player_embedded&v=YOUTUBE_VIDEO_ID_HERE
" target="_blank"><img src="http://img.youtube.com/vi/YOUTUBE_VIDEO_ID_HERE/0.jpg" 
alt="IMAGE ALT TEXT HERE" width="240" height="180" border="10" /></a>
""".replace("YOUTUBE_VIDEO_ID_HERE", "xqHdUjCXizI").replace("IMAGE ALT TEXT HERE", "Nim Conf 2020 Introduction")

# a simple way to add a footer (it would be probably better to add it as a partial through mustache)
nbText: "---\n<footer>" & renderMarkdown(
  "made with :heart: in [nim](https://nim-lang.org/) :crown: with [nimib](https://github.com/pietroppeter/nimib) :whale:".emojize) & "</footer>"

nbSave
#from mustachepkg/values import castStr
import std/[json, macros, sequtils, strutils, strformat]
import types, gits, highlight, config, jsons, globals, nimibSugars

# github light svg adapted from: https://iconify.design/icon-sets/octicon/mark-github.html
# github dark svg taken directly from github website
const githubLogoLight* = """<svg aria-hidden="true" width="1.2em" height="1.2em" style="vertical-align: middle;" preserveAspectRatio="xMidYMid meet" viewBox="0 0 16 16"><path fill-rule="evenodd" d="M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59c.4.07.55-.17.55-.38c0-.19-.01-.82-.01-1.49c-2.01.37-2.53-.49-2.69-.94c-.09-.23-.48-.94-.82-1.13c-.28-.15-.68-.52-.01-.53c.63-.01 1.08.58 1.23.82c.72 1.21 1.87.87 2.33.66c.07-.52.28-.87.51-1.07c-1.78-.2-3.64-.89-3.64-3.95c0-.87.31-1.59.82-2.15c-.08-.2-.36-1.02.08-2.12c0 0 .67-.21 2.2.82c.64-.18 1.32-.27 2-.27c.68 0 1.36.09 2 .27c1.53-1.04 2.2-.82 2.2-.82c.44 1.1.16 1.92.08 2.12c.51.56.82 1.27.82 2.15c0 3.07-1.87 3.75-3.65 3.95c.29.25.54.73.54 1.48c0 1.07-.01 1.93-.01 2.2c0 .21.15.46.55.38A8.013 8.013 0 0 0 16 8c0-4.42-3.58-8-8-8z" fill="#000"></path></svg>"""
const githubLogoDark* = """<svg aria-hidden="true" width="1.2em" height="1.2em" style="vertical-align: middle; fill: #fff" preserveAspectRatio="xMidYMid meet" viewBox="0 0 16 16"><path fill-rule="evenodd" d="M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63-.01 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.2.82.64-.18 1.32-.27 2-.27.68 0 1.36.09 2 .27 1.53-1.04 2.2-.82 2.2-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1.93-.01 2.2 0 .21.15.46.55.38A8.013 8.013 0 0016 8c0-4.42-3.58-8-8-8z"></path></svg>"""

func getTitle*(doc: NbDoc): string =
  doc.context{"title"}.getStr("nimib document")


# All of this should be moved to renders.nim?
func headToHtml*(blk: JsonNode, nb: Nb): string =
  result = withNewlines:
    fmt"""
<head>
  <title>{nb.doc.getTitle}</title>
  <meta content="text/html; charset=utf-8" http-equiv="content-type">
  <meta content="width=device-width, initial-scale=1" name="viewport">
  <meta content="nimib {nb.doc.context.getOrDefault("version").getStr}" name="generator">
  {nb.doc.context.getOrDefault("stylesheet").getStr}
  {nb.doc.context.getOrDefault("highlight").getStr}
  {nb.doc.context.getOrDefault("nb_style").getStr}
  {nb.doc.context.getOrDefault("latex").getStr}
    """
    if not nb.doc.context{"disableHighlightJs"}.getBool(false):
      nb.doc.context{"highlightJs"}.getStr
    "</head>"
    

func madeWithNimibToHtml*(): string =
  """<span class="nb-small">made with <a href="https://pietroppeter.github.io/nimib/">nimib 🐳</a></span>"""

func homeLinkToHtml*(homePath: string): string =
  fmt"""<a href="{homePath}">🏡</a>"""

func headerLeftToHtml*(blk: JsonNode, nb: Nb): string =
  homeLinkToHtml(nb.doc.context{"path_to_root"}.getStr("/"))

func headerCenterToHtml*(blk: JsonNode, nb: Nb): string =
  let title = nb.doc.getTitle()
  fmt"<code>{title}</code>"

func headerRightToHtml*(blk: JsonNode, nb: Nb): string =
  if not isNil(nb.doc.context{"github_remote_url"}):
    let githubRemoteUrl = nb.doc.context{"github_remote_url"}.getStr
    let githubLogo = nb.doc.context{"github_logo"}.getStr(githubLogoLight)
    result = fmt"""<a href="{github_remote_url}">{github_logo}</a>"""

func headerToHtml*(blk: JsonNode, nb: Nb): string =
  result = withNewlines:
    "<header>"
    """<div class="nb-box">"""
    " <span>" & nb.renderPartial("header_left", blk) & "</span>"
    " <span>" & nb.renderPartial("header_center", blk) & "</span>"
    " <span>" & nb.renderPartial("header_right", blk) & "</span>"
    "</div>"
    "<hr>"
    "</header>"

func leftToHtml*(blk: JsonNode, nb: Nb): string =
  ""

func mainToHtml*(blk: NbBlock, nb: Nb): string =
  result = withNewlines:
    "<main>"
    nbContainerToHtml(blk, nb)
    "</main>"

func rightToHtml*(blk: JsonNode, nb: Nb): string =
  ""

func footerLeftToHtml*(blk: JsonNode, nb: Nb): string =
  madeWithNimibToHtml()

func footerCenterToHtml*(blk: JsonNode, nb: Nb): string =
  ""

func showSourceButtonToHtml*(blk: JsonNode, nb: Nb): string =
  """<button class="nb-small" id="show" onclick="toggleSourceDisplay()">Show Source</button>"""

func footerRightToHtml*(blk: JsonNode, nb: Nb): string =
  showSourceButtonToHtml(blk, nb)

func sourceSectionToHtml*(blk: JsonNode, nb: Nb): string =
  fmt"""
<section id="source">
<pre><code class="nohighlight nim hljs">{nb.doc.context.getOrDefault("source_highlighted").getStr}</code></pre>
</section>
  """

func showSourceScriptToHtml*(blk: JsonNode, nb: Nb): string =
  """
<script>
  function toggleSourceDisplay() {
    var btn = document.getElementById("show")
    var source = document.getElementById("source");
    if (btn.innerHTML=="Show Source") {
      btn.innerHTML = "Hide Source";
      source.style.display = "block";
    } else {
      btn.innerHTML = "Show Source";
      source.style.display = "none";
    }
  }
</script>
  """

func footerToHtml*(blk: JsonNode, nb: Nb): string =
  result = withNewlines:
    "<footer>"
    """<div class="nb-box">"""
    " <span>" & nb.renderPartial("footer_left", blk) & "</span>"
    " <span>" & nb.renderPartial("footer_center", blk) & "</span>"
    " <span>" & nb.renderPartial("footer_right", blk) & "</span>"
    "</div>"
    "</footer>"
    nb.renderPartial("source_section", blk)
    nb.renderPartial("show_source_script", blk)


#[ # TODO: Make these old partials into procs with inputs so they can be reused!
const document* = """
<!DOCTYPE html>
<html lang="en-us">
{{> head }}
<body>
{{> header }}
{{> left }}
{{> main }}
{{> right }}
{{> footer }}
</body>
</html>"""

const head* = """
<head>
  <title>{{title}}{{^title}}nimib document{{/title}}</title>
  {{{favicon}}}
  <meta content="text/html; charset=utf-8" http-equiv="content-type">
  <meta content="width=device-width, initial-scale=1" name="viewport">
  <meta content="nimib {{version}}" name="generator">
  {{{stylesheet}}}
  {{{highlight}}}
  {{^disableHighlightJs}}
    {{{highlightJs}}}
  {{/disableHighlightJs}}
  {{{nb_style}}}
  {{{latex}}}
  {{> head_other }}
</head>
"""

const main* = """
<main>
{{#blocks}}
{{&.}}
{{/blocks}}
</main>
""" ]#

# https://css-tricks.com/emojis-as-favicons/ changed font-size to 80 to fit whale
const faviconWhale* = """<link rel="icon" href="data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 100 100%22><text y=%22.9em%22 font-size=%2280%22>🐳</text></svg>">"""
const waterLight* = """<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/water.css@2/out/light.min.css">"""
const waterDark* = """<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/water.css@2/out/dark.min.css">"""
const atomOneLight* = """<link rel='stylesheet' href='https://cdn.jsdelivr.net/gh/pietroppeter/nimib/assets/atom-one-light.css'>"""
const androidStudio* = """<link rel='stylesheet' href='https://cdn.jsdelivr.net/gh/pietroppeter/nimib/assets/androidstudio.css'>"""
const highlightJsTags* = """
<script src="https://cdn.jsdelivr.net/gh/pietroppeter/nimib@main/assets/highlight.min.js"></script>
<script>hljs.highlightAll();</script>
"""
const latex* = """<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.12.0/dist/katex.min.css" integrity="sha384-AfEj0r4/OFrOo5t7NnNe46zW/tFgW6x/bCJG8FqQCEo3+Aro6EYUG4+cU+KJWu/X" crossorigin="anonymous">
<script defer src="https://cdn.jsdelivr.net/npm/katex@0.12.0/dist/katex.min.js" integrity="sha384-g7c+Jr9ZivxKLnZTDUhnkOnsh30B4H0rpLUpJ4jAIKs4fnJI+sEnkvrMWph2EDg4" crossorigin="anonymous"></script>
<script defer src="https://cdn.jsdelivr.net/npm/katex@0.12.0/dist/contrib/auto-render.min.js" integrity="sha384-mll67QQFJfxn0IYznZYonOWZ644AWYC+Pt2cHqMaRhXVrursRwvLnLaebdGIlYNa" crossorigin="anonymous" onload="renderMathInElement(document.body,{delimiters:[{left: '$$', right: '$$', display: true},{left: '$', right: '$', display: false}]});"></script>"""
const nbStyle* = """<style>
.nb-box {
  display: flex;
  align-items: center;
  justify-content: space-between;
}
.nb-small {
  font-size: 0.8rem;
}
button.nb-small {
  float: right;
  padding: 2px;
  padding-right: 5px;
  padding-left: 5px;
}
section#source {
  display:none
}
pre > code {
  font-size: 1.2em;
}
.nb-output {
  line-height: 1.15;
}
figure {
  margin: 2rem 0;
}
figcaption {
  text-align: center;
}
  
</style>"""

#[ const header* = """
<header>
<div class="nb-box">
  <span>{{> header_left }}</span>
  <span>{{> header_center }}</span>
  <span>{{> header_right }}</span>
</div>
<hr>
</header>"""
const homeLink* = """<a href="{{path_to_root}}">🏡</a>"""
const githubLink* = """<a href="{{github_remote_url}}">{{{github_logo}}}</a>"""

const footer* = """
<footer>
<div class="nb-box">
  <span>{{> footer_left }}</span>
  <span>{{> footer_center }}</span>
  <span>{{> footer_right }}</span>
</div>
</footer>
{{> source_section }}
{{> show_source_script }}"""
const madeWithNimib* = """<span class="nb-small">made with <a href="https://pietroppeter.github.io/nimib/">nimib 🐳</a></span>"""
const showSourceButton* = """<button class="nb-small" id="show" onclick="toggleSourceDisplay()">Show Source</button>"""
const sourceSection* = """<section id="source">
<pre><code class="nohighlight nim hljs">{{{source_highlighted}}}</code></pre>
</section>"""
const showSourceScript* = """<script>
function toggleSourceDisplay() {
  var btn = document.getElementById("show")
  var source = document.getElementById("source");
  if (btn.innerHTML=="Show Source") {
    btn.innerHTML = "Hide Source";
    source.style.display = "block";
  } else {
    btn.innerHTML = "Show Source";
    source.style.display = "none";
  }
}
</script>"""

proc optOut*(content, keyword: string): string =
  "{{^" & keyword & "}}" & content & "{{/" & keyword & "}}" ]#

proc useDefault*(nb: var Nb) =
  nb.doc.context["path_to_root"] = %(nb.doc.srcDirRel).string
  nb.doc.context["path_to_here"] = %(nb.doc.thisFileRel).string
  nb.doc.context["source"] = %nb.doc.source

  #doc.partials["document"] = document
  #doc.partials["main"] = main
  nb.backend.partials["left"] = leftToHtml
  nb.backend.partials["right"] = rightToHtml
  # head
  nb.backend.partials["head"] = headToHtml
  nb.doc.context["version"] = %getNimibVersion()
  nb.doc.context["favicon"] = %faviconWhale
  nb.doc.context["stylesheet"] = %waterLight
  nb.doc.context["highlight"] = %atomOneLight
  nb.doc.context["highlightJs"] = %highlightJsTags
  nb.doc.context["nb_style"] = %nbStyle
  # header
  nb.backend.partials["header"] = headerToHtml
  nb.backend.partials["header_left"] = headerLeftToHtml
  nb.doc.context["title"] = nb.doc.context["path_to_here"]
  nb.backend.partials["header_center"] = headerCenterToHtml
  if isGitAvailable() and isOnGithub():
    nb.backend.partials["header_right"] = headerRightToHtml
    nb.doc.context["github_remote_url"] = %getGitRemoteUrl()
    nb.doc.context["github_logo"] = %githubLogoLight
  # footer
  nb.backend.partials["footer"] = footerToHtml
  nb.backend.partials["footer_left"] = footerLeftToHtml
  nb.backend.partials["footer_center"] = footerCenterToHtml
  nb.backend.partials["footer_right"] = footerRightToHtml
  nb.backend.partials["source_section"] = sourceSectionToHtml
  nb.backend.partials["show_source_script"] = showSourceScriptToHtml
  nb.doc.context["source_highlighted"] = %highlightNim(nb.doc.context["source"].getStr)

proc darkMode*(doc: var NbDoc) =
  doc.context["stylesheet"] = %waterDark
  doc.context["github_logo"] = %githubLogoDark
  doc.context["highlight"] = %androidStudio

proc darkMode*(nb: var Nb) =
  nb.doc.darkMode()

proc useLatex*(doc: var NbDoc) =
  doc.context["latex"] = %latex

proc useLatex*(nb: var Nb) =
  nb.doc.useLatex()

proc disableHighlightJs*(doc: var NbDoc) =
  doc.context["disableHighlightJs"] = %true

proc disableHighlightJs*(nb: var Nb) =
  nb.doc.disableHighlightJs()

proc `title=`*(doc: var NbDoc, text: string) =
  # to deprecate?
  doc.context["title"] = %text

proc `title=`*(nb: var Nb, text: string) =
  `title=`(nb.doc, text)

proc noTheme*(doc: var Nb) =
  discard

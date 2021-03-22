let doc* = """
<!DOCTYPE html>
<html lang="en-us">
{{> head }}
<body>
{{> header }}
{{> left }}
<main>
{{#blocks}}
{{{blocks}}}
{{/blocks}}
</main>
{{> right }}
{{> footer }}
</body>
</html>"""
let head* = """
<head>
  <title>{{title}}{{^title}}nimib document{{/title}}</title>
  {{! https://css-tricks.com/emojis-as-favicons/ changed font-size to 80 to fit whale }} 
  {{> favicon }}{{^no_default_favicon}}<link rel="icon" href="data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 100 100%22><text y=%22.9em%22 font-size=%2280%22>🐳</text></svg>">{{/no_default_favicon}}
  <meta content="text/html; charset=utf-8" http-equiv="content-type">
  <meta content="width=device-width, initial-scale=1" name="viewport">
  {{> style }}{{^no_default_style}}<link rel='stylesheet' href='https://unpkg.com/normalize.css/'>
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/kognise/water.css@latest/dist/light.min.css">
  {{/no_default_style}}
  {{> highlight }}{{^no_default_highlight_css}}<link rel='stylesheet' href='https://cdn.jsdelivr.net/gh/pietroppeter/nimib/assets/atom-one-light.css'>{{/no_default_highlight_css}}
  {{#use_latex}}<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.12.0/dist/katex.min.css" integrity="sha384-AfEj0r4/OFrOo5t7NnNe46zW/tFgW6x/bCJG8FqQCEo3+Aro6EYUG4+cU+KJWu/X" crossorigin="anonymous">
  <script defer src="https://cdn.jsdelivr.net/npm/katex@0.12.0/dist/katex.min.js" integrity="sha384-g7c+Jr9ZivxKLnZTDUhnkOnsh30B4H0rpLUpJ4jAIKs4fnJI+sEnkvrMWph2EDg4" crossorigin="anonymous"></script>
  <script defer src="https://cdn.jsdelivr.net/npm/katex@0.12.0/dist/contrib/auto-render.min.js" integrity="sha384-mll67QQFJfxn0IYznZYonOWZ644AWYC+Pt2cHqMaRhXVrursRwvLnLaebdGIlYNa" crossorigin="anonymous" onload="renderMathInElement(document.body,{delimiters:[{left: '$$', right: '$$', display: true},{left: '$', right: '$', display: false}]});"></script>
  {{/use_latex}}
  {{> head_other }}
  {{! I am not sure how to avoid the following </head> tag not to be indented }}
</head>
"""
let footer* = """
<footer>
<hr>
<span id="made">made with <a href="https://github.com/pietroppeter/nimib">nimib 🐳</a></span>
{{^no_source}}<button id="show" onclick="toggleSourceDisplay()">Show Source</button>
<section id="source">
<pre><code class="nim hljs">{{{source}}}</code></pre>
</section>
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
{{/no_source}}
<style>
span#made {
  font-size: 0.8rem;
}
{{^no_source}}button#show {
  font-size: 0.8rem;
}

button#show {
  float: right;
  padding: 2px;
  padding-right: 5px;
  padding-left: 5px;
}
section#source {
  display:none
}
{{/no_source}}
</style>
</footer>
"""

# github svg taken from adapted from: https://iconify.design/icon-sets/octicon/mark-github.html
let header* = """
<header>
<div id="header-box">
<span id="home"><a href="{{home-path}}">🏡</a></span>
<span id="header-title">{{{header-title}}}</span>
<span id="github">{{#github-remote-url}}<a href="{{github-remote-url}}"><svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" aria-hidden="true" focusable="false" width="1.2em" height="1.2em" style="vertical-align: middle;" preserveAspectRatio="xMidYMid meet" viewBox="0 0 16 16"><path fill-rule="evenodd" d="M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59c.4.07.55-.17.55-.38c0-.19-.01-.82-.01-1.49c-2.01.37-2.53-.49-2.69-.94c-.09-.23-.48-.94-.82-1.13c-.28-.15-.68-.52-.01-.53c.63-.01 1.08.58 1.23.82c.72 1.21 1.87.87 2.33.66c.07-.52.28-.87.51-1.07c-1.78-.2-3.64-.89-3.64-3.95c0-.87.31-1.59.82-2.15c-.08-.2-.36-1.02.08-2.12c0 0 .67-.21 2.2.82c.64-.18 1.32-.27 2-.27c.68 0 1.36.09 2 .27c1.53-1.04 2.2-.82 2.2-.82c.44 1.1.16 1.92.08 2.12c.51.56.82 1.27.82 2.15c0 3.07-1.87 3.75-3.65 3.95c.29.25.54.73.54 1.48c0 1.07-.01 1.93-.01 2.2c0 .21.15.46.55.38A8.013 8.013 0 0 0 16 8c0-4.42-3.58-8-8-8z" fill="#000"></path></svg></a>{{/github-remote-url}}</span>
</div>
<style>
div#header-box {
  display: flex;
  align-items: center;
  justify-content: space-between;
}
</style>
<hr>
</header>
"""
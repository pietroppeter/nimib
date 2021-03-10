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

<!DOCTYPE html>
<html lang="en-us">
<head>
  <title>Nimib Docs</title>
  <link rel="icon" href="data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 100 100%22><text y=%22.9em%22 font-size=%2280%22>🐳</text></svg>">
  <meta content="text/html; charset=utf-8" http-equiv="content-type">
  <meta content="width=device-width, initial-scale=1" name="viewport">
  <link rel='stylesheet' href='https://unpkg.com/normalize.css/'>
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/kognise/water.css@latest/dist/light.min.css">
  <link rel='stylesheet' href='https://cdn.jsdelivr.net/gh/pietroppeter/nimib/assets/atom-one-light.css'>
  <style>
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
</style>
  
  <script async defer data-domain="pietroppeter.github.io/nimib" src="https://plausible.io/js/plausible.js"></script>
</head>
<body>
<header>
<div class="nb-box">
  <span><a href=".">🏡</a></span>
  <span><code>index.nim</code></span>
  <span><a href="https://github.com/pietroppeter/nimib"><svg aria-hidden="true" width="1.2em" height="1.2em" style="vertical-align: middle;" preserveAspectRatio="xMidYMid meet" viewBox="0 0 16 16"><path fill-rule="evenodd" d="M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59c.4.07.55-.17.55-.38c0-.19-.01-.82-.01-1.49c-2.01.37-2.53-.49-2.69-.94c-.09-.23-.48-.94-.82-1.13c-.28-.15-.68-.52-.01-.53c.63-.01 1.08.58 1.23.82c.72 1.21 1.87.87 2.33.66c.07-.52.28-.87.51-1.07c-1.78-.2-3.64-.89-3.64-3.95c0-.87.31-1.59.82-2.15c-.08-.2-.36-1.02.08-2.12c0 0 .67-.21 2.2.82c.64-.18 1.32-.27 2-.27c.68 0 1.36.09 2 .27c1.53-1.04 2.2-.82 2.2-.82c.44 1.1.16 1.92.08 2.12c.51.56.82 1.27.82 2.15c0 3.07-1.87 3.75-3.65 3.95c.29.25.54.73.54 1.48c0 1.07-.01 1.93-.01 2.2c0 .21.15.46.55.38A8.013 8.013 0 0 0 16 8c0-4.42-3.58-8-8-8z" fill="#000"></path></svg></a></span>
</div>
<hr>
</header><main>
# nimib 🐳 - nim 👑 driven ⛵ publishing ✍

Nimib provides an API to convert your Nim code and its outputs to html documents.

The type of html output that is obtained by default is similar to html notebooks produced by tools
like [Jupyter](https://nbviewer.jupyter.org/url/norvig.com/ipython/Advent%20of%20Code.ipynb)
or [RMarkdown](https://rmarkdown.rstudio.com/lesson-10.html), but nimib provides this starting
directly from standard nim files. It currently does not provide any type of interactivity or automatic reloading.

If you have some nim code lying around that echoes stuff you can try how nimib works with following these steps:
  * run in shell `nimble install nimib`
  * add `import nimib` at the top of your nim file
  * add a `nbInit` command right after that
  * split your code into one or more `nbCode:` blocks
  * add some text commentary in markdown through `nbText:` blocks
  * add a `nbSave` command at the end
  * compile and run
  * open the html file that has been generated next to your nim file (same name)
  * (you can use runtime option `--nbShow` to open the html file automatically in your default browser)

See below for an example of this.

Nimib strives for:
  * a simple API
  * sane defaults
  * easy customization

The main goal of Nimib is to empower people to explore nim and its ecosystem and share with others.

This document is generated though nimib both as an index.html file and as a README.md,
you should be reading one of the two, for the other:

* [README.md](https://github.com/pietroppeter/nimib)
* [index.html](.)

Nimib was presented in [NimConf2021](https://conf.nim-lang.org),
see [video](https://www.youtube.com/watch?v=sWA58Wtk6L8)
and [slides](https://github.com/pietroppeter/nimconf2021). 

The vs code extension
[nimiboost](https://marketplace.visualstudio.com/items?itemName=hugogranstrom.nimiboost)
provides markdown highlighting in nimib file and a preview mechanism.

## 👋 🌍 Example Usage

First have a look at the following html document: [hello.html](./hello.html)

This was produced with `nim r docs/hello`, where [docs/hello.nim](https://github.com/pietroppeter/nimib/blob/main/docs/hello.nim) is:

```nim
discard
```


### Other examples of usage

in this repo:

* [index](./index.html): generate an HTML and a README.md at the same time (you are reading one of the two)
* [penguins](./penguins.html): explore palmer penguins dataset using ggplotnim (example of showing images)
* [numerical](./numerical.html): example usage of NumericalNim (example of custom style, usage of latex)
* [cheatsheet](./cheatsheet.html): markdown cheatsheet (example of a custom block, custom highlighting and a simple TOC)
* [mostaccio](./mostaccio.html): examples of usage of nim-mustache and of dark mode.
* [interactivity](./interactivity.html): shows the basic API of creating interactive elements using `nbCodeToJs`.
* [counter](./counters.html): shows how to create reusable interactive widgets by creating a counter button.
* [caesar](./caesar.html): a Caesar cipher implemented using `nbCodeToJs` and `karax`.


elsewhere:

* [adventofnim](https://pietroppeter.github.io/adventofnim/index.html): solutions for advent of code in nim
* [intro to binarylang](https://ajusa.github.io/binarylang-fun/intro.html): a introduction to library [binarylang](https://github.com/sealmove/binarylang) (first public usage of nimib I was aware of)
* [nblog](https://github.com/pietroppeter/nblog): a blog about nimib and its ecosystem
* [nimibook](https://github.com/pietroppeter/nimibook): a port of mdbook to nim(ib)
* [SciNim Getting Started](https://scinim.github.io/getting-started/): tutorials for nim in scientific computing 
* [Norm documentation](https://norm.nim.town): documentation of a Nim ORM library.
* [NimiSlides](https://github.com/HugoGranstrom/nimib-reveal): a [reveal.js](https://revealjs.com) theme for nimib.

you are welcome to add here what you have built with nimib!

## 🛠 Features

> “I try all things, I achieve what I can.” ― Herman Melville, Moby-Dick or, the Whale

The following are the main elements of a default nimib document:

* `nbInit`: initializes a nimib document, required for all other commands to work.
  In particular it creates and injects into scope a `nb` object used by all other blocks
  (see below section API for internal details).
* `nbCode`: code blocks with automatic stdout capture and capture of code source
* `nbText`: text blocks with automatic conversion from markdown to html (thanks to [nim-markdown](https://github.com/soasme/nim-markdown))
* `nbSave`: save the document (by default to html)
* styling with [water.css](https://watercss.kognise.dev/), light mode is default, dark mode available (`nb.darkMode` after `nbInit`).
* static highlighting of nim code. Highlight styling classes are the same of [highlightjs](https://highlightjs.org/)
  and you can pick a different styling (`atom-one-light` is default for light mode, `androidstudio` is default for dark mode).
* (optional) latex rendering through [katex](https://katex.org/) (see below)
* a header with navigation to a home page, a minimal title and an automatic detection of github repo (with link)
* a footer with a "made with nimib" line and a `Show source` button that shows the full source to create the document.
* (optional) possibility to create a markdown version of the same document (see this document for an example: [docs/index.nim](https://github.com/pietroppeter/nimib/blob/main/docs/index.nim))

Customization over the default is mostly achieved through nim-mustache or changing
`NbDoc` and `NbBlock` elements (see below api).
Currently most of the documentation on customization is given by the examples.

### other templates

* `nbImage`: image command to show images (see `penguins.nim` example linked above)
* `nbFile`: content (string or untyped) is saved to file (see example document [files](./files.html))
* `nbRawOutput`: called with string content, it will add the raw content to document (html backend)
* `nbTextWithCode`: a variant of `nbText` that also reads nim source. See example of usage
  at the end of the source in `numerical.nim` linked above.
* `nbPython`:  can be used after calling `nbInitPython()` and it runs and capture output of python code;
  requires [nimpy](https://github.com/yglukhov/nimpy).
* `nbClearOutput`: clears the output of preceding code block,
  useful in case a previous command has produced output that you do not want to show for some reason.


### creating custom blocks

* `newNbCodeBlock(cmd: string, body, blockImpl: untyped)`: template that can be used to create custom
  code block that will need both a `body` and an implementation which might make use of `body`.
  Also, the source code in `body` is read.
  Example blocks created with `newNbCodeBlock` are `nbCode` and `nbTextWithCode`.
* `newNbSlimBlock(cmd: string, blockImpl: untyped)`: template that can be used to create
  a custom block that does not need a separate `body`.
  Example blocks created with `newNbSlimBlock` are `nbText`, `nbImage` and `nbFile`.

See `src/nimib.nim` for examples on nimib blocks that are built using these two templates.

### interactivity using nim js backend

Nimib can incorporate javascript code generated from nim code using template `nbCodeToJs`.
It also provides a template `nbKaraxCode` to add code based on [karax](https://github.com/karaxnim/karax).

See [interactivity](./interactivity.html) for an explanation of the api
and [counter](./counters.html) for examples of how to create widgets using it.
In [caesar](./caesar.html) we have an example of a karax app
that implements [Caesar cipher](https://en.wikipedia.org/wiki/Caesar_cipher).

### latex

See [numerical](./numerical.html) for an example of latex usage.

To add latex support:

  * add a `nb.useLatex` command somewhere between `nbInit` and `nbSave`
  * use delimiters `$` for inline-math or `$$` for display math inside nbText blocks.

Latex is rendered with [katex](https://katex.org/) through an autodetection during document loading.

### config, command line options and interaction with filesystem

In the default situation a single nimib document
that writes or reads from filesystem will behave as a normal nim file:
the current directory is the directory from where you launch the executable.

When nimib is used to produce a website or in general a collection of document
it is useful to set up a **configuration file**.
A nimib configuration file is a file named `nimib.toml` and
it is a [toml](https://github.com/toml-lang/toml) file.
Every time `nbInit` is called nimib tries to find a config file in current directory
or in any parent directory.
Inside a config file you can define two special directory:

* `homeDir`: the directory to set as current directory.
  It can be given as an absolute directory or as a relative directory.
  When it is given as a relative directory it is relative with respect
  to the directory of config file.
* `srcDir`: the directory where all the sources resides.
  It is used to create the output filename that includes a relative path.
  In this way the folder structure of nim files can be recreated in the output.
  As `homeDir`, it can be set as absolute or relative (to config).

`nbInit` also parses command line options that start with `nb` or `nimib`
that allow to override the above value, skip the config file or other options.

All the options available can be seen by running any nimib file with option `nbHelp`
(execution will stop after `nbInit`).

```nim
import osproc
withDir nb.srcDir:
  echo execProcess(&quot;nim r --verbosity:0 --hints:off --warning:UnusedImport:off hello --nbHelp&quot;)
```


```
Nimib options:

  --nbHelp,     --nimibHelp                 print this help
  --nbSkipCfg,  --nimibSkipCfg              skip nimib config file
  --nbCfgName,  --nimibCfgName              change name of config file (default &quot;nimib.toml&quot;)
  --nbSrcDir,   --nimibSrcDir               set srcDir as relative (to CfgDir) or absolute; overrides config 
  --nbHomeDir,  --nimibHomeDir              set homeDir as relative (to CfgDir) or absolute; overrides config 
  --nbFilename, --nimibFilename             overrides name of output file (e.g. somefile --nbFilename:othername.html)
  --nbShow,     --nimibShow                 open in browser at the end of nbSave
```



The value of options are available in `nb.options` field which also
tracks further options in `nb.options.other: seq[tuple[kind: CmdLineKind; name, value: string]]`.

### Code capture

The code capture of a block like `nbCode` (or other custom blocks)
can happen in two different ways:

* `CodeAsInSource` (default since version 0.3): code for a single block
  is parsed from file source (available in `nb.source`).
* `CodeFromAst` (default in versions 0.1 and 0.2): code for a single block
  is rendered from AST of body. This means that only documentation comments
  are shown (since normal comments are not part of the AST) and that the source show
  might be different from original source.
  Since version 0.3 this is available through compile time switch `nimibCodeFromAst`.

## 🐝 API <!-- Api means bees in Italian -->

* `nbInit` template creates and injects a `nb` variable of type `NbDoc`.
* templates like `nbCode` and `nbText` create a new object of type `NbBlock`,
  these objects are added to a sequence of blocks accessible in `nb.blocks`
* the last processed block is available as `nb.blk`
* `nb.blk.output` contains the (non rendered) output of block
* `nb.blk.code` contains the source code of the block
* Work is ongoing to have the code source exactly as in source file (see PR ([#63](https://github.com/pietroppeter/nimib/pull/63)))
* `NbBlock` is a ref object, so changing `nb.blk`, changes the last block in `nb.blocks`.
* rendering happens during the call of `nbSave` and and calls a `nb.render` proc
  that can be overriden
* two render procs are available in nimib, one to produce a html, one to produce markdown
* the default html render proc uses [nim-mustache](https://github.com/soasme/nim-mustache)
  to produce the final document starting from a `document` template available in memory
* the main template (`document`) or all the other templates can be ovveriden in memory or
  providing an ovveride in a template directory
  (defaults are `.` and `templates`, can be overriden with `nb.templateDirs`)
* the templates in memory are available as `nb.partials`
  (partial is another name for a mustache template)
* to fill in all details, mustache starts from a `Context` object, that is initialized during `nbInit`
  and can be updated later (accessible as `nb.context`)
* during `nbInit` a default theme is called that initializes all partials and the context.
  this process can be overriden to create a new "theme" for nimib
  (see for example [nimibook](https://github.com/pietroppeter/nimibook))

Here are two examples that show how to hijack the api:

* [nolan](./nolan.html): how to mess up the timeline of blocks ⏳
* [pythno](./pythno.html): a reminder that nim is not python 😜

## Changelog and 🙏 Thanks

In the [changelog](changelog.md) you find all recent changes, some early history of nimib, pointers to relevant
examples of usage of nimib and heartfelt thanks to some of the fine folks that
made this development possible.

## 🌅 Roadmap

- add more themes such as [nimibook](https://github.com/pietroppeter/nimibook).
  In particular themes for blogging and for creating general websites.
- can I use nimib to build a library directly from documentation (like in [nbdev](https://github.com/fastai/nbdev))?
- nimib executable for scaffolding and to support different publishing workflows
- server-side dynamic sites (streamlit style? take advantage of caching instead of hot code reloading)
- possibility of editing document in the browser (similar to jupyter UI, not necessarily taking advantage of hot code reloading)
- ...

completed in 0.3:
- [x] refactor rendering of blocks and simplify api extensions ([#24](https://github.com/pietroppeter/nimib/issues/24))
- [x] client-side dynamic site: interactivity of documents, e.g. a dahsboard (possibly taking advantage of nim js backend)

## ❓ ❗ Q & A

### why the name?

corruption of [ninib](https://www.vocabulary.com/dictionary/Ninib):

> a solar deity; firstborn of Bel and consort was Gula;
> god of war and the _chase_ and agriculture; sometimes identified with biblical *Nimrod*

also:

> He explains that the seven directions were interpreted by the Babylonian theologians
> as a reference to the seven great celestial bodies, the sun and moon, Ishtar, Marduk, Ninib, Nergal and Nabu.
>
> This process, which reached its culmination in the post-Khammurabic period, led to identifying
> the planet Jupiter with Marduk, Venus with Ishtar, Mars with Nergal, Mercury with Nebo, and Saturn with Ninib.

and I should not need to tell you what [Marduk](https://jupyter.org/) is
and why [Saturn is the best planet](https://www.theatlantic.com/science/archive/2016/01/a-major-correction/422514/).

### why the whale 🐳?

why do you need a logo when you have emojis?

no particular meaning about the whale apart the fact that I like the emoji and this project is something I have been [chasing](https://en.wikipedia.org/wiki/Captain_Ahab) for a while
(and I expect to be chasing it indefinitely).

also googling `nimib whale` you might discover the existence of a cool place: [Skeleton Coast](https://en.wikipedia.org/wiki/Skeleton_Coast).

### why the emojis?

because I made a [package](https://github.com/pietroppeter/nimoji) for that and someone has to use it

### why the Q & A?

because [someone made it into an art form](https://github.com/oakes/vim_cubed#q--a)
and they tell me [imitation is the sincerest form of flattery](https://www.goodreads.com/quotes/558084-imitation-is-the-sincerest-form-of-flattery-that-mediocrity-can)
</main>
<footer>
<hr>
<div class="nb-box">
  <span><span class="nb-small">made with <a href="https://pietroppeter.github.io/nimib/">nimib 🐳</a></span></span>
  <span></span>
  <span><button class="nb-small" id="show" onclick="toggleSourceDisplay()">Show Source</button></span>
</div>
</footer>
<section id="source">
<pre><code class="nim hljs"><span class="hljs-keyword">import</span> nimib, strformat, nimoji, nimib / renders

<span class="hljs-keyword">when</span> <span class="hljs-keyword">defined</span>(mdOutput):
  nbInit(backend=useMdBackend)
<span class="hljs-keyword">else</span>:
  nbInit
nb.title = <span class="hljs-string">&quot;Nimib Docs&quot;</span>

<span class="hljs-keyword">let</span>
  repo = <span class="hljs-string">&quot;https://github.com/pietroppeter/nimib&quot;</span>
  docs = <span class="hljs-keyword">if</span> <span class="hljs-keyword">defined</span>(useMdBackend): <span class="hljs-string">&quot;https://pietroppeter.github.io/nimib&quot;</span> <span class="hljs-keyword">else</span>: <span class="hljs-string">&quot;.&quot;</span>
  hello = read(nb.srcDir / <span class="hljs-string">&quot;hello.nim&quot;</span>.<span class="hljs-type">RelativeFile</span>)
  assets = <span class="hljs-string">&quot;docs/static&quot;</span>
  highlight = <span class="hljs-string">&quot;highlight.nim.js&quot;</span>
  defaultHighlightCss = <span class="hljs-string">&quot;atom-one-light.css&quot;</span>

nbText: <span class="hljs-string">hlMdF&quot;&quot;&quot;
# nimib :whale: - nim :crown: driven :sailboat: publishing :writingHand:

Nimib provides an API to convert your Nim code and its outputs to html documents.

The type of html output that is obtained by default is similar to html notebooks produced by tools
like [Jupyter](https://nbviewer.jupyter.org/url/norvig.com/ipython/Advent%20of%20Code.ipynb)
or [RMarkdown](https://rmarkdown.rstudio.com/lesson-10.html), but nimib provides this starting
directly from standard nim files. It currently does not provide any type of interactivity or automatic reloading.

If you have some nim code lying around that echoes stuff you can try how nimib works with following these steps:
  * run in shell `nimble install nimib`
  * add `import nimib` at the top of your nim file
  * add a `nbInit` command right after that
  * split your code into one or more `nbCode:` blocks
  * add some text commentary in markdown through `nbText:` blocks
  * add a `nbSave` command at the end
  * compile and run
  * open the html file that has been generated next to your nim file (same name)
  * (you can use runtime option `--nbShow` to open the html file automatically in your default browser)

See below for an example of this.

Nimib strives for:
  * a simple API
  * sane defaults
  * easy customization

The main goal of Nimib is to empower people to explore nim and its ecosystem and share with others.

This document is generated though nimib both as an index.html file and as a README.md,
you should be reading one of the two, for the other:

* [README.md]({repo})
* [index.html]({docs})

Nimib was presented in [NimConf2021](https://conf.nim-lang.org),
see [video](https://www.youtube.com/watch?v=sWA58Wtk6L8)
and [slides](https://github.com/pietroppeter/nimconf2021). 

The vs code extension
[nimiboost](https://marketplace.visualstudio.com/items?itemName=hugogranstrom.nimiboost)
provides markdown highlighting in nimib file and a preview mechanism.

## :wave: :earthAfrica: Example Usage

First have a look at the following html document: [hello.html]({docs}/hello.html)

This was produced with `nim r docs/hello`, where [docs/hello.nim]({repo}/blob/main/docs/hello.nim) is:
&quot;&quot;&quot;</span>.emojize


<span class="hljs-keyword">when</span> <span class="hljs-keyword">not</span> <span class="hljs-keyword">defined</span>(useMdBackend):
  nbCode: <span class="hljs-keyword">discard</span>
  nb.blk.code = hello  <span class="hljs-comment"># &quot;\n&quot; should not be needed here (fix required in rendering)</span>
<span class="hljs-keyword">else</span>:
  nbText &amp;<span class="hljs-string">&quot;&quot;&quot;
```nim
{hello}
```&quot;&quot;&quot;</span>


nbText: <span class="hljs-string">hlMdF&quot;&quot;&quot;
### Other examples of usage

in this repo:

* [index]({docs}/index.html): generate an HTML and a README.md at the same time (you are reading one of the two)
* [penguins]({docs}/penguins.html): explore palmer penguins dataset using ggplotnim (example of showing images)
* [numerical]({docs}/numerical.html): example usage of NumericalNim (example of custom style, usage of latex)
* [cheatsheet]({docs}/cheatsheet.html): markdown cheatsheet (example of a custom block, custom highlighting and a simple TOC)
* [mostaccio]({docs}/mostaccio.html): examples of usage of nim-mustache and of dark mode.
* [interactivity]({docs}/interactivity.html): shows the basic API of creating interactive elements using `nbCodeToJs`.
* [counter]({docs}/counters.html): shows how to create reusable interactive widgets by creating a counter button.
* [caesar]({docs}/caesar.html): a Caesar cipher implemented using `nbCodeToJs` and `karax`.


elsewhere:

* [adventofnim](https://pietroppeter.github.io/adventofnim/index.html): solutions for advent of code in nim
* [intro to binarylang](https://ajusa.github.io/binarylang-fun/intro.html): a introduction to library [binarylang](https://github.com/sealmove/binarylang) (first public usage of nimib I was aware of)
* [nblog](https://github.com/pietroppeter/nblog): a blog about nimib and its ecosystem
* [nimibook](https://github.com/pietroppeter/nimibook): a port of mdbook to nim(ib)
* [SciNim Getting Started](https://scinim.github.io/getting-started/): tutorials for nim in scientific computing 
* [Norm documentation](https://norm.nim.town): documentation of a Nim ORM library.
* [NimiSlides](https://github.com/HugoGranstrom/nimib-reveal): a [reveal.js](https://revealjs.com) theme for nimib.

you are welcome to add here what you have built with nimib!

## :hammer_and_wrench: Features

&gt; “I try all things, I achieve what I can.” ― Herman Melville, Moby-Dick or, the Whale

The following are the main elements of a default nimib document:

* `nbInit`: initializes a nimib document, required for all other commands to work.
  In particular it creates and injects into scope a `nb` object used by all other blocks
  (see below section API for internal details).
* `nbCode`: code blocks with automatic stdout capture and capture of code source
* `nbText`: text blocks with automatic conversion from markdown to html (thanks to [nim-markdown](https://github.com/soasme/nim-markdown))
* `nbSave`: save the document (by default to html)
* styling with [water.css](https://watercss.kognise.dev/), light mode is default, dark mode available (`nb.darkMode` after `nbInit`).
* static highlighting of nim code. Highlight styling classes are the same of [highlightjs](https://highlightjs.org/)
  and you can pick a different styling (`atom-one-light` is default for light mode, `androidstudio` is default for dark mode).
* (optional) latex rendering through [katex](https://katex.org/) (see below)
* a header with navigation to a home page, a minimal title and an automatic detection of github repo (with link)
* a footer with a &quot;made with nimib&quot; line and a `Show source` button that shows the full source to create the document.
* (optional) possibility to create a markdown version of the same document (see this document for an example: [docs/index.nim]({repo}/blob/main/docs/index.nim))

Customization over the default is mostly achieved through nim-mustache or changing
`NbDoc` and `NbBlock` elements (see below api).
Currently most of the documentation on customization is given by the examples.

### other templates

* `nbImage`: image command to show images (see `penguins.nim` example linked above)
* `nbFile`: content (string or untyped) is saved to file (see example document [files]({docs}/files.html))
* `nbRawOutput`: called with string content, it will add the raw content to document (html backend)
* `nbTextWithCode`: a variant of `nbText` that also reads nim source. See example of usage
  at the end of the source in `numerical.nim` linked above.
* `nbPython`:  can be used after calling `nbInitPython()` and it runs and capture output of python code;
  requires [nimpy](https://github.com/yglukhov/nimpy).
* `nbClearOutput`: clears the output of preceding code block,
  useful in case a previous command has produced output that you do not want to show for some reason.


### creating custom blocks

* `newNbCodeBlock(cmd: string, body, blockImpl: untyped)`: template that can be used to create custom
  code block that will need both a `body` and an implementation which might make use of `body`.
  Also, the source code in `body` is read.
  Example blocks created with `newNbCodeBlock` are `nbCode` and `nbTextWithCode`.
* `newNbSlimBlock(cmd: string, blockImpl: untyped)`: template that can be used to create
  a custom block that does not need a separate `body`.
  Example blocks created with `newNbSlimBlock` are `nbText`, `nbImage` and `nbFile`.

See `src/nimib.nim` for examples on nimib blocks that are built using these two templates.

### interactivity using nim js backend

Nimib can incorporate javascript code generated from nim code using template `nbCodeToJs`.
It also provides a template `nbKaraxCode` to add code based on [karax](https://github.com/karaxnim/karax).

See [interactivity]({docs}/interactivity.html) for an explanation of the api
and [counter]({docs}/counters.html) for examples of how to create widgets using it.
In [caesar]({docs}/caesar.html) we have an example of a karax app
that implements [Caesar cipher](https://en.wikipedia.org/wiki/Caesar_cipher).

### latex

See [numerical]({docs}/numerical.html) for an example of latex usage.

To add latex support:

  * add a `nb.useLatex` command somewhere between `nbInit` and `nbSave`
  * use delimiters `$` for inline-math or `$$` for display math inside nbText blocks.

Latex is rendered with [katex](https://katex.org/) through an autodetection during document loading.

### config, command line options and interaction with filesystem

In the default situation a single nimib document
that writes or reads from filesystem will behave as a normal nim file:
the current directory is the directory from where you launch the executable.

When nimib is used to produce a website or in general a collection of document
it is useful to set up a **configuration file**.
A nimib configuration file is a file named `nimib.toml` and
it is a [toml](https://github.com/toml-lang/toml) file.
Every time `nbInit` is called nimib tries to find a config file in current directory
or in any parent directory.
Inside a config file you can define two special directory:

* `homeDir`: the directory to set as current directory.
  It can be given as an absolute directory or as a relative directory.
  When it is given as a relative directory it is relative with respect
  to the directory of config file.
* `srcDir`: the directory where all the sources resides.
  It is used to create the output filename that includes a relative path.
  In this way the folder structure of nim files can be recreated in the output.
  As `homeDir`, it can be set as absolute or relative (to config).

`nbInit` also parses command line options that start with `nb` or `nimib`
that allow to override the above value, skip the config file or other options.

All the options available can be seen by running any nimib file with option `nbHelp`
(execution will stop after `nbInit`).
&quot;&quot;&quot;</span>.emojize

nbCode:
  <span class="hljs-keyword">import</span> osproc
  withDir nb.srcDir:
    <span class="hljs-keyword">echo</span> execProcess(<span class="hljs-string">&quot;nim r --verbosity:0 --hints:off --warning:UnusedImport:off hello --nbHelp&quot;</span>)

nbText: <span class="hljs-string">hlMdF&quot;&quot;&quot;

The value of options are available in `nb.options` field which also
tracks further options in `nb.options.other: seq[tuple[kind: CmdLineKind; name, value: string]]`.

### Code capture

The code capture of a block like `nbCode` (or other custom blocks)
can happen in two different ways:

* `CodeAsInSource` (default since version 0.3): code for a single block
  is parsed from file source (available in `nb.source`).
* `CodeFromAst` (default in versions 0.1 and 0.2): code for a single block
  is rendered from AST of body. This means that only documentation comments
  are shown (since normal comments are not part of the AST) and that the source show
  might be different from original source.
  Since version 0.3 this is available through compile time switch `nimibCodeFromAst`.

## :honeybee: API &lt;!-- Api means bees in Italian --&gt;

* `nbInit` template creates and injects a `nb` variable of type `NbDoc`.
* templates like `nbCode` and `nbText` create a new object of type `NbBlock`,
  these objects are added to a sequence of blocks accessible in `nb.blocks`
* the last processed block is available as `nb.blk`
* `nb.blk.output` contains the (non rendered) output of block
* `nb.blk.code` contains the source code of the block
* Work is ongoing to have the code source exactly as in source file (see PR ([#63](https://github.com/pietroppeter/nimib/pull/63)))
* `NbBlock` is a ref object, so changing `nb.blk`, changes the last block in `nb.blocks`.
* rendering happens during the call of `nbSave` and and calls a `nb.render` proc
  that can be overriden
* two render procs are available in nimib, one to produce a html, one to produce markdown
* the default html render proc uses [nim-mustache](https://github.com/soasme/nim-mustache)
  to produce the final document starting from a `document` template available in memory
* the main template (`document`) or all the other templates can be ovveriden in memory or
  providing an ovveride in a template directory
  (defaults are `.` and `templates`, can be overriden with `nb.templateDirs`)
* the templates in memory are available as `nb.partials`
  (partial is another name for a mustache template)
* to fill in all details, mustache starts from a `Context` object, that is initialized during `nbInit`
  and can be updated later (accessible as `nb.context`)
* during `nbInit` a default theme is called that initializes all partials and the context.
  this process can be overriden to create a new &quot;theme&quot; for nimib
  (see for example [nimibook](https://github.com/pietroppeter/nimibook))

Here are two examples that show how to hijack the api:

* [nolan]({docs}/nolan.html): how to mess up the timeline of blocks :hourglass_flowing_sand:
* [pythno]({docs}/pythno.html): a reminder that nim is not python :stuck_out_tongue_winking_eye:

## Changelog and :pray: Thanks

In the [changelog](changelog.md) you find all recent changes, some early history of nimib, pointers to relevant
examples of usage of nimib and heartfelt thanks to some of the fine folks that
made this development possible.

## :sunrise: Roadmap

- add more themes such as [nimibook](https://github.com/pietroppeter/nimibook).
  In particular themes for blogging and for creating general websites.
- can I use nimib to build a library directly from documentation (like in [nbdev](https://github.com/fastai/nbdev))?
- nimib executable for scaffolding and to support different publishing workflows
- server-side dynamic sites (streamlit style? take advantage of caching instead of hot code reloading)
- possibility of editing document in the browser (similar to jupyter UI, not necessarily taking advantage of hot code reloading)
- ...

completed in 0.3:
- [x] refactor rendering of blocks and simplify api extensions ([#24](https://github.com/pietroppeter/nimib/issues/24))
- [x] client-side dynamic site: interactivity of documents, e.g. a dahsboard (possibly taking advantage of nim js backend)

## :question: :exclamation: Q &amp; A

### why the name?

corruption of [ninib](https://www.vocabulary.com/dictionary/Ninib):

&gt; a solar deity; firstborn of Bel and consort was Gula;
&gt; god of war and the _chase_ and agriculture; sometimes identified with biblical *Nimrod*

also:

&gt; He explains that the seven directions were interpreted by the Babylonian theologians
&gt; as a reference to the seven great celestial bodies, the sun and moon, Ishtar, Marduk, Ninib, Nergal and Nabu.
&gt;
&gt; This process, which reached its culmination in the post-Khammurabic period, led to identifying
&gt; the planet Jupiter with Marduk, Venus with Ishtar, Mars with Nergal, Mercury with Nebo, and Saturn with Ninib.

and I should not need to tell you what [Marduk](https://jupyter.org/) is
and why [Saturn is the best planet](https://www.theatlantic.com/science/archive/2016/01/a-major-correction/422514/).

### why the whale :whale:?

why do you need a logo when you have emojis?

no particular meaning about the whale apart the fact that I like the emoji and this project is something I have been [chasing](https://en.wikipedia.org/wiki/Captain_Ahab) for a while
(and I expect to be chasing it indefinitely).

also googling `nimib whale` you might discover the existence of a cool place: [Skeleton Coast](https://en.wikipedia.org/wiki/Skeleton_Coast).

### why the emojis?

because I made a [package](https://github.com/pietroppeter/nimoji) for that and someone has to use it

### why the Q &amp; A?

because [someone made it into an art form](https://github.com/oakes/vim_cubed#q--a)
and they tell me [imitation is the sincerest form of flattery](https://www.goodreads.com/quotes/558084-imitation-is-the-sincerest-form-of-flattery-that-mediocrity-can)
&quot;&quot;&quot;</span>.emojize

<span class="hljs-keyword">when</span> <span class="hljs-keyword">defined</span>(mdOutput):
  nb.filename = <span class="hljs-string">&quot;../README.md&quot;</span>
  nbSave
<span class="hljs-keyword">else</span>:
  nbSave
</code></pre>
</section><script>
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
</script></body>
</html>
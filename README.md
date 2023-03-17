
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
* [index.html](https://pietroppeter.github.io/nimib)

Nimib was presented at [NimConf2022](https://nim-lang.org/nimconf2022/), see the [slides](https://github.com/pietroppeter/nimconf22-nimib/) and click thumbnail to see video.
[![nimib nimconf2022 thumbnail](https://github.com/pietroppeter/nimib/raw/d4399747aa4c4435d27e0038046ad0311a92f21d/assets/nimib-nimconf-thumbnail.png)](https://www.youtube.com/watch?v=hZ7wX1kgnuc)

Nimib was also presented in [NimConf2021](https://conf.nim-lang.org),
see [video](https://www.youtube.com/watch?v=sWA58Wtk6L8)
and [slides](https://github.com/pietroppeter/nimconf2021). 

The VS Codium / Code extension
[nimiboost](https://marketplace.visualstudio.com/items?itemName=hugogranstrom.nimiboost) ([Open VSX](https://open-vsx.org/extension/hugogranstrom/nimiboost))
provides syntax highlighting of embedded languages in nimib documents (eg. markdown, python, html) and a preview window of nimib documents inside the editor.

## 👋 🌍 Example Usage

First have a look at the following html document: [hello.html](https://pietroppeter.github.io/nimib/hello.html)

This was produced with `nim r docsrc/hello`, where [docsrc/hello.nim](https://github.com/pietroppeter/nimib/blob/main/docsrc/hello.nim) is:


```nim
import strformat, strutils
import nimib

nbInit

nbText: """
## Secret talk with a computer
Let me show you how to talk with the computer like a [real hacker](https://mango.pdf.zone/)
and incidentally you might learn the basics of [nimib](https://github.com/pietroppeter/nimib).
### A secret message
Inside this document is hidden a secret message. I will ask the computer to spit it out:
"""

let secret = [104, 101, 108, 108, 111, 44, 32, 119, 111, 114, 108, 100]

nbCode:
  echo secret

nbText: fmt"""
what does this integer sequence mean?
Am I supposed to [recognize it](https://oeis.org/search?q={secret.join("%2C+")}&language=english&go=Search)?

### A cryptoanalytic weapon
Luckily I happen to have a [nim](https://nim-lang.org/) implementation of
a recently declassified top-secret cryptoanalytic weapon:"""

nbCode:
  func decode(secret: openArray[int]): string =
    ## classified by NSA as <strong>TOP SECRET</strong>
    for c in secret:
      result.add char(c)

nbText: """
  ### The great revelation
  Now I can just apply it to my secret message and
  finally decrypt what the computer wants to tell me:"""

nbCode:
  let msg = decode secret
  echo msg  # what will it say?

nbText:
  fmt"_Hey_, there must be a bug somewhere, the message (`{msg}`) is not even addressed to me!"

nbSave

```


### Other examples of usage

in this repo:

* [index](https://pietroppeter.github.io/nimib/index.html): generate an HTML and a README.md at the same time (you are reading one of the two)
* [penguins](https://pietroppeter.github.io/nimib/penguins.html): explore palmer penguins dataset using ggplotnim (example of showing images)
* [numerical](https://pietroppeter.github.io/nimib/numerical.html): example usage of NumericalNim (example of custom style, usage of latex)
* [cheatsheet](https://pietroppeter.github.io/nimib/cheatsheet.html): markdown cheatsheet (example of a custom block, custom highlighting and a simple TOC)
* [mostaccio](https://pietroppeter.github.io/nimib/mostaccio.html): examples of usage of nim-mustache and of dark mode.
* [interactivity](https://pietroppeter.github.io/nimib/interactivity.html): shows the basic API of creating interactive elements using `nbJsFromCode`.
* [counter](https://pietroppeter.github.io/nimib/counters.html): shows how to create reusable interactive widgets by creating a counter button.
* [caesar](https://pietroppeter.github.io/nimib/caesar.html): a Caesar cipher implemented using `nbKaraxCode` and `karax`.


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
* (optional) possibility to create a markdown version of the same document (see this document for an example: [docsrc/index.nim](https://github.com/pietroppeter/nimib/blob/main/docsrc/index.nim))

Customization over the default is mostly achieved through nim-mustache or changing
`NbDoc` and `NbBlock` elements (see below api).
Currently most of the documentation on customization is given by the examples.

### other templates

* `nbImage`: image command to show images (see `penguins.nim` example linked above)
* `nbFile`: content (string or untyped) is saved to file (see example document [files](https://pietroppeter.github.io/nimib/files.html))
* `nbShow`: show a variable that has a `toHtml` proc defined. For example to pretty print a dataframe.
* `nbRawHtml`: called with string content, it will add the raw content to document (html backend)
* `nbTextWithCode`: a variant of `nbText` that also reads nim source. See example of usage
  at the end of the source in `numerical.nim` linked above.
* `nbCodeSkip`: a variant of `nbCode` that that displays highlighted code but does not compile or run it.
* `nbCapture`: a block that only shows the captured output of a code block
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
  Example blocks created with `newNbSlimBlock` are `nbText`, `nbImage`.

See `src/nimib.nim` for examples on nimib blocks that are built using these two templates.

* a `newId` proc is available for `nb: NbDoc` object and provides an incremental integer.
  It can be used in some custom blocks (it is used in `nbJsFromCode` described below).

### interactivity using nim js backend

Nimib can incorporate javascript code generated from nim code using template `nbJsFromCode`.
It also provides a template `nbKaraxCode` to add code based on [karax](https://github.com/karaxnim/karax).

See [interactivity](https://pietroppeter.github.io/nimib/interactivity.html) for an explanation of the api
and [counter](https://pietroppeter.github.io/nimib/counters.html) for examples of how to create widgets using it.
In [caesar](https://pietroppeter.github.io/nimib/caesar.html) we have an example of a karax app
that implements [Caesar cipher](https://en.wikipedia.org/wiki/Caesar_cipher).

### highlighting
Code blocks produced by `nbCode` are statically highlighted, but code in markdown code blocks are dynamically highlighted using 
[highlightjs](https://highlightjs.org/). The dynamic highlighting can be disabled by running `nb.disableHighlightJs()`. 
The supported languages are the ones listed as "common" [here](https://highlightjs.org/download/) plus Nim, Julia and Latex.

Highlight styling classes are the same of [highlightjs](https://highlightjs.org/)
and you can pick a different styling (`atom-one-light` is default for light mode, `androidstudio` is default for dark mode).

### latex

See [numerical](https://pietroppeter.github.io/nimib/numerical.html) for an example of latex usage.

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
  echo execProcess(&quot;nim r --verbosity:0 --hints:off --warnings:off hello --nbHelp&quot;)
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
* `nb.blk.code` contains the source code of the block (if it was created with `newNbCodeBlock`)
* `NbBlock` is a ref object, so changing `nb.blk`, changes the last block in `nb.blocks`.

Here are two examples that show how to hijack the api:

* [nolan](https://pietroppeter.github.io/nimib/nolan.html): how to mess up the timeline of blocks ⏳
* [pythno](https://pietroppeter.github.io/nimib/pythno.html): a reminder that nim is not python 😜

## Rendering

* rendering is currently based on [nim-mustache](https://github.com/soasme/nim-mustache).
  This will likely be changed in a next release and in fact refactoring the rendering part of nimib
  is the main target for next breaking change, see [#111](https://github.com/pietroppeter/nimib/issues/111)
* there are two rendering backends, a html one and a markdown backend.
  In order to use the markdown backend one must initialize its document with `nbInitMd` instead of `nbInit`
* rendering happens during the call to `nbSave`, and two steps are performed:
  1. rendering all blocks and adding them to a sequence of blocks (added to `nb.context["blocks"]`)
  2. rendering the document starting from `document` partial using 
* rendering of a single block depends
  on a number of fields of `nb` object:
  - `partials`: a `Table[string, string]` that contains the templates/partials for every command (e.g. `nb.partials["nbCode"]`);
  - `templateDirs`: a `seq[string]` of folders where to look for `.mustache` templates that can complement/override
    the templates in `partials`.
    A common usage is to add a `head_other.mustache` template that contain additional content added to head section 
    of **every** document (in many repositories - including nimib - it is used to add a [plausible analytics](https://plausible.io) script)
  - `renderPlans`: a `Table[string, seq[string]]` that contains the render plan (a `seq[string]`) for every step of render plan
    an associated `renderProc` is called;
  - `renderProcs`: a `Table[string, NbRenderProc]` that contains all available render procs by name.
     (`type NbRenderProc = proc (doc: var NbDoc, blk: var NbBlock) {. nimcall .}`)
* the above fields are initialized during `nbInit` with a call to `render` backend and can
  be customized by a call to `theme` (`render` and `theme` have default values).

## Changelog and 🙏 Thanks

In the [changelog](https://github.com/pietroppeter/nimib/blob/main/changelog.md) you find all recent changes, some early history of nimib, pointers to relevant
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


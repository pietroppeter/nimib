import nimib, strformat, nimoji

nbInit
nbDoc.title = "Nimib Docs"

let
  repo = "https://github.com/pietroppeter/nimib"
  docs = "https://pietroppeter.github.io/nimib"
  hello = read("hello.nim".RelativeFile)
  assets = "docs/static"
  highlight = "highlight.nim.js"
  defaultHighlightCss = "atom-one-light.css"

nbText: fmt"""
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

## :wave: :earthAfrica: Example Usage

First have a look at the following html document: [hello.html]({docs}/hello.html)

This was produced with `nim r docs/hello`, where [docs/hello.nim]({repo}/blob/main/docs/hello.nim) is:
""".emojize
nbCode: discard
nbBlock.code = "\n" & hello  # "\n" should not be needed here (fix required in rendering)
nbText: fmt"""
<!--TODO
Notes should be directly embedded in hello file.
-->

### Other examples of usage

in this repo:

* [index]({docs}/index.html): generate an HTML and a README.md at the same time (you are reading one of the two)
* [penguins]({docs}/penguins.html): explore palmer penguins dataset using ggplotnim (example of showing images)
* [numerical]({docs}/numerical.html): example usage of NumericalNim (example of custom style, usage of latex)
* [cheatsheet]({docs}/cheatsheet.html): markdown cheatsheet (example of a custom block, custom highlighting and a simple TOC)
* [mostaccio]({docs}/mostaccio.html): examples of usage of nim-mustache and of dark mode.
* [ptest]({docs}/ptest.html): print testing for nimib

elsewhere:

* [adventofnim](https://pietroppeter.github.io/adventofnim/index.html): solutions for advent of code in nim
* [intro to binarylang](https://ajusa.github.io/binarylang-fun/intro.html): a introduction to library [binarylang](https://github.com/sealmove/binarylang) (first public usage of nimib I was aware of)

## :hammer_and_wrench: Features

> “I try all things, I achieve what I can.” ― Herman Melville, Moby-Dick or, the Whale

The following are the main elements of a default nimib document:

* `nbCode`: code blocks with automatic stdout capture
* `nbText`: text blocks with automatic conversion from markdown to html (thanks to [nim-markdown](https://github.com/soasme/nim-markdown))
* `nbImage`: image command to show images
* styling with [water.css](https://watercss.kognise.dev/), light mode is default, dark mode available (`nbDoc.darkMode` after `nbInit`).
* static highlighting of nim code. Highlight styling classes are the same of [highlightjs](https://highlightjs.org/)
  and you can pick a different styling (`atom-one-light` is default for light mode, `androidstudio` is default for dark mode).
* (optional) latex rendering through [katex](https://katex.org/) (see below)
* a header with navigation to a home page, a minimal title and an automatic detection of github repo (with link)
* a footer with a "made with nimib" line and a `Show source` button that shows the full source to create the document.
* (optional) possibility to create a markdown version of the same document (see this document for an example: [docs/index.nim]({repo}/blob/main/docs/index.nim))

Customization over the default is mostly achieved through nim-mustache or the internal Api (see below).
Currently most of the documentation on customization is given by the examples.

### latex

See [numerical]({docs}/numerical.html) for an example of latex usage.

To add latex support:

  * add a `nbDoc.useLatex` command somewhere between `nbInit` and `nbSave`
  * use delimiters `$` for inline-math or `$$` for display math inside nbText blocks.

Latex is rendered with [katex](https://katex.org/) through an autodetection during document loading.

### interaction with filesystem

The default situation for single article that does not access filesystem:

* you do not have to worry about nothing.
  the new html will appear next to your nim file with same name and html extension

if you need to change name or location of html output, or if you need to access
filesystem (in particular if you need it for your web assets), this is what you need to know:

* with `nbInit` a `nbHomeDir` a number of paths are initialized
* we follow [compiler/pathutils](https://nim-lang.org/docs/compiler/pathutils.html) which is available (exported) from `nimib/paths`.
* `nbThisFile` is an `AbsoluteFile` path of current nim file (the one where the `nbInit` is called from). `nbThisDir` is the corresponding `AbsoluteDir`.
* `nbHomeDir` is a "home" directory:
  - if no nimble file is found in `nbThisDir` or a parent directory, then it is set to `nbThisDir`.
  - if a nimble file is found and in that directory there is a `docs` folder, it is set to that `docs` folder.
  - if a nimble file is found without a `docs` folder, it is set to the directory containing the nimble file.
* current directory is set to `nbHomeDir` (current directory at initialization is saved in `nbInitDir` if needed)
* a procedure `relPath(path: AbsoluteFile | AbsoluteDir): string` turns an AbsolutePath into a string path relative to `nbHomeDir`

## :honeybee: API <!-- Api means bees in Italian -->

### external API

By external API we mean the following templates:

* `nbInit` (*always required*): it initializes the notebook,
   the other templates are not accessible if nbInit is not called.
* `nbText`: it is followed by any expression that evaluates to a string.
  this text is by default assumed to be markdown and it will be rendered as html
  thanks to [nim-markdown](https://github.com/soasme/nim-markdown).
* `nbCode`: followed by a block of code, it will execute the code,
  and capture the output. It will be rendered in the final html document
  as a block of nim code followed by preformatted text.
* `nbSave`: it is required to save the document to a file.
  Rendering takes place at this moment.
  By default the document will be save as an html (templated with [nim-mustache](https://github.com/soasme/nim-mustache))

other templates on top of the four basic ones are available (e.g. `nbImage`)
or will likely be added (see issue [#2](https://github.com/pietroppeter/nimib/issues/2)).

### internal api

`nbInit` creates two variables `nbDoc` and `nbBlock`, which are injected in the scope.
At every block of code or text (or else) `nbBlock` is updated and added to `nbDoc`.
`nbBlock` is a ref object, so changes done to it after a block will be reflected in
the content of `nbDoc`.

The specific types `NbDoc` and `NbBlock` are unstable and they will likely change,
but it is likely that access the following elements will be guaranteed:

  * `nbDoc.blocks`: container of all the blocks
  * `nbDoc.render`: a closure from NbDoc to string that produces the rendered document
  * `nbBlock.output`: string with the output of a nbCode/nbText block (not yet rendered)
  * `nbBlock.code`: stringification of the code block through AST.
    if it appears different than what you typed it is because nim likes it better that way.
    In particular only documentation comments survive this process and normal comments will
    not appear.

Here are two examples that show how to abuse the internal api:

* [nolan]({docs}/nolan.html): how to mess up the timeline of blocks :hourglass_flowing_sand:
* [pythno]({docs}/pythno.html): a reminder that nim is not python :stuck_out_tongue_winking_eye:

<!--
### extending the api

*TODO* after 0.2

## Rendering

*TODO* after 0.2

### html rendering

There are two levels of html rendering.

1. **render-in-the-small**: rendering html fragments. This is mostly taken care by nim-markdown
   and by appropriate semantic tagging in render functions (this can be overriden).
2. **render-in-the-large***: putting together html fragments and other elements to publish one or more documents.
   this is delegated to nim-mustache and to manual creation and update of json and context fields in doc and block objects.
-->

## :sunrise: Roadmap

- refactor rendering and simplify customization ([#24](https://github.com/pietroppeter/nimib/issues/24))
- add additional blocks and features for blogging ([#30](https://github.com/pietroppeter/nimib/issues/30))
- a [mdbook](https://rust-lang.github.io/mdBook/) / [bookdown](https://bookdown.org/) theme.
- can I use nimib to build library directly from documentation?
- client-side dynamic site: interactivity of documents, e.g. a dahsboard (possibly taking advantage of nim js backend)
- nimib executable for scaffolding and to support different publishing workflows
- server-side dynamic sites (streamlit style? take advantage of caching instead of hot code reloading)
- possibility of editing document in the browser (similar to jupyter UI, not necessarily taking advantage of hot code reloading)
- ...

## :pray: Thanks

to:

* [soasme](https://github.com/soasme) for the excellent libraries nim-markdown and nim-mustache, which provide the backbone of nimib rendering and customization
* [clonk](https://github.com/clonk) for help in a critical piece of code early on (see [this Stack Overflow answer](https://stackoverflow.com/a/64032172/4178189))
* [yardanico](https://github.com/yardanico) for being the first contributor and great sponsor of this library, even before an official release

## :question: :exclamation: Q & A

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

### why the whale :whale:?

why do you need a logo when you have emojis?

no particular meaning about the whale apart the fact that I like the emoji and this project is something I have been [chasing](https://en.wikipedia.org/wiki/Captain_Ahab) for a while
(and I expect to be chasing it indefinitely).

also googling `nimib whale` you might discover the existence of a cool place: [Skeleton Coast](https://en.wikipedia.org/wiki/Skeleton_Coast).

### why the emojis?

because I made a [package](https://github.com/pietroppeter/nimoji) for that and someone has to use it

### why the Q & A?

because [someone made it into an art form](https://github.com/oakes/vim_cubed#q--a)
and they tell me [imitation is the sincerest form of flattery](https://www.goodreads.com/quotes/558084-imitation-is-the-sincerest-form-of-flattery-that-mediocrity-can)
""".emojize

nbSave

nbDoc.render = renderMark
nbDoc.filename = "../README.md"
nbSave

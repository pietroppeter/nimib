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

Nimib was presented in [NimConf2021](https://conf.nim-lang.org),
see [video](https://www.youtube.com/watch?v=sWA58Wtk6L8)
and [slides](https://github.com/pietroppeter/nimconf2021). 

The vs code extension
[nimiboost](https://marketplace.visualstudio.com/items?itemName=hugogranstrom.nimiboost)
provides markdown highlighting in nimib file and a preview mechanism.

## 👋 🌍 Example Usage

First have a look at the following html document: [hello.html](https://pietroppeter.github.io/nimib/hello.html)

This was produced with `nim r docs/hello`, where [docs/hello.nim](https://github.com/pietroppeter/nimib/blob/main/docs/hello.nim) is:


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
    # so secret that they do not want me to tell you and they will remove this message!
    for c in secret:
      result.add char(c)

nbText: """
  ### The great revelation
  Now I can just apply it to my secret message and
  finally decrypt what the computer wants to tell me:"""

nbCode:
  let msg = decode secret
  echo msg

nbText:
  fmt"_Hey_, there must be a bug somewhere, the message (`{msg}`) is not even addressed to me!"

nbSave # use nbShow to automatically open a browser tab with html output

```


### Other examples of usage

in this repo:

* [index](https://pietroppeter.github.io/nimib/index.html): generate an HTML and a README.md at the same time (you are reading one of the two)
* [penguins](https://pietroppeter.github.io/nimib/penguins.html): explore palmer penguins dataset using ggplotnim (example of showing images)
* [numerical](https://pietroppeter.github.io/nimib/numerical.html): example usage of NumericalNim (example of custom style, usage of latex)
* [cheatsheet](https://pietroppeter.github.io/nimib/cheatsheet.html): markdown cheatsheet (example of a custom block, custom highlighting and a simple TOC)
* [mostaccio](https://pietroppeter.github.io/nimib/mostaccio.html): examples of usage of nim-mustache and of dark mode.
* [ptest](https://pietroppeter.github.io/nimib/ptest.html): print testing for nimib

elsewhere:

* [adventofnim](https://pietroppeter.github.io/adventofnim/index.html): solutions for advent of code in nim
* [intro to binarylang](https://ajusa.github.io/binarylang-fun/intro.html): a introduction to library [binarylang](https://github.com/sealmove/binarylang) (first public usage of nimib I was aware of)
* [nblog](https://github.com/pietroppeter/nblog): a blog about nimib and its ecosystem
* [nimibook](https://github.com/pietroppeter/nimibook): a port of mdbook to nim(ib)
* [SciNim Getting Started](https://scinim.github.io/getting-started/): tutorials for nim in scientific computing 
* [Norm documentation](https://norm.nim.town): documentation of a Nim ORM library.

you are welcome to add here what you have built with nimib!

## 🛠 Features

> “I try all things, I achieve what I can.” ― Herman Melville, Moby-Dick or, the Whale

The following are the main elements of a default nimib document:

* `nbInit`: initializes a nimib document, required for all other commands to work.
* `nbCode`: code blocks with automatic stdout capture
* `nbText`: text blocks with automatic conversion from markdown to html (thanks to [nim-markdown](https://github.com/soasme/nim-markdown))
* `nbImage`: image command to show images
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
To see all the options execute any nimib file with option `nbHelp`.


## 🐝 API <!-- Api means bees in Italian -->

* `nbInit` template creates and injects a `nb` variable of type `NbDoc`.
* templates like `nbCode` and `nbText` create a new object of type `NbBlock`,
  these objects are added to a sequence of blocks accessible in `nb.blocks`
* the last processed block is available as `nb.blk`
* `nb.blk.output` contains the (non rendered) output of block
* `nb.blk.code` contains the source code of the block
* currently the source code is a stringification of AST and as such it might be
  formatted differently than the actual source
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

* [nolan](https://pietroppeter.github.io/nimib/nolan.html): how to mess up the timeline of blocks ⏳
* [pythno](https://pietroppeter.github.io/nimib/pythno.html): a reminder that nim is not python 😜

## Changelog

### 0.2

most of the changes break the api

* instead of creating and injecting multiple variables
  (`nbDoc`, `nbBlock`, `nbHomeDir`, ...), nimib now only injects a `nb` variable
  that is a `NbDoc`. Some aliases are provided to minimize breakage.
* handling of paths (`srcDir` and `homeDir`) is changed and is based on the presence
  of a new config file `nimib.toml`
* command line options are now processed and can be used to skip/override the config process.
  Run any nimib file with option `--nbHelp` to see available options.
* `nbPostInit` and `nbPreSave` customization mechanism based on includes are now removed 

## 🌅 Roadmap

- refactor rendering of blocks and simplify api extensions ([#24](https://github.com/pietroppeter/nimib/issues/24))
- add more themes such as [nimibook](https://github.com/pietroppeter/nimibook).
  In particular themes for blogging and for creating general websites.
- client-side dynamic site: interactivity of documents, e.g. a dahsboard (possibly taking advantage of nim js backend)
- can I use nimib to build a library directly from documentation?
- nimib executable for scaffolding and to support different publishing workflows
- server-side dynamic sites (streamlit style? take advantage of caching instead of hot code reloading)
- possibility of editing document in the browser (similar to jupyter UI, not necessarily taking advantage of hot code reloading)
- ...

## 🙏 Thanks

to:

* [soasme](https://github.com/soasme) for the excellent libraries nim-markdown and nim-mustache, which provide the backbone of nimib rendering and customization
* [Clonkk](https://github.com/Clonkk) for help in a critical piece of code early on (see [this Stack Overflow answer](https://stackoverflow.com/a/64032172/4178189))
* [yardanico](https://github.com/yardanico) for being the first contributor and great sponsor of this library, even before an official release
* [vindaar](https://github.com/Vindaar),
  [hugogranstrom](https://github.com/HugoGranstrom)
  for their contributions towards version 0.2.

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



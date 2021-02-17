# nimib 🐳

nim 👑 driven ⛵ publishing ✍

🚧 working towards a 0.1 release 🚧

* [repository](https://github.com/pietroppeter/nimib)
* [documentation](https://pietroppeter.github.io/nimib)

<!--brief overview mentioning
- overview of use cases, features, workflows
- design philosophy (simple API, sane defaults, easy customization, nim all the way)
-->

## 👋 🌍 Example Usage

First have a look at the following html document: [hello](https://pietroppeter.github.io/nimib/hello.html)

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
    ## classified by NSA as <a href="https://www.nsa.gov/Portals/70/documents/news-features/declassified-documents/cryptologic-histories/EC-121.pdf">TOP SECRET</a>
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

<!--TODO
Note the following:

  * the code that appears in the

### Try it!

*TODO*
-->

### Other examples of usage

in this repo:

* [index](https://pietroppeter.github.io/nimib/index.html): generate an HTML and a README.md at the same time (you are reading one of the two)
* [penguins](https://pietroppeter.github.io/nimib/penguins.html): explore palmer penguins dataset using ggplotnim (example of showing images)
* [numerical](https://pietroppeter.github.io/nimib/numerical.html): example usage of NumericalNim (example of custom style, usage of latex)
* [cheatsheet](https://pietroppeter.github.io/nimib/cheatsheet.html): markdown cheatsheet (example of a custom block, custom highlighting and a simple TOC)
* [mostaccio](https://pietroppeter.github.io/nimib/mostaccio.html): examples of usage of nim-mustache
* [ptest](https://pietroppeter.github.io/nimib/ptest.html): print testing for nimib

elsewhere:

* [adventofnim](https://pietroppeter.github.io/adventofnim/index.html): solutions for advent of code in nim

## API

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

other templates on top of the four basic ones will likely be added.

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
<!-- change nbBlock.body to nbBlock.code? -->

Here are two examples that show how to abuse the internal api:

* [nolan](https://pietroppeter.github.io/nimib/nolan.html): how to mess up the timeline of blocks ⏳
* [pythno](https://pietroppeter.github.io/nimib/pythno.html): a reminder that nim is not python 😜

<!--
### extending the api

*TODO*

-->

## Rendering

### html rendering

There are two levels of html rendering.

1. **render-in-the-small**: rendering html fragments. This is mostly taken care by nim-markdown
   and by appropriate semantic tagging in render functions (this can be overriden).
2. **render-in-the-large***: putting together html fragments and other elements to publish one or more documents.
   this is delegated to nim-mustache and to manual creation and update of json and context fields in doc and block objects.

### markdown rendering

For an example on how to output Markdown see [docs/index.nim](https://github.com/pietroppeter/nimib/blob/main/docs/index.nim),
which automatically renders the `README.md` in the repo.

## Other features

### styling

Default style is provided by [water.css](https://watercss.kognise.dev/).
Style can be customized.

### code highlighting

Code highlighting is provided by [highlight.js](https://highlightjs.org/).
The script `docs/static/highlight.nim.js` contains highlighting assets only for nim language.
The default css style for highlighting is `docs/static/atom-one-light.css`.

If you want to change the style pick one using [highlight demo page](https://highlightjs.org/static/demo/)
(select all languages to find Nim) and make the appropriate change in `templates/head.mustache`.

### latex

Rendering latex expressions is an opt-in feature provided by [katex](https://katex.org/).
The delimiter supported are `$` for inline-math and `$$` for display math.
Latex is rendered through an autodetection during document loading.

<!--
## static assets

*TODO*

## filesystem

*TODO*

default situation for single article that does not access filesystem:

* you do not have to worry about nothing.
  the new html will appear next to your nim file with same name and html extension

if you need to change name or location of html output, or if you need to access
filesystem (in particular if you need it for your web assets), this is what you need to know:

* with nbInit a number of paths are initialized
* we follow compiler/pathutils which is available (exported) from nim paths.
  (along with os stuff also exported)
* nbThisFilename (string): name of this file (with nim extension).
* nbThisDir (RelativeDir): directory where this nim file resides
* nbThisFile (RelativeFile): this should be a template that gives nbThisDir + nbThisFilename
* npProjectDir (AbsoluteDir): the reference directory for the project.
  looks for a nimble file starting from nbThisDir in parent dirs.
  This should be the only Absolute path,
  all other paths should be relative to this path.
* nbProjectFile (RelativeFile): path (and also name since it is
  relative to the nbProjectDir) of the nimble file found as reference for the project.
  (what happens if multiple nimble files are found?)
* nbCurDir (RelativeDir): template that returns current directory.
  it should be set at the beginning as equal to nbProjectDir (with change of directory).
* nbDoc.dir (RelativeDir): this is directory where the specific nbDoc
  (there can be more than on) will be written to. Defaults to nbThisDir.
* nbDoc.filename (string): name of the output document *without extension*
  (default: nbThisFilename removing nim extension). or maybe with extension??
  should I add some magic in order to have a change of filename to check
  if it has extension and add it automatically?
* nbDoc.ext (string): extension (default: html)
* nbDoc.file (RelativeFile): nbDoc.dir + nbDoc.filename + nbDoc.ext
* the above fields of nbDoc become then an API that should be guaranteed for NbDoc object.

other thoughts

- should I add a Filename and Ext distinct string to pathutils?
- since I never remember which slash should I use maybe I could introduce
a +/- operator that work on this distinct strings
- also I should introduce readfile, writefile for this type of objects.

## Roadmap

focus for 0.2:

- use it and fix stuff around
- expand features for blogging use case
- clean up API and improve implementation (especially for NbBlock and rendering)

later on:

- more features to build static sites (other than blogging, for example library documentation or mdbook)
- interactivity of documents, e.g. a dahsboard (possibly taking advantage of nim js backend)
- nimib executable for scaffolding and to support different publishing workflows
- possibility of editing document in the browser (similar to jupyter UI, not necessarily taking advantage of hot code reloading)
- dynamic sites (streamlit style? take advantage of caching instead of hot code reloading)


## Thanks

to:

* soasme for the excellent libraries nim-markdown and nim-mustache, which provide the backbone of nimib rendering and customization
* clonk for help in a critical piece of code early on (see SO question)
* baf03 for tempfile, which elegantly fills a stdlib gap

-->

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



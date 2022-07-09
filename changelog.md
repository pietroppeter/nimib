
# Changelog

The changelog includes a bit of the early history of nimib, pointers to relevant
examples of usage of nimib and heartfelt thanks to some of the fine folks that
made this development possible.

When contributing a fix, feature or example please add a new line to briefly explain the changes. It will be used as release documentation here: https://github.com/pietroppeter/nimib/releases

## 0.3.x

* _insert here next change_

## 0.3

## 0.2.x

### 0.2.4

### 0.2.3

### 0.2.2

### 0.2.1

## 0.2 "Theme Maker" (November 2021)

this release aims to simplify creating Nimib themes such as nimibook.

It does this through the following changes:
* instead of creating and injecting multiple variables
  (`nbDoc`, `nbBlock`, `nbHomeDir`, ...), nimib now only injects a `nb` variable
  that is a `NbDoc`. Some aliases are provided to minimize breakage.
* handling of paths (`srcDir` and `homeDir`) is changed and is based on the presence
  of a new config file `nimib.toml`
* command line options are now processed and can be used to skip/override the config process.
  Run any nimib file with option `--nbHelp` to see available options.
* note in particular new `--nbShow` option which will automatically open the file in your default browser.
* `nbPostInit` and `nbPreSave` customization mechanism based on includes are now removed 
* documentation has been updated to reflect the above changes and also to add other Nimib references (NimConf video, nimibook, getting-started, ...)
most of the changes break the api

relevant external example:

* [norm](https://norm.nim.town) starts to use nimibook for its documentation

Special thanks again to to @Vindaar, @Clonkk and @HugoGranstrom

## 0.1.x (March-June 2021)

a growing ecosystem drives most of the development of the 0.1.x series:

* [intro to binarylang](https://ajusa.github.io/binarylang-fun/intro.html) by @ajusa (March 2021): first public use of nimib by someone other than @pietroppeter 
* [SciNim Getting Started](https://scinim.github.io/getting-started/) decided to use nimib and for that purpose
  [nimibook](https://github.com/pietroppeter/nimibook), a book theme (based of mdbook) developments was started
* [nblog](https://github.com/pietroppeter/nblog), a nimib blog, was started as a way to use nimib to explore nim ecosystem and experiment
  the various features of nimib
* [nimiboost](https://github.com/HugoGranstrom/nimiBoost) is a vs code extension to provide
  markdown highlighting and a preview mechanism.

changes:

*  0.1.1:
  - add nbPostInit mechanism to customize document (#32)
  - fix (breaking): code output is escaped by default
  - fix (breaking): code output is not stripped anymore
  - fix: nbDoc.write will create directories if not existing (#44)
* 0.1.2: release to align tag and nimble version
* 0.1.3: added compile-time switches to override nbHomeDir (#53)
* 0.1.4: fix for `nbImage` path (#56)
* 0.1.5: new template `nbCodeInBlock` (#59)
* 0.1.6: added `nimib / boost` module with `md` and `fmd` helpers to support markdown highlight with nimiboost

Thanks for this release series to @Vindaar, @Clonkk and @HugoGranstrom who decided to adopt
nimib in scinim/getting-started and motivated and directly contributed to nimib and nimibook development
to support this use case.

## 0.1 (March 2021)

* initial version with essential templates `nbInit`, `nbText`, `nbCode`, `nbImage`, `nbSave`
  - capture of output in `nbCode` based on code by @Clonkk
* html backend based on mustache and markdown by @soasme
* default theme using water.css
  - header with home button, minimal title (filename by default), automatic detection of github repo
  - footer with "made with nimib" and Show Source button
* static highlighting of nim code (by @yardanico)
* latex rendering through katex
* markdown backend
* essential documentation in `index.nim`
  - sections: intro, example usage, features, api, roadmap, thanks, Q&A
  - also generates `README.md` and serves as an example of usage of markdown backend
* possibility to customize theme (dark mode, custom stylesheet, add other scripts, ...)
* example documents:
  - `penguins`: data exploration, adding images
  - `numerical`: latex usage, theme customization
  - `cheatsheet`: toc creation, new text block which shows source, custom highlighting
    - also documents the markdown to html generator
  - `mostaccio`: example of using dark mode
    - also documents the templating system mustache
  - `ptest`: print testing for nimib
* deployed using github pages. html files committed in repo.

relevant external examples:

* adventofnim (2020) by @pietroppeter
  - first appeareance of nimib in public (before 0.1 release), see [commit on Dec 1st, 2020](https://github.com/pietroppeter/adventofnim/commit/973f9a2472d41188bb37650c082f115fc5787687#diff-a21a437c51bd7babb945c8291588853296387c7e1950997e05f1eb62d18b54f7)

Initial commit of nimib was on Nov, 25, 2020.
On the same day the [first milestone](https://github.com/pietroppeter/nimib/commit/b02ec7be4663956167701a81a96246d8e528fff3)
reached was the working hello world example.

For this release, thanks to:

* [soasme](https://github.com/soasme) for the excellent libraries nim-markdown and nim-mustache, which provide the backbone of nimib rendering and customization
* [Clonkk](https://github.com/Clonkk) for help in a critical piece of code early on (see [this Stack Overflow answer](https://stackoverflow.com/a/64032172/4178189))
* [yardanico](https://github.com/yardanico) for being the first contributor and great sponsor of this library, even before an official release

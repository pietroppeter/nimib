---
name: nimib
description: Write, edit, build and debug nimib documents, the Nim library that turns a Nim file into an HTML (or Markdown) page mixing text, code and its output (nbInit, nbText, nbCode, nbSave). Use it whenever the user wants a Nim notebook, tutorial, blog post, report, README or explorable explanation built from Nim code, mentions nimib or any nb* template (nbImage, nbJsFromCode, nbKaraxCode, newNbBlock, nimib.toml), wants interactive widgets compiled from Nim to JS in a page, or needs to fix a nimib document that does not compile or renders wrong, even if they never say "nimib".
---

# nimib

nimib (🐳) turns a normal Nim program into a document. Each `nb*` call appends a
*block* to a document object; `nbSave` renders the blocks to HTML (or Markdown)
and writes the file. Code inside `nbCode:` is real Nim code: it is compiled with
the rest of the file, runs when the program runs, and its `echo` output is
captured and shown under the code.

This skill targets **nimib 0.4.x** (current: 0.4.3, Nim >= 2.0 recommended).
nimib 0.4 rewrote the block and rendering system: there are no mustache
templates any more, and the README section on custom blocks still describes the
old 0.3 API (`newNbSlimBlock`, `newNbCodeBlock`, `nb.partials`) that **no longer
exists**. When you remember an API from training data, check it against
`references/api.md` before using it.

## Workflow

1. **Check the toolchain** (once per environment):
   `nim -v`, then `nimble path nimib` (or `ls ~/.nimble/pkgs2 | grep nimib`).
   If nimib is missing: `nimble install -y nimib`. On Linux the markdown
   renderer needs PCRE at runtime (`libpcre.so.3`); if a document fails with
   `could not load: libpcre.so(.3|.1|)`, install `libpcre3`. No Nim at all, or
   no network to nim-lang.org? See `references/setup.md`.
2. **Write the document** as a `.nim` file (skeleton below). Use plain
   `nbCode` for code the reader should see run, `nbText` for markdown prose.
3. **Build it**: `nim r --hints:off -d:nimibQuiet path/to/doc.nim`.
   This compiles, runs, and writes `doc.html` next to the source (when there is
   no `nimib.toml`; see "Where the HTML goes").
4. **Verify the output, don't assume it**: run
   `python3 <this-skill>/scripts/nbcheck.py path/to/doc.nim`. It builds the
   document, finds the HTML, and reports blocks, outputs and common rendering
   mistakes (markdown that became a code block, raw `**`/`#` left in text, empty
   outputs, the default title, missing local images). Fix what it flags and
   rebuild. A document that compiles can still render badly; the check is what
   tells you.

## Skeleton

```nim
import std/[strformat, strutils]   # whatever the code needs
import nimib

nbInit                # creates `nb`, reads nimib.toml and --nb* options
nb.title = "Counting words"   # default title is the file path

nbText: """
# Counting words
We split a sentence and count the words.
"""

nbCode:
  let sentence = "the quick brown fox jumps over the lazy dog"
  let words = sentence.splitWhitespace
  echo words.len

nbText: &"The sentence has **{words.len}** words."   # variables from nbCode are in scope

nbSave                # render and write the file (always last)
```

Everything defined inside `nbCode` lives at module top level, so later blocks
(and `nbText` with `&"..."`/`fmt"..."`) can use it.

## Core blocks (cheat sheet)

| Block | Use |
|---|---|
| `nbText: """markdown"""` | prose, GitHub-flavoured markdown (nim-markdown) |
| `nbCode: ...` | show code, run it, show captured stdout |
| `nbCodeSkip: ...` | show code without compiling or running it (must contain at least one statement) |
| `nbCodeInBlock: ...` | like `nbCode` but in a `block:` scope, so names can be reused |
| `nbCapture: ...` | run code, show only its output |
| `nbTextWithCode: fmt"..."` | text that also stores the producing code in `nb.blk.code` |
| `nbImage(url, caption = "", alt = "", width = "", height = "")` | figure with caption |
| `nbVideo(url, ...)`, `nbAudio(url, ...)` | media (`autoplay`, `muted`, `loop`) |
| `nbFile(name, content)` / `nbFile(name): code` / `nbFile(name)` | write a file and show it / show an existing file |
| `nbRawHtml: "<div>...</div>"` | raw html |
| `nbShow(obj)` | render any value that has a `toHtml(obj): string` proc |
| `nbDiv(classes, styles): ...` | wrap nested blocks in a `<div>` |
| `nbClearOutput` | clear the output of the previous code block |
| `nimibCode: ...` | show nimib code itself (the nb calls) and run it; for docs about nimib |
| `nbJsFromCode`, `nbKaraxCode`, ... | Nim compiled to JavaScript in the page: `references/interactivity.md` |

Document-level switches, called after `nbInit`: `nb.title = "..."`,
`nb.darkMode`, `nb.useLatex` (then `$...$` and `$$...$$` in `nbText`),
`nb.disableHighlightJs`. Everything else (head, header, footer, styles) is in
`nb.doc.context` (a `JsonNode`) and `nb.backend.partials`; see
`references/custom-blocks.md`.

## Writing good nimib documents

- **Let the code produce the numbers.** The point of nimib is that text and
  results cannot drift apart: compute in `nbCode`, then interpolate with
  `&"..."` (or `hlMdF"""..."""`, see below) instead of retyping values.
- **Small blocks, prose in between.** A reader follows a document like a
  notebook: one idea per `nbCode`, a sentence or two of `nbText` explaining
  what happens and what the output shows.
- **Echo what matters.** Only stdout is captured. Values that are not echoed
  do not appear. Avoid huge outputs (use `nbClearOutput`, or echo a summary).
- **Markdown indentation**: lines in `nbText` indented 4+ spaces become a code
  block (standard markdown). Keep text flush left or indented less than 4.
- **Interpolation and braces**: with `&"..."`/`fmt"..."`, literal `{` and `}`
  must be doubled (`{{`, `}}`). LaTeX like `e^{i\pi}` inside a `fmt` string
  needs `e^{{i\pi}}`. Prefer a non-interpolated string for LaTeX-heavy text.
- **Syntax-highlighting helpers** for the NimiBoost VS Code extension:
  `hlMd"""..."""` (markdown, no-op) and `hlMdF"""..."""` (markdown with `&`
  interpolation); also `hlPy`, `hlHtml`, `hlNim` and their `F` variants. They
  are plain strings at runtime, so using them is always safe.
- **Reusing names**: two `nbCode` blocks cannot both declare `let x`; use
  `nbCodeInBlock` or different names.
- **Show code without running it** (`nbCodeSkip`) only for code that cannot
  run (pseudo-code, infinite loops, errors on purpose). Everything else should
  run so the document proves itself.
- Templates that call `nbCode` work (code is read from the source file); a
  doc-wide helper template is a good way to repeat a pattern.

## Where the HTML goes (and why images break)

Without a `nimib.toml`, the output is written **next to the source file**,
named after it (`doc.nim` → `doc.html`), from whatever directory you run.
`--nbFilename:other.html` renames it; `--nbShow` opens it in a browser.

nimib looks for `nimib.toml` in the **current working directory and its
parents** (not the source file's directory). A config like

```toml
[nimib]
srcDir = "docsrc"   # where sources live (relative to the toml)
homeDir = "docs"    # where outputs go; it becomes the current dir at runtime
```

mirrors `docsrc/a/b.nim` to `docs/a/b.html`, and the program runs with
`docs/` as current directory (so relative file reads/writes in `nbCode` are
relative to `docs/`). Local URLs passed to `nbImage`/`nbVideo`/`nbAudio` are
treated as relative to the **root** (`srcDir`, or the working directory when
there is no config) and rewritten relative to the output page. So:

- With no config, run from the directory that holds the document and its
  images (`cd docs && nim r doc.nim`), or the image links will point elsewhere.
- For a site, add `nimib.toml` and put images under `homeDir`, referenced from
  the root (`nbImage("images/whale.png")`).
- Absolute URLs (`https://...`) are left untouched.

Details, command-line options and multi-document sites: `references/config-and-paths.md`.

## Markdown output (README from Nim)

Both files from one run (simplest when the user wants "README.md and an
html page"):

```nim
import nimib

nbInit
nbText: "# mylib\nA tiny library."
nbCode:
  echo "1 + 1 = ", 1 + 1
nbSave                         # readme.html, default theme

nb.useMdBackend()              # same blocks, Markdown renderer, no theme
nb.doc.filename = "README.md"  # the default would be readme.md
nbSave
```

Or one output per build, as nimib's own README (from `docsrc/index.nim`):
`when defined(mdOutput): nbInitMd else: nbInit`, then
`nim r -d:mdOutput doc.nim`. `nbInitMd` names the file after the source
(`readme.nim` gives `readme.md`, which GitHub does not show as the repo
README on case-sensitive checkouts), so pass `--nbFilename:README.md` or set
`nb.doc.filename`. `nbImage` width/height are ignored in Markdown.

## When things go wrong

Read `references/troubleshooting.md`: it maps the common compiler/runtime
errors (`undeclared identifier: 'nb'`, redefinition errors, `could not load:
libpcre`, js compilation failed, capture errors, `newNbSlimBlock` undeclared,
blank output, wrong image paths) to fixes.

## Reference files (read when needed)

- `references/api.md`: every public template/proc with signatures, the `Nb`/`NbDoc` objects, runtime options, define flags.
- `references/interactivity.md`: `nbJsFromCode` family, variable capture, `nbKaraxCode`, `nbHappyxCode`, `nbCodeDisplay`/`nbCodeAnd`.
- `references/custom-blocks.md`: defining blocks with `newNbBlock`, container blocks, overriding partials, themes, the Markdown/JSON backends, migrating 0.3 code.
- `references/config-and-paths.md`: `nimib.toml`, `srcDir`/`homeDir`, output paths, CLI options, publishing to GitHub Pages.
- `references/setup.md`: installing Nim and nimib (choosenim, PyPI `nimlang`, nightlies, offline/proxied environments).
- `references/troubleshooting.md`: errors and fixes.
- `examples/`: small documents that are compiled in CI against nimib main (copy them as starting points).
- Ecosystem: nimibook (books, see the `nimibook` skill), NimiSlides (reveal.js slides, `HugoGranstrom/nimiSlides`, ported to nimib 0.4), nimibex (extra blocks such as chat bubbles, `nimib-land/nimibex`), nimib.py (experimental Python port).

---
name: nimibook
description: Create, extend, build and publish nimibook books (mdBook-style sites whose chapters are nimib documents or Markdown files, with a sidebar table of contents). Use it whenever the user wants documentation, a tutorial series, a course or a book for a Nim project, mentions nimibook, nbook.nim, initBookWithToc, nimibookCli, `nim r nbook build`, or wants to add chapters, fix the table of contents, change book themes/config, or deploy the book to GitHub Pages.
---

# nimibook

nimibook is a port of mdBook to Nim on top of nimib. A book is:

- a `nbook.nim` program that declares the table of contents (TOC) and calls
  `nimibookCli(book)`; running it with a command (`init`, `build`, ...) manages the book;
- a `nimib.toml` with `[nimib]` (`srcDir` sources, `homeDir` output) and
  `[nimibook]` (title, description, repo link...);
- chapters in `srcDir`: `.md` files (rendered as markdown) or `.nim` nimib
  documents that use `nbInit(theme = useNimibook)`;
- the built site in `homeDir` (default `docs/`, ready for GitHub Pages),
  including vendored assets (`docs/assets`) and `book.json` (the TOC that
  every page reads to draw the sidebar).

Versions: nimibook **0.4.0** requires nimib **>= 0.4.1** and Nim >= 2.0.
nimibook 0.3.x pairs with nimib 0.3.x. If a build fails inside nimibook's
own code, check `nimble path nimib nimibook` first. For writing the content
of `.nim` chapters (nbText, nbCode, images, interactivity), use the `nimib`
skill: chapters are ordinary nimib documents with a different theme.

## Create a book

```sh
nimble install -y nimibook          # pulls nimib too
mkdir mybook && cd mybook
```

`nbook.nim`:

```nim
import nimibook

var book = initBookWithToc:
  entry("Introduction", "index.md", numbered = false)   # book/index.md
  entry("Getting started", "getting_started.nim")       # book/getting_started.nim
  section("Guide", "guide/index.md"):                   # book/guide/index.md, and children go in book/guide/
    entry("Basics", "basics.nim")                       # book/guide/basics.nim
    entry("Advanced", "advanced")                       # no extension: .nim is assumed
    draft("Coming soon")                                # listed, greyed out, no file
  entry("Appendix", "appendix.md")                      # back at top level: book/appendix.md

nimibookCli(book)
```

Then:

```sh
nim r nbook init     # writes nimib.toml (if missing), docs/assets, and a stub for every missing source
nim r nbook build    # builds every chapter into docs/ (and runs check)
```

Open `docs/index.html`. `init` never overwrites existing files, so it is
also the way to create stubs after adding TOC entries.

## TOC DSL rules

- `entry(title, path, numbered = true)`: path relative to `srcDir` (plus the
  folder of the enclosing sections). `.nim` is assumed when there is no
  extension. Output is the same relative path with `.html`.
- `section(title, path): body`: an entry with children. **The directory of
  `path` becomes the base folder for the children**: `section("Guide",
  "guide/index.md")` puts `entry("Basics", "basics.nim")` at
  `guide/basics.nim`. Use `section("Guide", "guide.md")` to keep children in
  the parent folder.
- `draft(title)`: placeholder in the TOC, no file, skipped by build/check.
- Numbering is automatic (1., 1.1., 2. ...); `numbered = false` for prefaces.
- Only `.nim` and `.md` sources are supported.

## Chapter templates

A `.nim` chapter (this is what `init` generates):

```nim
import nimib, nimibook

nbInit(theme = useNimibook)
nbText: "## Getting started"
nbCode:
  echo "chapters are nimib documents"
nbSave
```

- Always `nbInit(theme = useNimibook)`; a plain `nbInit` produces a page
  without the book layout. (`nbUseNimibook` was removed in 0.3.)
- `nb.useLatex` per chapter for KaTeX; `nb.doc.context["mathjax_support"] = %true`
  (with `import std/json`) for MathJax instead.
- Paths: during `build`, each chapter runs as `nim r book/chapter.nim` from the
  book root, and nimib then switches the current directory to `homeDir`
  (`docs/`). Images referenced with `nbImage` should live under `docs/` and
  be given relative to the book root (`nbImage("images/diagram.png")` for
  `docs/images/diagram.png`).
- `.md` chapters: plain markdown, rendered with the same theme (no code runs).

## Commands

```
init   : create nimib.toml, docs/assets, stub sources for TOC entries (never overwrites)
build  : build all chapters (in parallel), then fail if any failed; extra args go to `nim r`
dump   : write docs/book.json (needed to build a single chapter by hand)
check  : verify every non-draft entry has a source and an output
clean  : remove generated files from docs/ (keeps assets/)
update : re-copy assets (after upgrading nimibook)
```

- `nim r nbook build -d:release --hints:off` passes options to every chapter compile.
- When a chapter fails, a `<chapter>.log` with the compiler/runtime output is
  written next to its source and the error is printed. Read it, fix, rebuild.
- Iterating on one chapter: `nim r nbook dump` once, then
  `nim r book/getting_started.nim` (add `--nbShow` to open it). The sidebar
  comes from `docs/book.json`, so re-dump after changing the TOC.
- Serial builds: compile nbook with `-d:nimibParallelBuild=false`; cap
  parallelism with `-d:nimibMaxProcesses=4`.
- A `nimble` task is the usual entry point (`task genbook: selfExec("r nbook.nim init"); selfExec("r nbook.nim build")`).

## Configuration (`nimib.toml`)

```toml
[nimib]
srcDir = "book"
homeDir = "docs"

[nimibook]
title = "My Library"
description = "Docs for My Library"
language = "en-us"
git_repository_url = "https://github.com/me/mylib"   # adds a repo icon link
default_theme = "light"            # light, rust, coal, navy, ayu
preferred_dark_theme = "navy"      # used when the browser prefers dark
# git_repository_icon = "fa-github"
# plausible_analytics_url = "me.github.io/mylib"
# favicon_escaped = '<link rel="icon" href="...">'
```

All `[nimibook]` fields are optional (defaults: title "My book", light/navy
themes, whale favicon). `srcDir`/`homeDir` default to `book`/`docs` when
there is no toml.

## Verify the build

Don't stop at "build printed no error":

1. `nim r nbook check` prints `check book: OK` only if every entry has a source and an output.
2. Run `python3 <this-skill>/scripts/bookcheck.py` from the book root: it
   reads `docs/book.json`, checks every page exists, contains the sidebar with
   all TOC titles, has prev/next links where expected, and reports chapters
   whose content area is empty and `.log` files left by failed builds.
3. For a chapter with code, open its html and check that the outputs are there
   (or run the nimib skill's `nbcheck.py --html docs/chapter.html`).

## Publishing (GitHub Pages)

nimibook's own workflow, adapted:

```yaml
on:
  push:
    branches: [main]
jobs:
  book:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@v4
      - run: sudo apt-get install -y libpcre3
      - uses: jiro4989/setup-nim-action@v2
        with:
          nim-version: stable
      - run: nimble install -y nimibook   # or `nimble install -y` if the repo has a .nimble requiring it
      - run: nim r nbook init && nim r nbook build
      - uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: docs
```

Commit `nbook.nim`, `nimib.toml`, `book/`; usually ignore `docs/*.html` and
`book/*.log` (nimibook's own repo ignores html in the source folder).
PR previews: nimibex uses `rossjrw/pr-preview-action` on gh-pages (no
secrets); nimib and nimibook use a Netlify preview split into a build
workflow and a `workflow_run` deploy workflow.

## Common problems

| Symptom | Fix |
|---|---|
| Chapter renders without sidebar/theme | use `nbInit(theme = useNimibook)` and `import nimibook` |
| `[nimibook.warning] No book json was found` when building one chapter | run `nim r nbook dump` first |
| `check` reports missing sources | run `nim r nbook init` to create stubs, or fix the path (remember section folders) |
| A chapter fails only during `build` | read `book/<chapter>.log`; remember chapters run with cwd = `docs/` |
| Errors about mustache/partials/`nbUseNimibook` | old nimibook/nimib mix or 0.3-era code: upgrade both to 0.4 and use the 0.4 APIs |
| Assets (css/fonts) missing or outdated | `nim r nbook update` |
| `could not load: libpcre` | install libpcre3 (see the nimib skill's setup reference) |
| Links to the next page go to a draft | known issue (#76) when the last chapter is a draft; reorder or remove the draft |

nimibook internals for contributors: `src/readme.md` in the repo is the code
guide; `src/nimibook/themes.nim` holds the theme partials (rewritten from
mustache to nimib 0.4 partial procs in 0.4.0).

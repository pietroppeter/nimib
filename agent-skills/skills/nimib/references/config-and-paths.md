# Configuration, paths and publishing

## How nimib decides paths

At `nbInit`:

1. `initDir` = current working directory.
2. Options are parsed (`--nb*`, see api.md).
3. `nimib.toml` is searched in the **current directory and its parents**
   (not the source file's directory). Its directory is `cfgDir`. With
   `--nbSkipCfg`, or when no file is found, the defaults are
   `cfgDir = initDir`, `srcDir = "."`, `homeDir = "."`.
4. `srcDir` and `homeDir` from the `[nimib]` table (or `--nbSrcDir`,
   `--nbHomeDir`) are relative to `cfgDir` unless absolute.
5. Output filename = `<path of the source dir relative to srcDir>/<name>.html`
   (or `--nbFilename`). With the defaults this is "next to the source file".
6. If `homeDir` is set, nimib creates it and `setCurrentDir(homeDir)`. The
   file is written relative to it. **Your document's code also runs with
   `homeDir` as current directory**, so `readFile("data.csv")` in `nbCode` is
   relative to `homeDir`. Use `nb.doc.srcDir`, `nb.doc.thisDir` (typed
   `AbsoluteDir`) to reach files next to the sources:
   `readFile((nb.doc.thisDir / "data.csv".RelativeFile).string)`.

`path_to_root` (in `nb.doc.context`) is the relative path from the page to
`srcDir`'s mirror in the output; relative urls given to `nbImage`, `nbVideo`,
`nbAudio` are prefixed with it (`relToRoot`). So media urls are written
"as seen from the root of the site".

## Typical layouts

**Single document, no config**: `doc.nim` → `doc.html` next to it. Run from
the document's directory if it shows local images.

**Site / docs folder** (nimib's own repo):

```
nimib.toml        [nimib]  srcDir = "docsrc"  homeDir = "docs"
docsrc/index.nim  -> docs/index.html
docsrc/far/from/home.nim -> docs/far/from/home.html
docs/images/...   referenced as nbImage("images/x.png") from any page
```

Build each page from the repo root: `nim r docsrc/index.nim`. A `nimble`
task looping over the files is the usual "build all" (nimib's `nimble docs`).

**Book**: use nimibook (separate skill); it reads the same `[nimib]` table
plus a `[nimibook]` table.

## Extra configuration in nimib.toml

Other tables are free for your own use; read them with:

```nim
import nimib/config   # loadTomlSection
type MySite = object
  author: string
let site = loadTomlSection(nb.doc.rawCfg, "mysite", MySite)
```

## Command-line options, quickly

`nim r doc.nim --nbShow` opens the page, `--nbFilename:x.html` renames,
`--nbHomeDir:out` writes elsewhere, `--nbSkipCfg` ignores a toml found in a
parent folder (useful when a doc lives inside a repo that has an unrelated
`nimib.toml`), `--nbHelp` lists options.

## Gitignore

Built html is often committed for GitHub Pages; if not, ignore `*.html` in the
source folder. nimib also writes `js_file_nbCodeToJs_*.nim` temporarily for
nbJs blocks (removed on success).

## Publishing on GitHub Pages

Build in CI and publish the output folder. The pattern used by nimib and
nimibook:

```yaml
on:
  push:
    branches: [main]
jobs:
  gh-pages:
    runs-on: ubuntu-24.04            # libpcre3 is packaged here
    steps:
      - uses: actions/checkout@v4
      - run: sudo apt-get install -y libpcre3
      - uses: jiro4989/setup-nim-action@v2
        with:
          nim-version: stable
      - run: nimble install -y        # or: nimble install -y nimib
      - run: nim r --hints:off docsrc/index.nim   # build every page
      - uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: docs
```

Then set Pages to serve the `gh-pages` branch. nimib and nimibook also run a
Netlify deploy preview for PRs (`netlify_build_docs.yml` builds and uploads
the folder as an artifact, `netlify_deploy_preview.yml` deploys it from a
`workflow_run`, so PR code never sees the Netlify secrets).

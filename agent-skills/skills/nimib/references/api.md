# nimib 0.4 API reference

Taken from the nimib 0.4.3 sources (`src/nimib.nim`, `src/nimib/builtinBlocks.nim`,
`src/nimib/types.nim`, `src/nimib/themes.nim`). Every `nbXxx` template has a
method form `nb.xxx(...)` that takes the `Nb` object explicitly (handy in
procs/templates that receive `nb`).

## Contents
1. Document lifecycle
2. Text and code blocks
3. Media, files, html
4. Layout and output helpers
5. Interactivity (summary)
6. Document switches and context
7. The `Nb` and `NbDoc` objects
8. Runtime options (`--nb*`)
9. Define flags (`-d:`)
10. Things that do not exist (any more)

## 1. Document lifecycle

```nim
template nbInit*(theme: proc (nb: var Nb) = themes.useDefault,
                 renderer: NbRender = nbToHtml, thisFileRel = "")
template nbInitMd*(thisFileRel = "")   # Markdown backend, no theme, output .md
template nbSave*                        # compile nbJs code, render, write; `--nbShow` opens it
template nbShow*                        # (no args) nbSave + open in browser; prefer `--nbShow`
```

- `nbInit` injects `var nb: Nb` at the call site. Call it once, at top level,
  before any other `nb*` call. It loads options and `nimib.toml`, reads the
  source file (used for code capture and the "Show Source" button), computes
  the output filename, may `setCurrentDir` to `homeDir`, and applies the theme.
- `thisFileRel` is for tools that build a document on behalf of another file
  (nimibook uses it for `.md` chapters).
- Custom theme: `nbInit(theme = myTheme)` where `proc myTheme(nb: var Nb)`
  (usually calls `useDefault nb` first, then changes context/partials).
  `themes.noTheme` renders only the blocks.

## 2. Text and code blocks

```nim
template nbText*(ttext: string)                    # markdown -> html
template nbTextWithCode*(body: untyped)            # body evaluates to a string; code kept in nb.blk.code
template nbCode*(body: untyped)                    # show + run + capture stdout
template nbCodeSkip*(body: untyped)                # show only (not compiled)
template nbCodeInBlock*(body: untyped)             # nbCode inside `block:`
template nbCapture*(body: untyped)                 # run, show only output
template nimibCode*(body: untyped)                 # same as nbCode; idiom for showing nimib calls
template nbClearOutput*()                          # previous NbCode block output = ""
template nbCodeDisplay*(tmplCall, body: untyped)   # call tmplCall: body, then show body (nbCodeSkip)
template nbCodeAnd*(tmplCall, body: untyped)       # nbCode: body, then tmplCall: body
```

- Code shown is read from the source file exactly as written (comments
  included). With `-d:nimibCodeFromAst` it is regenerated from the AST instead
  (old behaviour: normal comments are lost).
- Output is the captured stdout (echo, stdout.write). stderr is not captured.
- Block objects: `NbText(text)`, `NbCode(code, output, blocks)`,
  `NbTextWithCode(text, code)`. After a call, `nb.blk` is the block just added,
  so you can patch it: `nb.blk.NbCode.code = readFile("example.nim")` (a common
  trick to display a file as highlighted Nim with a `nbCode: discard`).

## 3. Media, files, html

```nim
template nbImage*(url: string, caption = "", alt = "", width = "", height = "")
template nbVideo*(url: string, filetype = "", autoplay = false, muted = false, loop = false)
template nbAudio*(url: string, filetype = "", autoplay = false, muted = false, loop = false)
template nbFile*(name: string, content: string)    # write file + show content
template nbFile*(name: string, body: untyped)      # write code block to file + show
template nbFile*(name: string)                     # read existing file + show
template nbRawHtml*(content: string)
template nbShow*(obj: untyped)                     # nbRawHtml(obj.toHtml())
```

- `nbImage`: `alt` defaults to `caption`; `width`/`height` go verbatim into the
  html attributes (`"300"`, `"50%"`), ignored by the Markdown backend. Renders
  `<figure><img ...><figcaption>caption</figcaption></figure>`.
- Media urls that are relative are interpreted relative to the root and
  rewritten (`relToRoot`) relative to the page; see config-and-paths.md.
- `nbVideo`/`nbAudio` infer `filetype` from the extension (`video/mp4`).
- `nbFile` writes relative to the current directory (which is `homeDir` when a
  config sets one). Highlighting language comes from the extension.
- `nbShow` works with any type that has `proc toHtml(x: T): string`, e.g. a
  datamancer `DataFrame`.

## 4. Layout and output helpers

```nim
template nbDiv*(classes: string, styles: string, body: untyped)  # container <div class style>
template nbDiv*(body: untyped)
proc relPath*(path: AbsoluteFile | AbsoluteDir): string  # path relative to homeDir (template)
```

`nbDiv` is a container: blocks created inside its body are nested in it.

Python (only when `nimpy` is installed): `nbInitPython()` then
`nbPython: hlPy"""print(1)"""` runs Python code and captures its output.

## 5. Interactivity (summary)

`nbJsFromCode`, `nbJsFromCodeInBlock`, `nbJsFromCodeGlobal`,
`nbJsFromCodeOwnFile`, `nbJsFromString`, `nbKaraxCode` (needs `karax`),
`nbHappyxCode` (needs `happyx`). See interactivity.md.

## 6. Document switches and context

```nim
nb.title = "My title"     # <title> and header; default is the relative path of the file
nb.darkMode               # water.css dark + androidstudio highlight
nb.useLatex               # KaTeX auto-render, delimiters $...$ and $$...$$
nb.disableHighlightJs     # no client-side highlight.js (affects ``` blocks in nbText)
```

`nb.doc.context` is a `JsonNode` with the values the default theme reads:
`title`, `stylesheet`, `highlight`, `highlightJs`, `nb_style`, `latex`,
`favicon`, `path_to_root`, `path_to_here`, `source`, `source_highlighted`,
`github_remote_url`, `github_logo`, `version`, `disableHighlightJs`.
Example, a different stylesheet:

```nim
nb.doc.context["stylesheet"] = %"""<link rel="stylesheet" href="https://latex.now.sh/style.css">"""
```

(`%` and `JsonNode` come from `std/json`, which nimib does **not** re-export:
add `import std/json`.)

`nb.backend.partials` is a `Table[string, NbPartialFunc]` with the page
pieces: `head`, `header`, `header_left`, `header_center`, `header_right`,
`left`, `right`, `footer`, `footer_left`, `footer_center`, `footer_right`,
`source_section`, `show_source_script`, plus per-block partials `nbText`,
`nbCodeSource`, `nbCodeOutput`, `nbFile`. Replace one to change that piece
(custom-blocks.md shows how).

## 7. The `Nb` and `NbDoc` objects

```nim
type
  Nb* = object
    blk*: NbBlock            # last block added
    doc*: NbDoc              # the document
    containers*: seq[NbContainer]
    backend*: NbRender       # funcs: Table[kind, render proc]; partials: Table[name, proc]
  NbDoc* = ref object of NbContainer   # .blocks: seq[NbBlock]
    thisFile*: AbsoluteFile; filename*: string; source*: string
    initDir*: AbsoluteDir; options*: NbOptions; cfg*: NbConfig; cfgDir*: AbsoluteDir
    rawCfg*: string; context*: JsonNode; id*: int; nbJsCounter*: int
```

Useful procs: `nb.doc.thisDir`, `nb.doc.srcDir`, `nb.doc.homeDir`,
`nb.doc.thisFileRel`, `nb.doc.srcDirRel`, `nb.doc.newId()` (unique int, for
html ids), `nb.blocks` (top-level blocks), `nb.add blk`,
`nb.withContainer(blk): body`, `nb.render(blk)`, `nb.renderPartial(name, json)`.
Paths are typed (`AbsoluteFile`, `AbsoluteDir`, `RelativeFile`, `RelativeDir`
from `nimib/paths`); convert with `.string` or e.g. `"x.nim".RelativeFile`,
join with `/`. `read(file)` reads a typed path.

`nb.doc.rawCfg` holds the full text of `nimib.toml`, so a document or tool can
read its own sections with `loadTomlSection(nb.doc.rawCfg, "mysection", MyType)`.

## 8. Runtime options

Passed after the file name: `nim r doc.nim --nbShow`.

```
--nbHelp,     --nimibHelp       print help and quit
--nbSkipCfg,  --nimibSkipCfg    ignore nimib.toml
--nbCfgName,  --nimibCfgName    config file name (default nimib.toml)
--nbSrcDir,   --nimibSrcDir     override srcDir (relative to cfgDir, or absolute)
--nbHomeDir,  --nimibHomeDir    override homeDir
--nbFilename, --nimibFilename   output file name
--nbShow,     --nimibShow       open the output in the browser after nbSave
```

Parsing stops at the first non-nimib option; the rest are in
`nb.doc.options.other` for your own use.

## 9. Define flags

- `-d:nimibQuiet`: no `[nimib] ...` log lines on stdout.
- `-d:nimibCodeFromAst`: show code regenerated from the AST (pre-0.3 behaviour).
- `-d:nimibHomeDir=...`, `-d:nimibSrcDir=...` are used by some repos'
  `config.nims` together with the toml (nimib itself reads the toml/options).

## 10. Things that do not exist (any more)

Old code or old answers may use these; they fail to compile on 0.4:

| Old (<= 0.3) | Now |
|---|---|
| `newNbSlimBlock`, `newNbCodeBlock` | `newNbBlock(MyBlock): fields... toHtml: ...` plus a template (custom-blocks.md) |
| `nb.partials["x"] = "mustache"`, `nb.templateDirs`, mustache contexts | `nb.backend.partials["x"] = proc`, string interpolation |
| `nb.blk.context["output"]`, `nb.blk.output` on generic blocks | typed fields: `nb.blk.NbCode.output` |
| `nb.blocks` of a single `NbBlock` type with `command` field | block subclasses with a `kind` string |
| `nbDoc.render = ...` render plans | `nb.backend.funcs[kind] = proc` |
| `nbUseNimibook` | `nbInit(theme = useNimibook)` |
| `nbJsFromCode` without capturing outer variables | must capture: `nbJsFromCode(x, y): ...` (interactivity.md) |

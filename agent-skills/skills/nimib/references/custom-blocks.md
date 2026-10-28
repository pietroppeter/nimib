# Custom blocks, themes and backends (nimib 0.4)

## Contents
1. How rendering works
2. A simple block with `newNbBlock`
3. A container block (nested blocks)
4. Markdown backend support for your block
5. Changing page pieces: partials and context
6. A custom theme
7. Migrating 0.3 blocks
8. Pitfalls

## 1. How rendering works

- A block is a `ref object of NbBlock` with a `kind: string` equal to its type name.
- `nb.add blk` appends it to the document (or to the innermost open container).
- At `nbSave`, `nb.render(blk)` looks up `nb.backend.funcs[blk.kind]` and
  calls it: `proc (blk: NbBlock, nb: Nb): string {.noSideEffect.}`.
  A kind with no render func renders as `""` (silently!).
- Two backends ship: `nbToHtml` (default) and `nbToMd` (used by `nbInitMd`).
- Page-level pieces and some block pieces are *partials*:
  `nb.backend.partials[name]: proc (blk: JsonNode, nb: Nb): string`.

## 2. A simple block with `newNbBlock`

```nim
import std/strformat
import nimib

newNbBlock(NbCallout):          # defines type NbCallout, newNbCallout(...), nbCalloutToHtml
  level: string                 # fields: name: type
  message: string
  toHtml:                       # body has `blk: NbCallout` and `nb: Nb` in scope; returns string
    &"""<div class="callout callout-{blk.level}"><strong>{blk.level}:</strong> {blk.message}</div>"""

func callout*(nb: var Nb, level, message: string) =   # method form: nb.callout(...)
  nb.add newNbCallout(level = level, message = message)

template nbCallout*(level, message: string) =   # the user-facing template, uses the injected `nb`
  nb.callout(level, message)
```

This mirrors how nimib defines its own blocks (`func image*(nb: var Nb, ...)`
plus `template nbImage*`). Putting the logic in a proc/func avoids a classic
template trap: **template parameters are substituted everywhere in the
template body**, including the left side of named arguments and field
accesses. `template nbCallout(level, message: string) = nb.add newNbCallout(level = level, ...)`
expands to `newNbCallout("warning" = "warning", ...)` and fails with
`identifier expected, but found '"warning"'`. When you must use a template
(blocks with a `body`, like containers), give parameters names that differ
from the fields (`tsummary`, `tlevel`).

`newNbBlock` generates:

```nim
type NbCallout* = ref object of NbBlock
  level*: string
  message*: string
proc newNbCallout*(level: string = "", message: string = ""): NbCallout   # sets kind = "NbCallout"
proc nbcalloutToHtml*(blk: NbBlock, nb: Nb): string
nbToHtml.funcs["NbCallout"] = nbcalloutToHtml
addNbBlockToJson(NbCallout)     # registers the type for the JSON backend
```

Notes:
- Do not name a field `kind` (it is the inherited type tag).
- `toHtml` must be side-effect free (it is a `func`): no `echo`, no global
  mutable state, no file IO. Compute things in the template, store them in fields.
- Field types must be JSON-serializable (jsony), because every block type is
  registered for the JSON backend.
- `withNewlines:` is a handy macro for building multi-line html: each line of
  its body is an expression; empty strings are skipped; `if` without `else`
  and `for` loops work.

```nim
  toHtml:
    withNewlines:
      "<ul>"
      for item in blk.items:
        &"<li>{item}</li>"
      "</ul>"
```

- Markdown text inside your html: call `markdownToHtml(text)`.
- Escape user text if it can contain `<`/`&` (e.g. `xmltree.escape`).
- Run code and capture output in a custom block: reuse the `NbCode` pieces,

```nim
template nbCodeWithTitle*(title: string, body: untyped) =
  nbText: "**" & title & "**"
  nbCode: body
```

  Composing existing blocks in a template is often all you need.

## 3. A container block (nested blocks)

Inherit from `NbContainer` and open it with `nb.withContainer`:

```nim
newNbBlock(NbDetails of NbContainer):
  summary: string
  toHtml:
    withNewlines:
      &"<details><summary>{blk.summary}</summary>"
      nbContainerToHtml(blk, nb)     # renders the nested blocks
      "</details>"

template nbDetails*(tsummary: string, body: untyped) =
  let blk = newNbDetails(summary = tsummary)      # param name differs from the field
  nb.withContainer(blk):
    body                             # nbText/nbCode inside go into blk.blocks
  nb.add blk
```

nimibex's chat bubbles (`nimib-land/nimibex`, `src/nimibex/chat_bubbles.nim`)
are a full real-world example (object fields, chroma colours, a "character"
helper template).

## 4. Markdown backend support

`newNbBlock` only registers an html renderer. For `nbInitMd` documents add one:

```nim
func nbCalloutToMd(blk: NbBlock, nb: Nb): string =
  let blk = blk.NbCallout
  "> **" & blk.level & ":** " & blk.message
nbToMd.funcs["NbCallout"] = nbCalloutToMd
```

## 5. Changing page pieces: partials and context

The default theme (`themes.useDefault`) fills `nb.doc.context` (JsonNode) and
`nb.backend.partials`. After `nbInit`, override either:

nimib does not re-export `JsonNode` or `%`: add `import std/json` to write
partials or touch the context.

```nim
import std/json
nb.doc.context["stylesheet"] = %"""<link rel="stylesheet" href="https://cdn.simplecss.org/simple.min.css">"""
nb.doc.context["nb_style"] = %(nb.doc.context["nb_style"].getStr & "<style>.callout{padding:1em}</style>")

func myFooterCenter(blk: JsonNode, nb: Nb): string =
  """<span class="nb-small">CC-BY 4.0</span>"""
nb.backend.partials["footer_center"] = myFooterCenter

func noSource(blk: JsonNode, nb: Nb): string = ""
nb.backend.partials["footer_right"] = noSource       # hide the Show Source button
nb.backend.partials["source_section"] = noSource
```

Partial names: `head`, `header`, `header_left`, `header_center`,
`header_right`, `left`, `right`, `footer`, `footer_left`, `footer_center`,
`footer_right`, `source_section`, `show_source_script`, and block-level
`nbText`, `nbCodeSource`, `nbCodeOutput`, `nbFile`. Page layout
(`nbDocToHtml`): `<head>` partial, then `<body>`: header, left, `<main>`
blocks `</main>`, right, footer.

Adding something to `<head>` (a script, meta tags): the default `head`
partial prints `context["stylesheet"]`, `["highlight"]`, `["nb_style"]`,
`["latex"]` and `["highlightJs"]`; appending to `nb_style` (any html is fine)
is the simplest hook.

## 6. A custom theme

```nim
proc useMyTheme*(nb: var Nb) =
  nb.useDefault                # start from default (import nimib/themes if needed)
  nb.darkMode
  nb.backend.partials["footer_center"] = myFooterCenter

nbInit(theme = useMyTheme)
```

nimibook (`useNimibook`) is a complete theme that replaces most partials.

## 7. Migrating 0.3 blocks

```nim
# 0.3
template nbCallout(level, message: string) =
  newNbSlimBlock("nbCallout"):
    nb.blk.context["level"] = level
    nb.blk.context["message"] = message
nb.partials["nbCallout"] = """<div class="callout">{{level}}: {{message}}</div>"""
```

becomes the `newNbBlock` version in section 2: context keys become typed
fields, the mustache partial becomes `toHtml` with `&"..."` interpolation,
`{{x}}` becomes `{blk.x}`. Code that read `nb.blk.output` now casts:
`nb.blk.NbCode.output`. Code that set `nb.partials[...]` for page pieces now
sets `nb.backend.partials[...]` to a proc.

## 8. Pitfalls

- A block that renders nothing: you forgot `nb.add blk`, or the kind has no
  render func in the active backend (e.g. Markdown).
- `Error: 'toHtml' can have side effects`: remove echo/IO/global access from
  `toHtml`.
- `identifier expected, but found '"..."'`: a template parameter has the same
  name as a block field (see section 2); nimibex prefixes template params
  (`tname`, `tcolor`) for this reason.
- Define blocks at top level (they generate types and procs), not inside a proc.

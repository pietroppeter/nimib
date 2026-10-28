# Interactivity: Nim compiled to JavaScript

nimib can put JavaScript in the page that is **compiled from Nim** during
`nbSave` (it shells out to `nim js`, so `nim` must be on `PATH`). The
compiled script runs in the reader's browser; the rest of the document ran at
build time on your machine. Keep these two worlds apart in your head:

- "C-land": `nbCode` and plain top-level code, run once at build time.
- "JS-land": code inside `nbJs*`/`nbKaraxCode`, compiled to JS and run in the browser.

Names from C-land are not visible in JS-land unless **captured**.

## The nbJsFromCode family (one shared script)

```nim
nbJsFromCodeGlobal:        # placed at the top of the shared script (imports, globals)
  import std/dom
  var clicks = 0
nbJsFromCode:              # appended in order, top-level scope
  echo "goes to the browser console"
nbJsFromCodeInBlock:       # appended inside `block:` so names can repeat
  let msg = "hi"
  echo msg
nbJsFromString: "echo 42"  # Nim source given as a string (it is compiled as Nim, not raw JS)
```

All `nbJsFromCode`, `nbJsFromCodeInBlock` and `nbJsFromCodeGlobal` snippets of
a document go into **one** Nim file compiled once: Global ones first, then the
others in call order. So a variable from an earlier `nbJsFromCode` is visible
in a later one, and declaring the same name twice at top level is a
`redefinition` error (use `nbJsFromCodeInBlock`, required when the snippet is
inside a template called more than once). Imports cannot go inside a block:
put them in `nbJsFromCodeGlobal`.

`nbJsFromCodeOwnFile: ...` compiles a snippet as its own separate script (no
access to the shared globals).

## Capturing build-time values

```nim
let data = @[3, 1, 4, 1, 5]            # computed at build time
let listId = "list-" & $nb.doc.newId()
nbRawHtml: &"""<ul id="{listId}"></ul>"""
nbJsFromCodeGlobal:
  import std/dom                        # imports go in Global, not inside a block
nbJsFromCodeInBlock(data, listId):     # captured: serialized to JSON, rebuilt in JS
  var html = ""
  for x in data:
    html.add "<li>" & $x & "</li>"
  getElementById(listId.cstring).innerHtml = html.cstring   # build a Nim string, convert once
```

Rules:
- List every outer variable the snippet uses as an argument before the body.
  Forgetting one gives a JS compile error like `undeclared identifier` and the
  message "The compilation of a javascript file failed! Did you remember to
  capture all needed variables?".
- Captured values go through `toJson`/`parseJson(...).to(T)` (std/json), so
  their types must round-trip through JSON (ints, floats, strings, seqs,
  objects, tuples; not procs/refs with cycles).
- Captures are copies: changing them in JS does not affect build-time values.

## The reusable widget pattern

Generate the html with unique ids at build time, capture the ids:

```nim
nbJsFromCodeGlobal:
  import std/dom

template counterButton(label: string) {.dirty.} =
  block:
    let btnId = "btn-" & $nb.doc.newId()
    let outId = "out-" & $nb.doc.newId()
    let btnLabel = label
    nbRawHtml: &"""<button id="{btnId}">{btnLabel}</button> <span id="{outId}">0</span>"""
    nbJsFromCodeInBlock(btnId, outId):
      var n = 0
      let btn = getElementById(btnId.cstring)
      btn.addEventListener("click", proc (e: Event) =
        inc n
        getElementById(outId.cstring).innerHtml = ($n).cstring)

counterButton("Click me")
counterButton("Me too")     # works: dirty template + block + unique ids
```

Three details make this work (each one, when missing, is a compile error):
- `{.dirty.}`: in a normal hygienic template, `btnId` is renamed
  (gensym'd) but the captured body still says `btnId`, so the JS compile
  fails with `undeclared identifier: 'btnId'`. (The same template written
  inside a `nbCode:`/`nimibCode:` block happens to work without it, which is
  why nimib's own counters example does not use `dirty`.)
- `block:` so the dirty template can be called more than once without
  `redefinition of 'btnId'`.
- `let btnLabel = label`: `&"..."`/`fmt"..."` strings are parsed after template
  substitution, so a template **parameter** written as `{label}` inside the
  string is not found. Bind parameters to a local first.

`std/dom` expects `cstring` for ids and html (`"x".cstring`, `($n).cstring`).

## nbKaraxCode (needs `nimble install karax`)

Each `nbKaraxCode` is compiled as its own file (`nbJsFromCodeOwnFile` under the
hood) and mounted in a fresh `<div id="karax-N">`. karax's prelude modules are
imported for you; you write state + a `karaxHtml:` block (the body of
`buildHtml(tdiv)`):

```nim
let start = 10
nbKaraxCode(start):               # capture works the same way
  var count = start
  karaxHtml:
    p: text "count: " & $count
    button:
      text "+1"
      proc onClick() = inc count
```

`postRender: body` (before `karaxHtml`) registers a callback that runs after
each render. To display the karax code too, wrap it in a template inside
`nbCode` and call the template afterwards, or use `nimibCode:`.

Caveat: identical `nbKaraxCode` blocks could get identical gensym'd names;
nimib bumps the gensym counter per block. Avoid declaring two different
variables with the same name in nested scopes inside one karax block.

## nbHappyxCode (needs `happyx`)

Like `nbKaraxCode` but the body must end with a `happyxRoutes:` block, which
becomes `appRoutes(rootId): ...`.

## Showing the code you compiled to JS

- `nbCodeDisplay(nbJsFromCodeInBlock): body`: compiles `body` to JS and shows it.
- `nbCodeAnd(nbJsFromCodeInBlock): body`: runs `body` at build time (nbCode,
  with output) and also in the browser.
- `nimibCode: nbJsFromCode: ...`: shows the nimib call itself.

## Debugging

- The JS compile runs during `nbSave`; its compiler output appears in your
  terminal even with `--hints:off`. Look for the first `Error:` line, the file
  is `js_file_nbCodeToJs_N.nim` (written to the current directory and removed
  after a successful compile; it stays when compilation fails, which is useful
  for reading the generated Nim).
- Check the result in a browser console. Headless check: open the html with
  Playwright/Chromium and read console messages.
- Big JS output is normal (the Nim runtime is included).

# Troubleshooting nimib documents

Read the **first** `Error:` line of the compiler output; the long chain of
`template/generic instantiation of nbCode from here` lines below it only says
the error happened inside a block. `python3 scripts/nbcheck.py doc.nim`
prints the first error for you.

| Symptom | Cause and fix |
|---|---|
| `undeclared identifier: 'nb'` | `nbInit` missing, called later, or called inside a proc/block. Call it once at top level before any block. |
| `redefinition of 'x'` | two `nbCode` blocks declare the same name (they share module scope). Rename, or use `nbCodeInBlock`. In JS blocks use `nbJsFromCodeInBlock`. |
| `undeclared identifier: 'newNbSlimBlock'` / `'newNbCodeBlock'` / `nb.partials` | 0.3 API. Rewrite with `newNbBlock` (custom-blocks.md). |
| `undeclared identifier: 'JsonNode'` or `'%'` | add `import std/json` (nimib does not re-export it). |
| `identifier expected, but found '"..."'` in your own template | a template parameter has the same name as a field used in `field = param` (custom-blocks.md, section 2). Rename the parameter. |
| `could not load: libpcre.so(.3\|.1\|)` at runtime | install PCRE (setup.md). |
| `The compilation of a javascript file failed! Did you remember to capture all needed variables?` | open the kept `js_file_nbCodeToJs_N.nim` and the first JS compile error above. Usually: an outer variable not captured (`nbJsFromCode(x): ...`), an `import` inside an InBlock snippet (move to `nbJsFromCodeGlobal`), a C-only API used in JS (`readFile`, `os`), `cstring` vs `string` mismatch with `std/dom` (convert with `.cstring`; build a Nim `string` and convert once instead of `&` on cstrings). |
| `undeclared identifier` for a variable created in your own template and captured by `nbJs*` | the template is hygienic: mark it `{.dirty.}` and wrap the body in `block:` (interactivity.md). |
| a `{param}` inside `&"..."` in a template is undeclared | fmt cannot see template parameters; `let p = param` first. |
| `undeclared identifier: 'nbKaraxCode'` | karax not installed (`nimble install karax`); the template only exists when `karax/kbase` is importable. Same for `nbHappyxCode` (happyx) and `nbInitPython` (nimpy). |
| `undefined reference to ...` at **link** time (often in `markdown`), right after upgrading or while other builds run | stale or shared C cache: Nim caches per file name in `~/.cache/nim/<name>_d`, so two builds of `report.nim` collide. Rebuild with `--nimcache:./nimcache` (or delete that folder). `-f` alone may not help. |
| `identifier expected, but got 'keyword converter'` (or another keyword) at a name like `converter`, `method`, `iterator`, `concept`, `mixin` | it is a Nim keyword: rename the template/proc/variable (`converterWidget`). |
| `nbCodeSkip` error about an empty block / statement expected | the body must contain at least one statement in every branch; add `discard`. |
| A literal `{` / `}` disappears or errors in `&"..."` | double them: `{{` `}}` (LaTeX in fmt strings too). |
| Text shows as a grey code block | it was indented 4+ spaces inside `nbText`. Dedent. |
| Markdown shows raw `#`/`**` | same indentation issue, or the text was put in `nbRawHtml`. |
| Output section empty | only stdout is captured: `echo` the value. Output printed by a C library directly to the fd is captured; output of a child process started with `execShellCmd` is captured too, but `stderr` is not. |
| Page shows text/code but not my custom block | `nb.add blk` missing or no render func for the backend (custom-blocks.md). |
| Image broken | relative url interpreted from the root (srcDir, or cwd without config). See config-and-paths.md. |
| Html written in an unexpected folder | a `nimib.toml` in a parent of the working directory sets `homeDir`/`srcDir`. Use `--nbSkipCfg`, or run from elsewhere, or adjust the toml. |
| Document runs but reads files from the wrong place | with `homeDir` set, the program's current directory is `homeDir`. Use `nb.doc.thisDir`/`nb.doc.srcDir`. |
| `[nimib] ...` log lines clutter output | compile with `-d:nimibQuiet`. |
| `nimble install` fails with `Refresh failed` / status 405 | package list download blocked by a proxy: see setup.md. |
| Show Source button shows wrong/missing code | nimib reads the source at runtime from `thisFile`; moving the binary away from the source (or `nim c` then copying it) loses it. Use `nim r`. |
| Comments missing from shown code | compiled with `-d:nimibCodeFromAst`; drop it. |

When a document compiles but something looks off, open the html (or run
`nbcheck.py`, and `node scripts/browser_check.mjs page.html` for nbJs/karax
pages to see browser console errors and click through widgets).

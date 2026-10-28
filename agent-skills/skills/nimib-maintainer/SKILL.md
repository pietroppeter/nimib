---
name: nimib-maintainer
description: Maintain the nimib ecosystem repositories (nimib, nimibook, nimiSlides, nimibex, nblog, nimiBoost, nimib.py, the nimib-land org), to cut releases, update changelogs and versions, run and fix tests and CI, keep the docs and README in sync, check downstream compatibility, triage issues, and carry on the move to the nimib-land GitHub org. Use it when working inside one of these repos on anything other than writing a document, for example "release nimib 0.4.4", "why is the docs workflow red", "port this block to nimibex", "update links after moving nimibook", "close stale issues".
---

# Maintaining the nimib ecosystem

Maintainers: Pietro Peterlongo (`pietroppeter`) and Hugo Granström
(`HugoGranstrom`). For writing nimib documents or blocks, use the `nimib`
skill; for books, the `nimibook` skill. This skill is about the repos.

Facts below were checked on 2026-10-28; versions and CI state move, so
re-check them (`git log`, the `.nimble` files, the Actions tab) before acting.

## Repository map

| Repo | Role | Version / deps | Site |
|---|---|---|---|
| `pietroppeter/nimib` | core library | 0.4.3; nim >= 1.4, fusion, markdown, parsetoml, jsony | pietroppeter.github.io/nimib (gh-pages) |
| `pietroppeter/nimibook` | mdBook port | 0.4.0; nimib >= 0.4.1, nim >= 2.0, jsony | pietroppeter.github.io/nimibook |
| `HugoGranstrom/nimiSlides` | reveal.js slides | ported to nimib 0.4 | hugogranstrom.com/nimiSlides |
| `nimib-land/nimibex` | extra blocks (one module per block, e.g. `nimibex/chat_bubbles`) | 0.1.0; nimib >= 0.4.1, chroma; nimble.lock | nimib.land/nimibex |
| `nimib-land/nblog` | blog = loose drafts; SSG never finished (draft PR #16) | nimib 0.3 era | nimib.land/nblog |
| `nimib-land/nimiBoost` | VS Code extension (markdown highlighting in `hlMd` strings, preview) | TypeScript | VS Code marketplace `hugogranstrom.nimiboost` |
| `nimib-land/nimib.py` | experimental Python bridge (nimpy + nimporter) | nimib 0.3 internals, does not build on 0.4 | nimib.land/nimib.py |
| `nimib-land/nimib-land.github.io` | org landing page, CNAME `nimib.land` (so every org repo site is `nimib.land/<repo>/`) | stub | nimib.land |
| `pietroppeter/adventofnim` | AoC solutions as nimib docs | nimib 0.2/0.3 era | pietroppeter.github.io/adventofnim |

Repos built on nimib <= 0.3 (nblog, adventofnim, nimib.py, slides decks) need
porting before they rebuild on 0.4; see the `nimib` skill's custom-blocks
reference, section "Migrating 0.3 blocks".

## Working on nimib itself

- Layout: `src/nimib.nim` (glue, `nbInit`/`nbSave`), `src/nimib/builtinBlocks.nim`
  (all blocks, via `newNbBlock`), `nimibSugars.nim` (`newNbBlock`,
  `withNewlines`), `renders.nim`, `themes.nim`, `jsutils.nim` (nbJs/karax),
  `jsons.nim` (JSON backend), `config.nim`, `options.nim`.
- Tests: `nimble test` runs `tests/{tsources,tblocks,tnimib,trenders}.nim`,
  then again with `-d:nimibCodeFromAst`. Requires libpcre3 at runtime.
  `nimble docsdeps` installs doc dependencies (it pins nimja 0.10.3 and
  deletes nimja 0.10.4, which does not compile to JS); `nimble docs` builds
  every `docsrc/*.nim` into `docs/` and then runs `nimble readme`.
- **README is generated** from `docsrc/index.nim` by `nimble readme`
  (`-d:mdOutput`). Edit `index.nim`, never only README.md. Known drift:
  README lines about NimConf 2024 and the NimibLand migration note were
  edited directly (PR #252) and are missing from `index.nim`; running
  `nimble readme` would delete them. Port them into `index.nim` first (issue
  #141 tracks removing this coupling).
- Stale docs after 0.4 (fix when touching nearby code): README "API" and
  "Rendering" sections and "creating custom blocks" (mustache, partials,
  `newNbSlimBlock`), CONTRIBUTING "How to add a new block" (blocks now go in
  `builtinBlocks.nim` with `newNbBlock`, plus a test and an `allblocks.nim`
  example), `docsrc/mostaccio.nim` ("nimib uses nim-mustache").
- A new built-in block: define it in `builtinBlocks.nim` with `newNbBlock`
  and a `func xxx*(nb: var Nb, ...)` plus `template nbXxx*`, add an md
  renderer if sensible (`nbToMd.funcs[...]`), a test in `tests/tblocks.nim`
  or `trenders.nim`, an example in `docsrc/allblocks.nim`, a changelog entry.

## Release checklist (nimib; nimibook is similar)

From `changelog.md` "Notes for maintainers":

1. All PRs for the release merged with clear squash messages; CI green.
2. Bump the version in **both** `nimib.nimble` and `nimibVersion` in
   `src/nimib/config.nim` (`tests/tnimib.nim` fails if they differ).
3. Add a `## vX.Y.Z` section on top of `changelog.md`: a short prose summary
   with a code example for new API, then the auto-generated PR list
   (`* title by @author in <PR url>`). Bump and changelog usually land as one
   PR titled "Bump X.Y.Z and changelog".
4. Tag `vX.Y.Z` on main and create the GitHub release with auto-generated
   notes, adding context from the changelog. Nimble picks up tags directly
   (the package registry points to the repo; no publish step).
5. Optionally announce (GitHub Discussions, Nim forum thread).
6. Downstream check (see below) for anything that changes blocks, rendering,
   themes or paths.

Tagging, releasing, pushing to main and announcing are visible to users and
cannot be quietly undone: prepare everything, then ask the maintainer to
confirm before doing those steps.

## Downstream compatibility

nimib changes ripple into nimibook (theme partials in
`src/nimibook/themes.nim`, uses `nbInit(theme=..., thisFileRel=...)`,
`loadNimibCfg`, `loadTomlSection`), nimiSlides (theme, custom blocks),
nimibex (custom blocks). Before releasing a change to blocks, partials,
`NbDoc` fields, config or paths:

```sh
# with the candidate nimib installed (cd nimib && nimble install -y)
git clone https://github.com/pietroppeter/nimibook && cd nimibook
nimble install -y --depsOnly && nimble test && nimble genbook && nimble test_example
git clone https://github.com/nimib-land/nimibex && cd nimibex
nimble install -y --depsOnly && nimble buildBook
```

Also build the nimib skill's examples (`agent-skills/harness/check_snippets.py`)
so the skills keep matching the code.

## CI patterns (and known breakage)

- `test.yml`: ubuntu-24.04, Nim stable + devel (setup-nim-action), apt
  `libpcre3`, `nimble install`, `docsdeps`, `test`. **ubuntu-latest no longer
  packages libpcre3**: pin ubuntu-24.04 or install PCRE another way.
- `docs.yml` (push to main, deploys gh-pages): as of 2026-10-28 it still runs
  on `ubuntu-latest` without the libpcre3 step and has been failing since
  0.4.2, so the public docs predate 0.4.1. Fix: same runner/apt step as
  `test.yml`.
- PR previews: nimib and nimibook use Netlify (build workflow uploads an
  artifact, `workflow_run` workflow deploys with `NETLIFY_AUTH_TOKEN`/
  `NETLIFY_SITE_ID`, URL `https://<sha20>--<site>.netlify.app`). nimibex uses
  gh-pages + `rossjrw/pr-preview-action` (no secrets): simpler to move between
  orgs.
- Many actions are old (`checkout@v2`, `peaceiris@v3`); update opportunistically.

## Triage

Most open issues in nimib (60) and nimibook (23) predate 2024. When triaging:
close issues solved by the 0.4 refactor with a pointer to PR #235 (nimib
#168, #102, #111), close done items (nimibex #11 chat bubbles, nimibook #93
pcre CI), and retire dated labels (2023H1/2023H2). Closing issues and
commenting are public actions: draft the list with reasons and let the
maintainer approve before posting.

## The nimib-land move (in progress)

Goal (nimib issue #137): move nimib, nimibook (and nimiSlides, if Hugo
agrees) to `nimib-land`. Done: nblog, nimibex, nimiBoost, nimib.py and small
repos. For each transfer:

1. Transfer the repo on GitHub (keeps issues, stars, git redirects).
2. Keep the old Pages URLs alive: create a redirect-only repo at the old name
   (e.g. `pietroppeter/nimib` with Pages) with meta-refresh pages to
   `https://nimib.land/<repo>/...` for every published path. nblog still lacks
   this (nblog #19: pietroppeter.github.io/nblog/... is 404).
3. Update the `nim-lang/packages` `packages.json` URL (PR there).
4. Update hardcoded links: README/docs, `nimib.toml` (`git_repository_url`,
   plausible domain), nimibex `nimble.lock`, workflow URLs and Netlify secrets
   (or switch to the gh-pages preview), cross-links in other repos.
   `grep -rn "pietroppeter/<repo>\|pietroppeter.github.io/<repo>"` across all
   repos finds them.
5. Close #137 when nimib and nimibook are moved; refresh the org profile README.

Detailed research notes (if available in the project files):
`ecosystem-research/core.md`, `satellites.md`, `web.md`.

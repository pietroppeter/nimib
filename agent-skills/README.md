# nimib agent skills 🐳🤖

Skills that teach AI coding agents (Claude Code, and any agent that reads
`SKILL.md` folders) to work with the nimib ecosystem the way it is **today**:
nimib 0.4 (no more mustache), nimibook 0.4, and the maintainers' own
procedures. Models trained before mid-2026 default to the nimib 0.3 API
(`newNbSlimBlock`, `nb.partials`, `nb.blk.output`), and parts of the online
docs still describe it, so an agent without these skills writes code that no
longer compiles.

| Skill | Use it for |
|---|---|
| [`nimib`](skills/nimib/SKILL.md) | writing, building and debugging nimib documents: blocks, markdown, config and paths, interactivity (nbJs/karax), custom blocks and themes, Markdown output |
| [`nimibook`](skills/nimibook/SKILL.md) | creating and building books: `nbook.nim` TOC DSL, chapters, `nimib.toml`, commands, GitHub Pages |
| [`nimib-maintainer`](skills/nimib-maintainer/SKILL.md) | maintaining the repos: releases, changelog/version bumps, CI, docs/README sync, downstream checks, triage, the nimib-land move |

Each skill has a short `SKILL.md` (loaded when the skill triggers) and
`references/` loaded only when needed. The nimib skill ships two checkers the
agent runs on its own output:

- `skills/nimib/scripts/nbcheck.py doc.nim`: builds the document and reports
  what the HTML contains plus common rendering mistakes (prose turned into a
  code block by indentation, raw markdown, un-interpolated `{placeholders}`,
  default title, missing images, errors in outputs).
- `skills/nimib/scripts/browser_check.mjs page.html --click "#btn" --text "#out"`:
  opens the page in headless Chromium (Playwright) and reports JS errors, so
  nbJs/karax widgets are tested, not just compiled.

and nimibook has `skills/nimibook/scripts/bookcheck.py` (every TOC entry has a
page with the sidebar, prev/next links resolve, no failed-chapter logs).

## Install

Claude Code, as a plugin from this repository:

```
/plugin marketplace add pietroppeter/nimib
/plugin install nimib@nimib
```

Or copy single skill folders into `~/.claude/skills/` (personal) or
`.claude/skills/` (one project). Other agents: point them at
`skills/<name>/SKILL.md`. On claude.ai, upload a skill folder as a zip in
Settings > Capabilities > Skills.

## How the skills are tested

Skills are code that rots: nimib changes, and an example that compiled last
month can fail today. Two layers keep them honest.

**1. Everything the skills teach is compiled** (`harness/check_snippets.py`, run in CI):

- every `skills/*/examples/*.nim` is built with nimib and checked with
  `nbcheck.py`; pages with nbJs/karax are also opened in headless Chromium;
- every complete nimib document in a ```` ```nim ```` fence of any skill
  markdown (an `import ... nimib` line and a top-level `nbSave`) is extracted
  and built;
- every book declared in a fence (`nimibookCli`) is built with `init`/`build`
  and checked with `bookcheck.py`.

Fragments that are not complete documents should have their pattern covered
by an example file. A fence can opt out with a `# snippet: skip` line.

**2. Agents are benchmarked with and without the skills** (`evals/`, the
`claude plugin eval` format). Each case is a realistic request (write a
document, port a 0.3 doc to 0.4, add a custom block, interactive widget,
README + html from one source, docs site with `nimib.toml`, new nimibook,
prepare a release). Graders are mostly **deterministic checks on the files
the agent produced**: the HTML exists (nimib only writes it if the program
compiled and ran), contains code outputs, the custom block rendered, the
image path resolves, the version was bumped in both places... An LLM judge
covers what regexes cannot (numbers in prose come from code, the agent did
not tag or push a release). Every case runs twice, with and without the
plugin, so the report shows what the skills add.

```sh
bash harness/setup-nim.sh                   # Nim + nimib + nimibook + karax + libpcre, works in sandboxes
python3 harness/check_snippets.py           # layer 1
cd agent-skills && claude plugin eval . --scaffold --allow-tools Write Edit Bash \
   --judge-model sonnet --runs 3            # layer 2 (real, billed model runs)
```

First benchmark (2026-10-28, nimib 0.4.3, one run per arm, sonnet subagents
graded with `harness/run_graders.py`): both arms passed 41/43 checks, because
an agent that can read the installed nimib sources rediscovers the 0.4 API by
itself; with the skills runs took half the time (80 s vs 154 s mean, faster
in 7 of 8 cases) for the same tokens. Without the skills the agent kept the
default page title and typed computed numbers by hand into prose; with them
it wrote `readme.md` instead of `README.md`, which led to the Markdown
section of the nimib skill being fixed (the rerun passes). Most cases do not
yet separate the arms: harder cases are the next step.

Re-run both after each nimib/nimibook release, and when a skill changes.
When a with-skill run fails, read its transcript: the fix is usually a
clearer explanation in the skill, not another rule. When a check passes just
as often without the skill, the advice it tests may be unnecessary: consider
pruning it.

## Adding or changing a skill

1. Ground every claim in the current source (`src/nimib/*.nim`), not in the
   README/docs (parts still describe 0.3).
2. Put runnable patterns in `examples/`, and run `harness/check_snippets.py`.
3. Add an eval case in `evals/<case-name>/` (`prompt.md`, `case.yaml`,
   `graders/`), preferring file checks over LLM judges.
4. Run the evals with and without the plugin and compare.

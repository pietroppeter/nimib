---
tags: [nimib]
max_turns: 40
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

For my small Nim library `tinystats` (just imagine a proc `mean(xs: seq[float]): float`, define it inline),
I want a single nimib source readme.nim that produces BOTH README.md (for GitHub) and readme.html (for the docs site),
with a usage example whose output is shown. Generate both files.

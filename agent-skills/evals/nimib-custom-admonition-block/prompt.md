---
tags: [nimib]
max_turns: 40
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

In my nimib docs (nimib 0.4.3) I keep writing raw html for warning/tip boxes. Create a reusable custom block
`nbAdmonition(kind, text)` where kind is "tip" or "warning", rendering a styled box (div with class admonition and the kind).
Put the block definition and a short demo page using it twice in admonition.nim and build it to admonition.html.

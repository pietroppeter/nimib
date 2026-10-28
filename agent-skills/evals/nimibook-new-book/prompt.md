---
tags: [nimibook]
max_turns: 40
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

Create a nimibook for a tiny statistics tutorial in the current folder. Book title "Stats Book",
repo link https://github.com/example/stats. Chapters: "Introduction" (markdown, not numbered),
"Mean" (a Nim chapter that computes and prints a mean), and a section "Dispersion" containing a
"Variance" chapter (Nim, prints a variance). Build the book.

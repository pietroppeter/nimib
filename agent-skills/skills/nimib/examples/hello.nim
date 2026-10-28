## The skeleton from SKILL.md: text, code, output, interpolation.
import std/[strformat, strutils]
import nimib

nbInit
nb.title = "Counting words"

nbText: """
# Counting words
We split a sentence and count the words.
"""

nbCode:
  let sentence = "the quick brown fox jumps over the lazy dog"
  let words = sentence.splitWhitespace
  echo words.len

nbText: &"The sentence has **{words.len}** words."

nbCodeInBlock:
  let words = @["shadowing", "is", "fine", "in", "a", "block"]
  echo words.join(" ")

nbSave

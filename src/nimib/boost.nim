import std / strformat

template md*(s: string): string =
  ## Template for use with NimiBoost to mark strings to be syntax-highlighted as Markdown.
  ## It is a no-op and returns the orginal string.
  s

template fmd*(s: string): string =
  ## Template for use with NimiBoost to mark strings to be syntax-highlighted as Markdown.
  ## Equivilent to ``&s`` so it applies string interpolation.
  &s

template python*(s: string): string =
  ## Template for use with NimiBoost to mark strings to be syntax-highlighted as Python.
  ## It is a no-op and returns the orginal string.
  s
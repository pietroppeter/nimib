import std / strformat

template md*(s: string): string =
  ## Template for use with NimiBoost to mark strings to be syntax-highlighted.
  ## It is a no-op and returns the orginal string.
  s

template fmd*(s: string): string =
  ## Template for use with NimiBoost to mark strings to be syntax-highlighted
  ## Equivilent to ``&s`` so it applies string interpolation.
  &s
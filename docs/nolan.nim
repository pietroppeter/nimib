import nimib
import strutils, sequtils

proc mix[T](s: seq[T]): seq[T] =
  var
    i = 0
    j = s.len - 1
  while true:
    if j < i:
      break
    result.add s[j]
    if j == i:
      break
    result.add s[i]
    inc i
    dec j

nbInit

nbText: "# " & mix(toSeq("Limerick")).join

nbText: "There was a young man from Japan"
nbText: "Whose limericks never would scan."
nbText: "And when they asked why,"
nbText: "He said \"I do try!"
nbtext: "But when I get to the last line I try to fit in as many words as I can.\""

nbDoc.blocks[1 .. 5] = mix(nbDoc.blocks[1 .. 5])

nbSave
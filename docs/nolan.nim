import nimib
import strutils, sequtils

nbInit

nbText: """
> This nimib example document shows how to use `nbDoc.blocks` api to change
> the order of presentation of blocks.
>
> It reorders a **Limerick** according to Nolan's [Memento film structure](https://en.wikipedia.org/wiki/Memento_(film)#Film_structure).
>
> Click on `Show Source` at the bottom to see the nim file that generates this document.
"""

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

nbText: "# " & mix(toSeq("Limerick")).join

nbText: "`1` There was a young man from Japan"
nbText: "`2` Whose limericks never would scan."
nbText: "`3` And when they asked why,"
nbText: "`4` He said \"I do try!"
nbtext: "`5` But when I get to the last line I try to fit in as many words as I can.\""

nbDoc.blocks[2 .. 6] = mix(nbDoc.blocks[2 .. 6])

nbSave

# save another document without source to test the opt-out of Show Source feature
nbDoc.context["no_source"] = true
nbDoc.filename = nbDoc.filename.replace(".html", "_no_source.html")
nbSave
import nimib
import strutils, sequtils, strformat

nbInit
nbText: """
> This nimib example document shows:
>   * how to use `nbDoc.blocks` api to change the order of presentation of blocks.
>   * how to change the output of a previous block
>   * how to save a variant of a document
>   * how to opt-out of Show Source functionality
>
> It reorders a **Limerick** according to Nolan's [Memento film structure](https://en.wikipedia.org/wiki/Memento_(film)#Film_structure).
"""
let filename_variant = nb.filename.replace(".html", "_no_source.html")
let iChange = nb.blocks.len
nbText:fmt"""
> Click on `Show Source` at the bottom to see the nim file that generates this document.
> To see the variant with no Show Source [click here]({(filename_variant.AbsoluteFile).relPath})
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
let iStart = nb.blocks.len
nbText: "`1` There was a young man from Japan"
nbText: "`2` Whose limericks never would scan."
nbText: "`3` And when they asked why,"
nbText: "`4` He said \"I do try!"
nbtext: "`5` But when I get to the last line I try to fit in as many words as I can.\""
let iEnd = nb.blocks.len

nb.blocks[iStart ..< iEnd] = mix(nb.blocks[iStart ..< iEnd])

nbSave

# save another document without source to test the opt-out of Show Source feature
nbText: "---\n> This is how we can remove the `Show Source` functionality"
nbCode:
  nb.context["no_source"] = true
# we will generate this last block to change a previous block and then remove it
nbText:fmt"""
> To see the variant with Show Source [click here]({(nb.filename.AbsoluteFile).relPath})
"""
nb.blocks[iChange] = nbDoc.blocks.pop
nb.filename = filename_variant
nbSave
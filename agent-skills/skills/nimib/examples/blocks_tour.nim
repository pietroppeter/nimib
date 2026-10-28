## A tour of the built-in blocks and document switches listed in SKILL.md and references/api.md.
import std/[strformat, strutils, json]
import nimib

newNbBlock(NbList):
  items: seq[string]
  toHtml:
    withNewlines:
      "<ul class=\"tour-list\">"
      for item in blk.items:
        &"<li>{item}</li>"
      "</ul>"

func list*(nb: var Nb, items: seq[string]) =
  nb.add newNbList(items = items)

template nbList*(items: seq[string]) =
  nb.list(items)

template nbCodeWithTitle(title: string, body: untyped) =
  nbText: "**" & title & "**"
  nbCode: body

nbInit
nb.title = "Blocks tour"
nb.darkMode
nb.useLatex
nb.doc.context["stylesheet"] = %"""<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/water.css@2/out/dark.min.css">"""

nbText: hlMd"""
# Blocks tour
Inline math $e^{i\pi} + 1 = 0$ and display math:
$$\sum_{k=1}^n k = \frac{n(n+1)}{2}$$
"""

nbCode:
  let n = 10
  echo "sum 1..", n, " = ", n * (n + 1) div 2

nbText: &"With interpolation: n is **{n}**, and braces need doubling: `{{literal}}`."

nbTextWithCode: fmt"computed at build time: {2 * 21}"
assert nb.blk.NbTextWithCode.code.len > 0

nbCodeSkip:
  while true:
    discard

nbCapture:
  echo "only this output is shown"

nbCode:
  for i in 1 .. 100:
    echo i
nbClearOutput

nbCodeWithTitle("A titled block"):
  echo "titled"

nbImage("https://raw.githubusercontent.com/pietroppeter/nimib/main/docs/images/todd-cravens-nimib-unsplash.jpg",
        caption = "A whale", width = "300")

nbFile("tour.txt", "a file written by the document\n")
nbFile("tour_code.nim"):
  echo "this code is saved, not run"
nbFile("tour.txt")

nbDiv("note", "border-left: 4px solid gray; padding-left: 1em"):
  nbText: "Blocks nested in a div."
  nbCode:
    echo "inside the div"

type Point = object
  x, y: int
proc toHtml(p: Point): string = &"<b>Point({p.x}, {p.y})</b>"
nbShow(Point(x: 1, y: 2))

nbRawHtml: """<p style="text-align: center">raw html</p>"""

nbList(@["custom", "list", "block"])

nbSave

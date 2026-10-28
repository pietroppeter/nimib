## Custom blocks with newNbBlock (see references/custom-blocks.md).
import std/[strformat, json]   # JsonNode and % for partials/context
import nimib

newNbBlock(NbCallout):
  level: string
  message: string
  toHtml:
    &"""<div class="callout callout-{blk.level}"><strong>{blk.level}:</strong> {blk.message}</div>"""

func callout*(nb: var Nb, level, message: string) =
  nb.add newNbCallout(level = level, message = message)

template nbCallout*(level, message: string) =
  nb.callout(level, message)

func nbCalloutToMd(blk: NbBlock, nb: Nb): string =
  let blk = blk.NbCallout
  "> **" & blk.level & ":** " & blk.message
nbToMd.funcs["NbCallout"] = nbCalloutToMd

newNbBlock(NbDetails of NbContainer):
  summary: string
  toHtml:
    withNewlines:
      &"<details><summary>{blk.summary}</summary>"
      nbContainerToHtml(blk, nb)
      "</details>"

template nbDetails*(tsummary: string, body: untyped) =
  # template parameters are substituted everywhere, also on the left of `summary = ...`,
  # so they must not share a name with a block field (hence `tsummary`)
  let blk = newNbDetails(summary = tsummary)
  nb.withContainer(blk):
    body
  nb.add blk

func myFooterCenter(blk: JsonNode, nb: Nb): string =
  """<span class="nb-small">CC-BY 4.0</span>"""

nbInit
nb.title = "Custom blocks"
nb.backend.partials["footer_center"] = myFooterCenter
nb.doc.context["nb_style"] = %(nb.doc.context["nb_style"].getStr &
  "<style>.callout{padding:.5em 1em;border-left:4px solid orange}</style>")

nbCallout("warning", "Custom blocks are plain Nim types in nimib 0.4.")

nbDetails("Click to see the code that ran"):
  nbCode:
    echo "nested inside <details>"

nbSave

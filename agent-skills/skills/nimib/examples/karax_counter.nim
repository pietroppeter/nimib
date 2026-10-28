## nbKaraxCode (requires `nimble install karax`).
import nimib

nbInit
nb.title = "Karax counter"

let start = 10
nbKaraxCode(start):
  var count = start
  karaxHtml:
    p:
      text "count: " & $count
    button:
      text "+1"
      proc onClick() = inc count

nbSave

import nimib, strformat

nbInit

template nbWarning(message: string) =
  newNbSlimBlock("nbWarning"):
    nb.blk.context["message"] = message

nb.partials["nbWarning"] = """<div class="warning-box">⚠️ {{message}}</div>"""

nbText: """
    # Sales report
    This report shows the monthly sales.
"""

let sales = [120, 340, 210]

nbCode:
  for i, s in sales:
    echo "month ", i+1, ": ", s

nbText: fmt"Total sales: {sales[0] + sales[1] + sales[2]}"

nbCode:
  echo "average: ", (sales[0] + sales[1] + sales[2]) div 3
let avgOutput = nb.blk.output

nbWarning("Month 1 was below target")

nbSave

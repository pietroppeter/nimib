import nimib

nbInit

nbText: hlMd"""
# Counters - Creating reusable widgets

This document will show you how to create reusable widgets using `nbCodeToJs`. Specifically we will make a counter:
A button which increases a counter each time you click it. We will do this in two different ways, using `std/dom` and `karax`.
## std/dom
"""
nbCode:
  template counterButton(id: string) =
    let labelId = "label-" & id
    let buttonId = "button-" & id
    nbRawOutput: """
  <p id="$1">0</p>
  <button id="$2">Click me</button>
  """ % [labelId, buttonId]
    nbCodeToJs(labelId, buttonId):
      import std/dom
      echo "Hello world!"
      var label = getElementById(labelId.cstring)
      var button = getElementById(buttonId.cstring)
      var counter: int = 0
      button.addEventListener("click",
        proc (ev: Event) =
          counter += 1
          label.innerHtml = ($counter).cstring
      )

nbText: hlMd"""
## Karax
"""

nbCode:
  var karaxId = 0
  template karaxTest() =
    let root = "root" & $karaxId
    inc(karaxId)
    nbRawOutput: """<div id="$1"></div>""" % [root]
    nbCodeToJs(root):
      import karax / [kbase, karax, karaxdsl, vdom, compact, jstrutils]
      var counter = 0
      proc createDom(): VNode =
        result = buildHtml(tdiv):
          p:
            text "Hello world"
          label:
            text "Counter: " & $counter
          button:
            text "Click me (karax)"
            proc onClick() =
              counter += 1
      setRenderer(createDom, root=root.cstring)

nbSave
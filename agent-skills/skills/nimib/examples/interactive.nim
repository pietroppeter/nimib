## nbJsFromCode family: globals, captures and a reusable widget (see references/interactivity.md).
import std/strformat
import nimib

nbInit
nb.title = "Interactive widgets"

nbText: "Values computed at build time, rendered by Nim compiled to JavaScript:"

nbJsFromCodeGlobal:
  import std/dom

let data = @[3, 1, 4, 1, 5]
let listId = "list-" & $nb.doc.newId()
nbRawHtml: &"""<ul id="{listId}"></ul>"""
nbJsFromCodeInBlock(data, listId):
  var html = ""
  for x in data:
    html.add "<li>" & $x & "</li>"
  getElementById(listId.cstring).innerHtml = html.cstring   # build a Nim string, convert once

# A template that captures its own local variables must be {.dirty.}:
# in a normal (hygienic) template the locals get gensym'd names and the capture fails
# with "undeclared identifier". The `block:` keeps the names local to each call.
template counterButton(label: string) {.dirty.} =
  block:
    let btnId = "btn-" & $nb.doc.newId()
    let outId = "out-" & $nb.doc.newId()
    let btnLabel = label   # fmt strings cannot see template parameters, bind them first
    nbRawHtml: &"""<button id="{btnId}">{btnLabel}</button> <span id="{outId}">0</span>"""
    nbJsFromCodeInBlock(btnId, outId):
      var n = 0
      let btn = getElementById(btnId.cstring)
      btn.addEventListener("click", proc (e: Event) =
        inc n
        getElementById(outId.cstring).innerHtml = ($n).cstring)

nbText: "Two independent counters from the same template:"
counterButton("Click me")
counterButton("Me too")

nbText: "`nbCodeDisplay` shows the code it compiles to JS:"
nbCodeDisplay(nbJsFromCodeInBlock):
  echo "hello from the browser console"

nbSave

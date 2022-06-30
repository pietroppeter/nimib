import std / [strutils]
import nimib

nbInit

nbText: hlMd"""
# Counters - Creating reusable widgets

This document will show you how to create reusable widgets using `nbCodeToJs`. Specifically we will make a counter:
A button which increases a counter each time you click it. We will do this in two different ways, using `std/dom` and `karax`.
## std/dom

The first method is to use Nim like you would have used Javascript using `getElementById` and `addEventListener`: 
"""
nbCode:
  ## 1:
  template counterButton(id: string) =
    let labelId = "label-" & id
    let buttonId = "button-" & id
    ## 2:
    nbRawOutput: """
<label id="$1">0</label>
<button id="$2">Click me</button>
""" % [labelId, buttonId]
    ## 3:
    nbCodeToJs(labelId, buttonId):
      import std/dom
      ## 4:
      var label = getElementById(labelId.cstring)
      var button = getElementById(buttonId.cstring)
      ## 5:
      var counter: int = 0
      button.addEventListener("click",
        proc (ev: Event) =
          counter += 1
          label.innerHtml = ($counter).cstring
      )

nbText: hlMd"""
Let's explain each part of the code:
1. We define a template called `counterButton` which will create a new counter button. So if you call it somewhere it will
place the widget there, that's the reusable part done. But it also takes an input `id: string`. This is to solve the problem of each widget needing unique ids. It can also be done with `nb.newId` as will be used in the Karax example.
2. Here we emit the `<label>` and `<button>` tags and insert their ids.
3. `nbCodeToJs` is the template that will turn our Nim code into Javascript and we are capturing `labelId` and `buttonId` (Important that you capture all used variables defined outside the code block). `std/dom` is where many dom-manipulation functions are located.
4. We fetch the elements we emitted above by their ids. Remember that most javascript functions want `cstring`s!
5. We create a variable `counter` to keep track of the counter and add the eventlistener to the `button` element. There we increase the counter and update the `innerHtml` of the `label`.

Here we have the button in action: `counterButton("uniqueString")`
"""

counterButton("uniqueString")

nbText: """And here is another independent counter: `counterButton("anotherUniqueString")`"""

counterButton("anotherUniqueString")

nbText: hlMd"""
## Karax

The second method uses Karax to construct the HTML and attach an eventlistener to the button:
"""

nbCode:
  template karaxButton() =
    ## 1:
    nbKaraxCode:
      ## 2:
      var counter = 0
      ## 3:
      karaxHtml:
        label:
          text "Counter: " & $counter
        button:
          text "Click me (karax)"
          ## 4:
          proc onClick() =
            counter += 1


nbText: hlMd"""
Here's what each part of the code does:
1. `nbKaraxCode` is a convinience template for writing karax components. Karax is automatically imported inside the code block.
2. Setup `counter` to keep track of the count.
3. `karaxHtml` is a convinience wrapper for the karax dsl. The code block will automatically be inserted inside a `buildHtml(tdiv)`.
4. The eventlistener is inlined in the `button:`.

Here is the button in action: `karaxButton()`
"""

karaxButton()

nbText: """And here is another independent counter: `karaxButton()`"""

karaxButton()

nbText: hlMd"""
## Exercise

Modify the counter templates to include a reset button which sets the counter to 0 again like this:
"""

## Karax with reset button
template karaxButtonWithReset() =
  nbKaraxCode:
    var counter = 0
    karaxHtml:
      label:
        text "Counter: " & $counter
      button:
        text "Click me (karax)"
        proc onClick() =
          counter += 1
      button:
        text "Reset"
        proc onClick() =
          counter = 0

karaxButtonWithReset()

nbText: hlMd"""
If you click "Show source" at the bottom of the page you can find this implemented in Karax in template `karaxButtonWithReset`.
"""


nbSave
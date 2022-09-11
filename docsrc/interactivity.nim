import nimib

nbInit

nbText: hlMd"""
# Creating interactive components in Nimib

Nimib can easily be used to create static content with `nbText` and `nbCode`, but did you know that you can create interactive
content as well? And that you can do it all in Nim even! This can be achieved using either the `nbJsFromCode`-API or `nbKaraxCode`.
They work by compiling Nim code into javascript and adding it to the resulting HTML file.
This means that arbitrary Javascript can be written but also that Karax, which compiles to javascript, also can be used.

## nbJsFromCodeInit
This is the fundamental API used for compiling Nim-snippets to javascript. It consists of three templates:
- `nbJsFromCodeInit` - Creates a new code script that further code can be added to later.
- `addCodeToJs` - Adds to an existing code script
- `addToDocAsJs` - Takes the Nim code in a script and compiles it to javascript. 
Here is a basic example:
"""

nbCode:
  let script = nbJsFromCodeInit:
    echo "Hello world!"
  let x = 3.14
  script.addCodeToJs(x):
    echo "Pi is roughly ", x
  ## Uncomment this line:
  ##script.addToDocAsJs()
script.addToDocAsJs()
nbJsShowSource("This is the complete script:")


nbText: hlMd"""
The reason `script.addToDocAsJs()` is commented out is just a limitation of nimib not handling nested blocks well.
If you now go to your browser's javascript console you should see `Hello world` and `Pi is roughly 3.14` printed there.
What is up with `script.addCodeToJs(x)` though? Why is `(x)` needed? It is because we have to capture the value of `x`
to be able to use it in the javascript. The code block will basically be copy-pasted into a separate file and
compiled into javascript. And `x` isn't defined there so we have to capture it. This is true for any variable that
we want to use that is defined outside the script blocks.

## nbJsFromCode
This is basically a shorthand for running `nbJsFromCodeInit` and `addToDocAsJs` in a single call:
```nim
let x = 3.14
nbJsCode(x):
  echo "Pi is roughly ", x
```

## nbKaraxCode

If you want to write a component using karax this is the template for you!
A normal karax program has the following structure:
```nim
nbJsFromCode(rootId):
  import karax / [kbase, karax, karaxdsl, vdom, compact, jstrutils, kdom]

  karaxCode  # some code, set up global variables for example

  proc createDom(): VNode =
    result = buildHtml(tdiv):
      karaxHtmlCode # html karax code

  setRenderer(createDom, root=rootId.cstring)
```
where `karaxCode` and `karaxHtmlCode` can be arbitrary code. Using `nbKaraxCode` it can instead be written as:
```nim
nbKaraxCode:
  karaxCode
  karaxHtml:
    karaxHtmlCode
```
This reduces the boilerplate and makes for more readable code! Karax is automatically imported for you (the modules in `karax / prelude`) and `karaxHtml`
is a template that writes `createDom` and `setRenderer` for you so you only have to provide the body of the `buildHtml` call. Here's a basic example:
"""

nbCode:
  template karaxExample =
    let x = 3.14
    nbKaraxCode(x):
      var message = "Pi is roughly " & $x
      karaxHtml:
        p:
          text message
        button:
          text "Click me!"
          proc onClick() =
            message = "Poof! Gone!"

nbText: "This is the output this code produces:"

karaxExample()

nbSave
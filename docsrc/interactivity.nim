import nimib

nbInit

nbText: hlMd"""
# Creating interactive components in nimib

Nimib can easily be used to create static content with `nbText` and `nbCode`, but did you know that you can create interactive
content as well? And that you can do it all in Nim even! This can be achieved using either the `nbJsFromCode`-API or `nbKaraxCode`.
They work by compiling Nim code into javascript and adding it to the resulting HTML file.
This means that arbitrary Javascript can be written but also that Karax, which compiles to javascript, also can be used.

## nbJsFromCode
This is the fundamental API used for compiling Nim-snippets to javascript.
Here is a basic example:
"""

nbCode:
  let x = 3.14
  nbJsFromCodeInBlock(x):
    echo "Hello world!"
    echo "Pi is roughly ", x

nbText: hlMd"""
If you now go to your browser's javascript console you should see `Hello world` and `Pi is roughly 3.14` printed there.
What is up with `nbJsFromCode(x)` though? Why is `(x)` needed? It is because we have to capture the value of `x`
to be able to use it in the javascript. The code block will basically be copy-pasted into a separate file and
compiled into javascript. And `x` isn't defined there so we have to capture it. This is true for any variable that
we want to use that is defined outside the script blocks. 

The code that you pass to `nbJsFromCode` will internally be put inside a `block`, so things like `import`s which need to be top-level statements
will need to be done using `nbJsFromCodeGlobal`. Code defined using `nbJsFromCodeGlobal` will be visible to all `nbJsFromCode` blocks. So if you want
to have communication between different code blocks, you have to set it up using a global variable here. An example if how this would work is this:
"""

nbCode:
  nbJsFromCodeGlobal:
    import std / dom # this will be imported for all your nbJs blocks
    var globalVar = 1
  nbJsFromCode:
    echo "First block: ", globalVar
    globalVar += 1
  nbJsFromCode:
    echo "Second block: ", globalVar

nbText: hlMd"""
If you look in the console you should see that it prints out `1` in the first block and `2` in the second block.

## nbKaraxCode

If you want to write a component using karax this is the template for you!
A normal karax program has the following structure:
```nim
nbJsFromCode(rootId):
  include karax / prelude

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

nbText: "This is the output this code produces when called:"

karaxExample()

nbText: hlMd"""
## Internal workings
### nbJsFromCode
The way this works is that each `nbJsFromCode` is put inside a separate `block` inside a common file. So if we have 10 `nbJsFromCode` blocks in
our code, we will have 10 `block`s in the final code that will be compiled. Any code passed to `nbJsFromCodeGlobal` will be put at the top of the file
without any blocks. Here's a simple schematic:
```nim
global code here (imports and global variables)
block:
  first nbJsFromCode
block:
  second nbJsFromCode
block:
  third nbJsFromCode
```

### nbKaraxCode
`nbKaraxCode` works a bit differently, there each code block will be compiled in its own file so there is no global scope.
So (`nbJsFromCode` + `nbJsFromCodeGlobal`) and `nbKaraxCode` are totally isolated from each other. 
"""

nbSave
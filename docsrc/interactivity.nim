import nimib

nbInit

nbText: hlMd"""
# Creating interactive components in Nimib

Nimib can easily be used to create static content with `nbText` and `nbCode`, but did you know that you can create interactive
content as well? And that you can do it all in Nim even! This can be achieved using either the `nbNewCode`-API or a convenience
wrapper around it called `nbJsCode`. They work by compiling Nim code into javascript and adding it to the resulting HTML file.
This means that arbitrary Javascript can be written but also that Karax, which compiles to javascript, also can be used.

## nbNewCode
This is the fundamental API used for compiling Nim-snippets to javascript. It consists of three templates:
- `nbNewCode` - Creates a new code script that further code can be added to later.
- `addCode` - Adds to an existing code script
- `addToDocAsJs` - Takes the Nim code in a script and compiles it to javascript. 
Here is a basic example:
"""

nbCode:
  let script = nbNewCode:
    echo "Hello world!"
  let x = 3.14
  script.addCode(x):
    echo "Pi is roughly ", x
  ## Uncomment this line:
  ##script.addToDocAsJs()
script.addToDocAsJs()

nbText: hlMd"""
The reason `script.addToDocAsJs()` is commented out is just a limitation of nimib not handling nested blocks well.
If you now go to your browser's javascript console you should see `Hello world` and `Pi is roughly 3.14` printed there.
What is up with `script.addCode(x)` though? Why is `(x)` needed? It is because we have to capture the value of `x`
to be able to use it in the javascript. The code block will basically be copy-pasted into a separate file and
compiled into javascript. And `x` isn't defined there so we have to capture it. This is true for any variable that
we want to use that is defined outside the script blocks.

## nbJsCode
This is basically a shorthand for running `nbNewCode` and `addToDocAsJs` in a single call:
```nim
let x = 3.14
nbJsCode(x):
  echo "Pi is roughly ", x
```
"""

nbSave
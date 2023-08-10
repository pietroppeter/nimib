import nimib

nbInit

nbText: hlMd"""
# Creating interactive components in nimib

Nimib can easily be used to create static content with `nbText` and `nbCode`, but did you know that you can create interactive
content as well? And that you can do it all in Nim even! This can be achieved using either the `nbJsFromCode`-API or `nbKaraxCode`.
They work by compiling Nim code into javascript and adding it to the resulting HTML file.
This means that arbitrary Javascript can be written but also that Karax, which compiles to javascript, can be used.

In the same way that code from nbCode blocks are all compiled into a single file,
all code to be compiled in javascript will be put in a single file. 
This has the advantage that a single compilation is performed
and code from a previous block can be used in subsequent blocks.
The api looks like this:

- `nbJsFromCode`: nim code will be appended to the file and compiled during `nbSave`.
- `nbJsFromCodeInBlock`: same as `nbJsFromCode` but the code is put inside a `block`.
- `nbJsFromCodeGlobal`: the code here will be put at the top of the file.

If you wish to compile to a separate file you can do that.
Indeed this is what is done for a special block that allows you to use karax without boilerplate:

- `nbJsFromCodeOwnFile`: compile to js as its own file.
- `nbKaraxCode`: Sugar on top of `nbJsFromCodeOwnFile` for writing Karax components.

## nbJsFromCode
This is the fundamental API used for compiling Nim-snippets to javascript.
Here is a basic example:
"""

nimibCode:
  nbJsFromCode:
    let x = "Hello world!"
    echo x

nbText: hlMd"""
If you now go to your browser's javascript console you should see `Hello world` printed there.
So the code we passed to `nbJsFromCode` has been compiled to Javascript and is run by your browser!

### Capturing variables
If you have a variable in your code that you want to access inside a
nbJs-block, you have to capture it. This can be done by passing it to the block like this:
"""
nimibCode:
  # This variable is defined in C-land
  let captureVariable = 3.14
  nbJsFromCode(captureVariable): # capture it
    # use it in JS-land
    echo "Pi is roughly ", captureVariable
nbText: hlMd"""
If you look at the console you should see that it prints out `Pi is roughly 3.14`.
The capturing is done by serializing the variable to JSON, so the captured type has to support it.

Capturing variables is especially important when creating reusable components as they allow you to
generate the HTML using `nbRawHtml` and then pass in the ids of the elements by capturing them.
Examples of this can be seen in the [counters tutorial](counters.html).


## nbJsFromCodeInBlock
`nbJsFromCodeInBlock` works the same as `nbJsFromCode`, except that it puts the code inside a block.
This is a feature which is important if you are making a reusable piece of code, like a component.
This is because it allows you to reuse the same variable name in multiple blocks. 
Using `nbJsFromCode` would yield a `redefinition of variable` error. 
Here is an example showing how the same variable name can be used:
"""
nimibCode:
  nbJsFromCodeInBlock:
    let sameVariable = "First block"
    echo sameVariable
  nbJsFromCodeInBlock:
    let sameVariable = "Second block"
    echo sameVariable

nbText: hlMd"""
The case when this is really needed is when you have a `nbJsFromCodeInBlock` inside a template like this:
"""
nimibCode:
  template jsGoodbyeWorld() =
    nbJsFromCodeInBlock:
      let s = "Good bye world"
      echo s

  jsGoodbyeWorld()
  # Without block the second call would give `redefinition of 's'`
  jsGoodbyeWorld()


nbText: hlMd"""
If you look in the console you should see that it prints out `Good bye world` once for each call to `jsGoodbyeWorld` call.

Because the code is put inside of a block, any code needing to be put at the top-level (like imports)
must be done in a separate `nbJsFromCode` or `nbJsFromCodeGlobal` before it.

## nbJsFromCodeGlobal
`nbJsFromCodeGlobal` works similarly to `nbJsFromCode`, except that it places the code at the top of the generated js file.
So it is well suited for `import`s and defining global variables you want to be able to access in multiple blocks. 
Code defined here is available in all `nbJsFromCode` and `nbJsFromCodeInBlock` blocks.
"""

nimibCode:
  nbJsFromCodeGlobal:
    import std / dom # this will be imported for all your nbJs blocks
    var globalVar = 1
  nbJsFromCode:
    echo "First block: ", globalVar
    globalVar += 1
  nbJsFromCode:
    echo "Second block: ", globalVar

nbText: hlMd"""
## nbJsFromCodeOwnFile
The above-mentioned nbJs blocks are all compiled in the same file. But if you want to compile a code block
in its own file you can use `nbJsFromCodeOwnFile`. This also means you can't access any variables defined
in for example `nbJsFromCodeGlobal`.

## nbKaraxCode

If you want to write a component using karax this is the template for you!
A normal karax program has the following structure:
```nim
nbJsFromCodeOwnFile(rootId):
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

nbText: "Another example on how to use `nbKaraxCode` can be found in the [caesar document](./caesar.html) by clicking the `Show Source` button at the bottom."

nbText: hlMd"""
## nbCodeDisplay and nbCodeAnd

We introduce in this section two generic templates that can be useful when used with the
templates of `nbJsFromCode` family.

### Display code in nbJsFromCode with nbCodeDisplay

If you wish to display the code used in one of `nbJsFromCode`, `nbJsFromCodeInBlock`, `nbJsFromCodeGlobal`
you can use `nbCodeDisplay` (which can be used in general with any template that does not show code by itself):
"""
nimibCode:
  nbCodeDisplay(nbJsFromCodeInBlock):
    echo "hi nbCodeDisplay"
nbText: hlMd"""

Note that in this same document we gave examples of two other methods
to show code:

- `nimibCode`: to show the code as you would use it in a nimib file
- `nbCode` + template: create a template (e.g. `karaxExample`) inside a `nbCode` and call the template later.

### Running the same code with both c and js backends using nbCodeAnd

If you want to run some code both in C and js backends, you can use `nbCodeAnd`:
"""
nimibCode:
  nbCodeAnd(nbJsFromCodeInBlock):
    echo "hi nbCodeAnd"

nbText: hlMd"""
## Internal workings
### nbJsFromCode
Any code defined in `nbJsFromCode`, `nbJsFromCodeInBlock` and `nbJsFromCodeGlobal` will be pasted into a common file.
- Any code passed to `nbJsFromCodeGlobal` will be put at the top of the file without any blocks. 
- Any code passed to `nbJsFromCode` will be placed in the order they are called without any blocks.
- Any code passed to `nbJsFromCodeInBlock` will be placed in the order they are called inside blocks.

Here is an example of how the code will be ordered:
```nim
nbJsFromCode:
  echo 1
nbJsFromCodeInBlock:
  echo 2
nbJsFromCodeGlobal:
  echo 3
nbJsFromCode:
  echo 4
nbJsFromCodeGlobal:
  echo 5
```
This will be transformed into something like this:
```nim
echo 3 # Global is placed at the top

echo 5 # the other Global

echo 1 # no block for nbJsFromCode

block:
  echo 2 # placed inside block

echo 4 # no block
```

### nbKaraxCode
`nbKaraxCode` works a bit differently, there each code block will be compiled in its own file so there is no global scope.
So (`nbJsFromCode` + `nbJsFromCodeGlobal`) and `nbKaraxCode` are totally isolated from each other. 

### Caveats
Because of the way Nim gensym's variable names in the generated Javascript code, compiling two identical `nbKaraxCode` would
cause Nim to generate the same variable names for the variables defined in them. An example is `varName_123456`. This is really bad as changing the variable in
one component would change it in the other one as well! The solution we are using for this is to bump gensym by 1 each time we compile a
`nbKaraxCode`. So a variable being generated as `varName_123456` the first time will be generated as `varName_123457` the second time. 

This works well for most scenarios, but there is still a small risk that it will generate variable names that collide **if**
you are defining multiple different variables with the same name in your code. For example:
"""
nimibCode:
  nbKaraxCode:
    var counter: int
    block:
      var counter: int

nbText: hlMd"""
The two variables `counter` are different variables but have the same name. Lets say the generated names for them the first time we compile this block are
`counter_1` and `counter_2` for simplicity. The next time the generated names have been incremented with one and is instead `counter_2` and `counter_3`.
And here the problem lies: `counter_2` is generated both times we compile the block! So this could lead to unwanted interactions between the two codes!
The solution is stated above: don't name multiple separate variables the same in a `nbKaraxCode` or `nbJsFromCodeOwnFile` block! 
This isn't a problem for the other nbJs blocks luckily. 
"""
nbText: hlMd"""
### nbHappyxCode
HappyX is an emerging alternative to Jester (on the back-end) and Karax(on the front end). It aims to streamline the syntax for writing full-stack applications and to allow more flexibility in its single page applications, which use a routing mechanism to switch between different pages for the app. It is being actively developed and some of the syntax for the DSL may change, so the introduction will be brief.

The system for HappyX in nimib is analogous to the system for Karax. Note the parts of a typical Karax code block.

```nim
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
```
Here's how it changes for HappyX:

"""
nimibCode:
  template happyxExample =
    let x = 3.14
    nbHappyxCode(x):
      var message = remember fmt"pi is roughly {x}"
      happyxRoutes:
        "/":
          p:
           {message}
          tButton:
            "Click me!"
            @click(
              message.set("Poof! Gone!"))

nbText: "This is the output this code produces when called:"

happyxExample()

nbText: hlMd"""
There are many differences worth noticing, like use embedding of `fmt`'s `{}` to make a text node from data or the more prolific use of the prefix `t` before html tags (which is stylistic, as it's an optional disambiguator in happyX. The key thing to get you going, though, is that:

`nbKaraxCode` becomes `nbHappyxCode` -- obviously

`karaxHtml` becomes `happyxRoutes`  -- this is due to differences in the DSLs. Karax uses a `buildHtml()` macro directly when creating VNodes and components. Happyx, on the other hand, enters into the front end DSL with an `appRoutes()` macro since the blocks beneath it like `"/":` define the different routes or 'subpages' of the app. So `happyxRoutes` imitates the `appRoutes` that it is meant to replace.

There is **one other note for users of happyX**. The event handlers beginning in `@` must be called unambiguously. The more normal block declaration with `:` will not work in the current commit. HappyX does some massaging with its macros to make the syntax work in either case but plain Nim doesn't recognize `@click: <do stuff>` as a call. The best strategy for resolving the inconsistency hasn't been decided yet, and a potential refactor as happyX continues development may resolve it spontaneously.
"""
nbSave

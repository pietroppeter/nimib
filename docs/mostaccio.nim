import nimib

nbInit
nbDoc.darkMode
nbText: """# mustache man (5)

[mustache](https://mustache.github.io/) is a logic-less template system
with implementations available in multiple languages.

In nim there are two implementations:

* [nim-mustache](https://github.com/soasme/nim-mustache)
* [moustachu](https://github.com/fenekku/moustachu)

[nimib](https://pietroppeter.github.io/nimib/) uses `nim-mustache` and takes
specific advantage of its feature for in-memory partials to store default templates.

Below I will show examples of usage of `mustache` using `nim-mustache`,
mostly replicating [mustache(5)](https://mustache.github.io/mustache.5.html) man page
([why (5)?](https://en.wikipedia.org/wiki/Man_page#Manual_sections)).
"""
nbCode: import mustache
nbText: """
## SYNOPSIS

A typical mustache template:
"""
nbCode:
  var tmpl = """
Hello {{name}}
You have just won {{value}} dollars!
{{#in_california}}
Well, {{taxed_value}} dollars, after taxes.
{{/in_california}}
"""
nbText: "Given the following context:" # using context instead of hash
nbCode:
  var context = newContext()
  context["name"] = "Chris"
  context["value"] = 10_000
  context["taxed_value"] = 10000 - (10000 * 0.4)
  context["in_california"] = true
nbText: "Will produce the following:"
nbCode:
  echo tmpl.render(context)
nbText: """
## DESCRIPTION

Mustache can be used for HTML, config files, source code - anything.
It works by expanding tags in a template using values provided in a context
object.

We call it "logic-less" because there are no if statements, else clauses, or for loops.
Instead there are only tags.
Some tags are replaced with a value, some nothing, and others a series of values.
This document explains the different types of Mustache tags.

> in this document we use the `context` keyword instead of referring to it as a hash or object
> as in the original document

## TAG TYPES

Tags are indicated by the double mustaches. `{{person}}` is a **tag**, as is `{{#person}}`.
In both examples, we'd refer to person as the key or tag key.
Let's talk about the different types of tags.

### Variables

The most basic tag type is the variable.
A `{{name}}` tag in a basic template will try to find the **name** key in the current context.
If there is no **name** key, the parent contexts will be checked recursively.
If the top context is reached and the **name** key is still not found, nothing will be rendered.

All variables are HTML escaped by default.
If you want to return unescaped HTML, use the triple mustache: `{{{name}}}`.

You can also use & to unescape a variable: `{{& name}}`.
This may be useful when changing delimiters (see "Set Delimiter" below).

By default a variable "miss" returns an empty string.
This can usually be configured in your Mustache library.
The Ruby version of Mustache supports raising an exception in this situation, for instance.

Template:
""" # is there a way to raise the exception in nim-mustache?
nbCode:
  tmpl = """
* {{name}}
* {{age}}
* {{company}}
* {{{company}}}
* {{&company}}"""
nbText: "Context:"
nbCode:
  context = newContext()
  context["name"] = "Chris"
  context["company"] = "<b>Github</b>"
nbText: "Output:"
nbCode:
  echo tmpl.render(context)
nbText: """
> added the `{{&company}}` to clarify that it is just an alternative syntax with the same result
> as the triple mustache.

### Sections

Sections render blocks of text one or more times, depending on the value of the key in the current context.

A section begins with a pound and ends with a slash.
That is, `{{#person}}` begins a "person" section while `{{/person}}` ends it.

The behavior of the section is determined by the value of the key.

#### False Values or Empty Lists

If the person key exists and has a value of false or an empty list, the HTML between the pound and slash will not be displayed.

Template:
"""
nbCode:
  tmpl = """
Shown.
{{#person}}
  Never shown!
{{/person}}"""
nbText: "Context:"
nbCode:
  context = newContext()
  context["person"] = false
nbText: "Output:"
nbCode:
  echo tmpl.render(context)
nbText: """
#### Non-Empty Lists

If the **person** key exists and has a non-false value,
the HTML between the pound and slash will be rendered and displayed one or more times.

When the value is a non-empty list, the text in the block will be displayed once for each item in the list.
The context of the block will be set to the current item for each iteration. In this way we can loop over collections.

Template:
"""
nbCode:
  tmpl = """
{{#repo}}
  <b>{{name}}</b>
{{/repo}}"""
nbText: "Context:"
nbCode:
  import json
  context = newContext()
  context["repo"] = %* [
    { "name": "resque" },
    { "name": "hub" },
    { "name": "rip" }
  ]
# add a note to explain better what is Context and what can be casted to a context value?
nbText: "Output:"
nbCode:
  echo tmpl.render(context)

nbText: """
#### Lambdas

When the value is a callable object, such as a function or lambda, the object will be invoked and passed the block of text.
The text passed is the literal block, unrendered.
`{{tags}}` will not have been expanded - the lambda should do that on its own. In this way you can implement filters or caching.

Template:
"""
nbCode:
  tmpl = """
{{#wrapped}}
  {{name}} is awesome.
{{/wrapped}}"""
nbText: "Context:"
nbCode:
  import strutils
  context = newContext()
  context["name"] = "Willy"
  context["wrapped"] = proc(s: string, c: Context): string = "<b>" & s.strip.render(c) & "</b>"
nbText: "Output:"
nbCode:
  echo tmpl.render(context)
nbText: """
> note that we need to `strutils.strip` the string in order to obtain the expected
> whitespace behaviour
> (see discussion in [soasme/mustache/issues/8](https://github.com/soasme/nim-mustache/issues/8))"""

nbText: """
#### Non-False Values

When the value is non-false but not a list,
it will be used as the context for a single rendering of the block.

Template:
"""
nbCode:
  tmpl = """
{{#person?}}
  Hi {{name}}!
{{/person?}}"""
nbText: "Context:"
nbCode:
  context = newContext()
  context["person?"] = %* { "name": "Jon" }
nbText: "Output:"
nbCode:
  echo tmpl.render(context)
nbText: """
### Inverted Sections

An inverted section begins with a caret (hat) and ends with a slash.
That is `{{^person}}` begins a "person" inverted section while `{{/person}}` ends it.

While sections can be used to render text one or more times based on the value of the key,
inverted sections may render text once based on the inverse value of the key.
That is, they will be rendered if the key doesn't exist, is false, or is an empty list.

Template:
"""
nbCode:
  tmpl = """
{{#repo}}
  <b>{{name}}</b>
{{/repo}}
{{^repo}}
  No repos :(
{{/repo}}"""
nbText: "Context:"
nbCode:
  context = newContext()
  let empty: seq[string] = @[]
  context["repo"] = empty  # does not work with seq or array or also with %* []
nbText: "Output:"
nbCode:
  echo tmpl.render(context)
nbText: """
### Comments

Comments begin with a bang and are ignored. The following template:
"""
nbCode:
  tmpl = """<h1>Today{{! ignore me }}.</h1>"""
nbText: "Will render as follows:"
nbCode:
  echo tmpl.render(newContext())
nbText: """
### Partials

Partials begin with a greater than sign, like `{{> box}}`.

Partials are rendered at runtime (as opposed to compile time),
so recursive partials are possible. Just avoid infinite loops.

They also inherit the calling context.
Whereas in an [ERB](http://en.wikipedia.org/wiki/ERuby) file you may have this:

```
<%= partial :next_more, :start => start, :size => size %>
```

Mustache requires only this:

```
{{> next_more}}
```

Why? Because the `next_more.mustache` file will inherit
the size and start methods from the calling context.

In this way you may want to think of partials as
includes, imports, template expansion, nested templates,
or subtemplates, even though those aren't literally the case here.

For example, this template and partial:
"""
nbCode:
  let base = """
<h2>Names</h2>
{{#names}}
  {{> user}}
{{/names}}
"""
  let user = "<strong>{{name}}</strong>\n"
nbText: "Can be thought of as a single, expanded template:"
nbCode:
  let expanded = """
<h2>Names</h2>
{{#names}}
  <strong>{{name}}</strong>
{{/names}}
"""
nbText: """
> `nim-mustache` allows to use partials in-memory.
> By default nim-mustache looks for `.mustache` files in current directory
> but the behaviour of where to find partials (which directories or in-memory)
> can be fully customized
> (see [here](https://github.com/soasme/nim-mustache#read-partials-from-memory)).
>
> Below we show an example where we only search in-memory.
"""
nbCode:
  import tables
  let partials = {
    "base": base,
    "user": user,
    "expanded": expanded
  }.toTable
  
  context = newContext(searchDirs = @[], partials=partials)
  context["names"] = %* [
    { "name": "resque" },
    { "name": "hub" },
    { "name": "rip" }
  ]

  echo "{{>base}}".render(context)
nbCode:
  echo "{{>expanded}}".render(context)
nbText: """
### Set Delimiter

Set Delimiter tags start with an equal sign and change the tag delimiters from {{ and }} to custom strings.

Consider the following contrived example:

"""
nbCode:
  tmpl = """
* {{default_tags}}
{{=<% %>=}}
* <% erb_style_tags %>
<%={{ }}=%>
* {{ default_tags_again }}
"""
nbText: """
Here we have a list with three items. The first item uses the default tag style, the second uses erb style as defined by the Set Delimiter tag, and the third returns to the default style after yet another Set Delimiter declaration.

According to ctemplates, this "is useful for languages like TeX,
where double-braces may occur in the text and are awkward to use for markup."

Custom delimiters may not contain whitespace or the equals sign.

> adding an example of usage of set delimiter feature
""" # probably also useful for delayed rendering
nbCode:
  context = newContext()
  context["default_tags"] = "one"
  context["erb_style_tags"] = "two"
  context["default_tags_again"] = "three"
  echo tmpl.render(context)

## COPYRIGHT
## SEE ALSO
nbSave
# idea: document that shows all spec tests of nim mustache (do this in nblog)
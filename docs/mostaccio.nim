import nimib

nbInit
nbDarkMode
nbText: """# Example of usage of mustache

From [nim-mustache](https://github.com/soasme/nim-mustache).

## Usage

Step 1.
"""
nbCode:
  import mustache, tables
nbText: "Step 2."
block:
  nbCode:
    var c = newContext()
    c["i"] = 1
    c["f"] = 1.0
    c["s"] = "hello world"
    c["a"] = @[{"k": "v"}.toTable]
    c["t"] = {"k": "v"}.toTable
    c["l"] = proc(s: string, c: Context): string = "<b>" & s.render(c) & "</b>"
  nbBlock.code = nbBlock.code.escapeTag
  nbText: "Step 3."
  nbCode:
    let s = """
{{i}} {{f}} {{s}}
{{#a}}
  {{k}}
{{/a}}

{{#t}}
  {{k}}
{{/t}}

{{#l}}
  {{s}}
{{/l}}
"""
    echo(s.render(c))

#[
nbText: """## Other examples

not taken from [nim-mustache](https://github.com/soasme/nim-mustache).
"""
block:
  nbCode:
    var c = newContext()
    var s = """
{{highlight}}{{^highlight}}<default>
{{/highlight}}
"""
    echo s.render c
  nbBlock.code = nbBlock.code.escapeTag
  nbBlock.output = nbBlock.output.escapeTag
  nbText: "In order to get the default tag probably rendered I had to escape it (both in code and output)"
  nbCode:
    c["highlight"] = "<custom>"
    echo s.render c
  nbText: "rendering in mustache does automatic escaping"
  nbCode:
    s = "{{> highlight }}"
    echo s.render c
  nbBlock.output = nbBlock.output.escapeTag
  nbText: "unless you use a partial (no escaping by mustache, I did it manually in order to have it appear here)"
]#
nbSave

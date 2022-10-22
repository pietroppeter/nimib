# Contributing to nimib
You are interested in contributing to nimib? The you have come to the right place!
Note that using nimib and sharing more nim code around is **already** contributing to nimib.
But this is the guide for contributing code to nimib!

## What can I help with?
Both small and large contributions are welcomed! If you have an idea, open an issue and discuss it with us. Otherwise,
have a look at the [open issues](https://github.com/pietroppeter/nimib/issues) and see if anything peaks your interest.
You can also use github [discussion forum](https://github.com/pietroppeter/nimib/discussions) if you are not sure about what to ask.

## Project Structure
There are 4 main folders in the project:
- `docsrc/`: Here the source files for the documentation are located.
- `docs/`: Here the built documentation is located. You will only find committed some static files.
- `tests`: All unit-tests are located here.
- `src`: Here the implementation of `nimib` is located
  - `nimib.nim`: This file is the glue that exports the entire library. Most of the exported procs and templates are implemented here.
  - `nimib/`
    - `blocks.nim`: Here the `newNbBlock` template is defined.
    - `boost.nim`: Here functionality related to nimiBoost is defined. For example the string-highlighting templates like `hlMd`.
    - `capture.nim`: The logic of the `captureStdout` template which allows you to capture everything that is `echo`'d in a code block.
    - `config.nim`: Logic related to loading `nimib.toml`. 
    - `docs.nim`: Procs acting on `NbDoc`. For example `write` to write a document to file and `open` to open the written file in a browser.
    - `gits.nim`: Git-related logic.
    - `highlight.nim`: Logic related to static highlighting of Nim code.
    - `jsutils.nim`: Here the underlying logic of the `nbJs` blocks are located.
    - `options.nim`: Logic related to parsing runtime options when building a document.
    - `paths.nim`: Wrapper on top of the compiler's `pathutils`.
    - `renders.nim`: Here all the backends are defined. `partials`, `renderPlans` and `renderProcs` are defined here.
    - `sources.nim`: The logic of `codeAsInSource` is located here.
    - `themes.nim`: Here the default theme is located. If you are making your own theme, this is a good reference to start from.
    - `types.nim`: The core types like `NbDoc`, `NbBlock` are defined.

## How to add a new block

- add the logic in `nimib.nim`
- add the rendering in `nimib\renders.nim`
- add some test in `tests` (if it make sense)
- add an example document or modify an existing document to show usage
- add a mention of the new block in the readme
- add a line in the changelog

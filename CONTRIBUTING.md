# Contributing to nimib
You are interested in contributing to nimib? The you have come to the right place!
Note that using nimib and sharing more nim code around is **already** contributing to nimib.
But this is the guide for contributing code to nimib!

## What can I help with?
Both small and large contributions are welcomed! If you have an idea, open an issue and discuss it with us. Otherwise,
have a look at the [open issues](https://github.com/pietroppeter/nimib/issues) and see if anything peaks your interest.

There might be some issues marked as [good first issue](https://github.com/pietroppeter/nimib/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22):
those are issues where we have already a clear idea on what needs to be done and sometimes even code for the fix;
they are especially good to familiarize oneself with the codebase and the process of contributing to open source.

You can also use github [discussion forum](https://github.com/pietroppeter/nimib/discussions) if you are not sure about what to ask.

We also organize [Nimib speaking hours](https://github.com/pietroppeter/nimib/discussions/categories/nimib-speaking-hours), a semi regular
meeting of nimib's maintainers (Pietro and Hugo) where we welcome users and contributors (even potential ones).
These are announced on the discussion forum, [look at the special forum category](https://github.com/pietroppeter/nimib/discussions/categories/nimib-speaking-hours) for when we have the next one (or ask if it is not yet planned).

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
- add an example in `allblocks.nim`
  - ⚠️ currently `README.md` depends on `docsrc\index.nim`, you will have to modify `docsrc\index.nim` and run `nimble readme` to update the readme. we will remove this dependency, see https://github.com/pietroppeter/nimib/issues/141 

## CI and deploy preview

documentation is built in CI and we have **deploy preview** built with netlify. Once all checks have run succesfully the last one will contain a link to the deploy preview. This is very useful to make sure the documents still build so make sure to check it when you work on the internals of nimib.

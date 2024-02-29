## Naming

- not sure I still like the name backend for the rendering engine
  that changes from blocks to string (and could be a themed html, a json, markdown...)

### notes on backends

- I could implement specific behaviours:
  - markdown backend defaults to html backend when not defined
  - html backend could default to a commented json output when not defined
  - json backend should always be defined
    - but stuff can be marked as to be skipped, e.g. the default theme should not be serialized

## Third day - Feb 29

- goal: add json backend
- useful distraction: added a potential idea for sugar for creating blocks
- interesting question: now NbDoc is special, what if I make it non special?
- an idea I am realizing:
  - all side effects should happen during block creation
  - block rendering should be kept pure
  - in particular this means that block that need an id from global nb object need to generate it at block creation time!
- reminder for later: to fully support custom container blocks I will need to add in
  Nb object something that tells me where to add next block
- removed minilib, not useful since I would need import and that's a different problem

todo:
- [x] restructured minib and added sugar for blocks
- [x] json backend (hugo's work is great!)

## Second day - Feb 28

- [x] review Hugo solution for oop
- [x] define a scope and make explicit goals and assumptions
- answer why OOP question
- start working on it, starting from api

### scope

- blocks:
  - nbBlock
  - nbCode, nbText, nbImage, nbSummaryDetails
- commands:
  - nbInit, nbSave
- output on save:
  - a basic html document with water.css
- support all 3 backends: html, json, md
- support 2 themes: default, debug (json in html)
- capture? maybe but no capture blocks inside other capture blocks
- try to minimize use of external templating system
  - pluggable templating system?

### minib3

implementation of above scope, structure:
- minib: main library and example
- minilib: non focus code that comes from existing nimib

todo:
- [x] structure
- [x] implement nbText, nbImage
- [x] implement nbSave (html backend, default theme, echo to terminal)
  - [x] refactor NbDoc as NbBlock and add Nb object
  - [x] NbRender and NbRenderFunc
  - [x] single backend (for now)
  - [x] nb.render blk
  - [x] nbImageToHtml
  - [x] nbTextToHtml
  - [x] nbDocToHtml
- [ ] implement json backend
- later:
  - md backend
  - nbCode, nbSummaryDetails
  - sugar for block creation
  - ...

decisions:
- 1) what do I pass to the render function?
  - docs and any container block will need the full backend
  - currently passing the whole Nb object but it might be an overkill
- 2) where is the default backend defined?
  - currently in Nb object (same as before)


#### key understanding

- I think I want to make NbDoc a NbBlock and basically remove the mustache templating!
  (could still be reintroduced in a NbLegacyDoc for compatibility reasons)

## Pair programming session - Feb 27

GOALS of TODAY: pair program, get ideas and motivation.
Achieved.

Main highlights:
- why I want to do OOP? need to be able to answer that
- start from API (in particular locality of definition of blocks)
- define a Scope of what I want to support
- is this an extension of a templating system?

### details

preparation

annoying:
- just noticed that this PR broke locally my tests: https://github.com/pietroppeter/nimib/pull/211/files
- I am still using 1.6! not good!
- still do not have a way to switch easily

plan for today:
- this is a summary of nimib and refactoring: https://gist.github.com/pietroppeter/0a3699531c8059eea9094e076ac15f9f
- discuss and see critical points
- if we manage to code stuff, better

plan:
- let's start in a sandbox environment from scratch
- a new NbBlock type
- goals:
  - support container blocks
  - inheritance
  - user can customize method (how? oop? or I just add a closure?)
  - support json backend
  - should work well with multi-language support
    - might come from json backend
  - improve locality of block definition
- current mechanism
  - does not support container blocks
  - blocks are defined in two places
- how to handle the customization of backend?
  - willing to sacrifice this at the moment
  - but ideally 
- not in scope
  - serialization and deserialization through jsony
    - Hugo will take care of that



discussion:
- **decision**: base block should be a containers block?
  - yes: you mimic html where every node can have children nodes
  - (argument for no) if yes all blocks inheriting would need to take into account the children blocks in the templating
  - example of nbImage: argument for no
- idea: we could start with locality and start from api and work backwards


what kind of blocks do we have:
- a source block: where I need to capture the source code generating the block
- a capturing block: where stdout is captured
- a slim block: with no body
- a block with body:
  - body can be executed
  - body can be discarded
  - (body can be altered) - no example
- a container block: that can contain other blocks inside
- blocks can have side effects: e.g. write to a file, read from a file
- needs rendering procs (postprocess), could be backend specific

examples:
- nbCode: source, capturing, withBody(executed), needs postprocess (highlighting)
- nbText: slim block, needs postprocess (mdToHtml)
- nbImage: slim block
- nbSummaryDetails: container block

a new minib:
- skip capturing
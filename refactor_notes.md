todo:

- [ ] be able to run nim r docs/hello (also with nimibPreviewCodeAsInSource)
  - [x] new NewBlock with test (that works for NbCode and NbText and custom version of those)
  - [ ] new nbText and nbCode
  - [ ] new nbSave
- [ ] be able to run the rest of documentation
  - [ ] nbImage
  - [ ] nbFile
  - [ ] add also nbAudio, nbVideo? (with new doc examples)
  - [ ] add task nimble docs to build docs
- [ ] cleanup
  - [ ] remove old newBlock
  - [ ] remove manageErrors (never used)
- [ ] check that projects that depend on nimib are not broken
  - [ ] nimibook
  - [ ] scinim/getting-started
  - [ ] nimislides

notes:

- testing will also be improved (did not notice that ptest is turned off)
- (I could also almost pass to an improved doc generation workflow... - problem with README though...)
- [breaking change] code will be stripped by default (as a sort of normalization)
  - with this change I might able to simplify also tests in tsources? should I normalize in the same way?
- all templates have been moved outside of nbInit (no more unused warning!)
- log will move in newBlock? will it be newBlock(cmd: string, body, blockImpl: untyped) so that I can call a log at the end?
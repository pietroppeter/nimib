todo:

- [ ] be able to run nim r docs/hello (also with nimibPreviewCodeAsInSource)
- [x] new NewBlock with test (that works for NbCode and NbText and custom version of those)
- [ ] new nbText and nbCode
- [ ] new nbSave

notes:

- [breaking change] code will be stripped by default (as a sort of normalization)
  - with this change I might able to simplify also tests in tsources? should I normalize in the same way?
import macros
import types, capture

macro toStr*(body: untyped): string =
  (body.toStrLit)

proc newBlock*(kind: NbBlockKind, code: string): NbBlock =
  # I cannot use this directly in nbBlocks (nbText, nbCode, ...)
  # or it will substitute kind and body fields with their values
  result = NbBlock(kind: kind, code: code)
  result.context = newContext(searchDirs = @[])  # searchDirs=@[] gives error, why?

template manageErrors*(identBlock, body: untyped) =
  # not used yet!
  try:
    body
  except:
    let
      e = getCurrentException()
      msg = getCurrentExceptionMsg()
    identBlock.error = "ERROR: Got exception " & repr(e) & " with message " & msg

template nbTextBlock*(identBlock, identContainer, body: untyped) =
  # assume body is a string
  identBlock = newBlock(nbkText, toStr(body))  # nbDoc.flags.update(flags)
  identBlock.renderPlan = nbTextBlockDefaultSteps
  identBlock.output = block:
    body
  identContainer.blocks.add identBlock

template nbCodeBlock*(identBlock, identContainer, body: untyped) =
  identBlock = newBlock(nbkCode, toStr(body))
  identBlock.renderPlan = nbCodeBlockDefaultSteps
  captureStdout(identBlock.output):
    body
  identContainer.blocks.add identBlock

template nbFreeBlock*(identBlock, identContainer, body: untyped) =
  identBlock = newBlock(nbkCode, toStr(body))
  body
  identContainer.blocks.add identBlock

import strformat, strutils
import nimib

nbInit

nbText: """
## Secret talk with a computer
Let me show you how to talk with the computer like a [real hacker](https://mango.pdf.zone/)
and incidentally you might learn the basics of [nimib](https://github.com/pietroppeter/nimib).
### A secret message
Inside this document is hidden a secret message. I will ask the computer to spit it out:
"""

let secret = [104, 101, 108, 108, 111, 44, 32, 119, 111, 114, 108, 100]

nbCode:
  echo secret

nbText: fmt"""
what does this integer sequence mean?
Am I supposed to [recognize it](https://oeis.org/search?q={secret.join("%2C+")}&language=english&go=Search)?

### A cryptoanalytic weapon
Luckily I happen to have a [nim](https://nim-lang.org/) implementation of
a recently declassified top-secret cryptoanalytic weapon:"""

nbCode:
  func decode(secret: openArray[int]): string =
    ## classified by NSA as <strong>TOP SECRET</strong>
    for c in secret:
      result.add char(c)

nbText: """
  ### The great revelation
  Now I can just apply it to my secret message and
  finally decrypt what the computer wants to tell me:"""

nbCode:
  let msg = decode secret
  echo msg  # what will it say?

nbText:
  fmt"_Hey_, there must be a bug somewhere, the message (`{msg}`) is not even addressed to me!"

nbSave

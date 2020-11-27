# nimib 🐳

nim 👑 driven ⛵ publishing ✍

**status**: *in flux, not officially released a 0.1*

* [repository](https://github.com/pietroppeter/nimib)
* [documentation](https://pietroppeter.github.io/nimib)

## 👋 🌍 Example Usage

[examples/hello_nimib.nim](https://github.com/pietroppeter/nimib/blob/main/examples/hello_nimib.nim)

```nim
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
    ## classified by NSA as <a href="https://www.nsa.gov/Portals/70/documents/news-features/declassified-documents/cryptologic-histories/EC-121.pdf">TOP SECRET</a>
    # so secret that they do not want me to tell you and they will remove this message!
    for c in secret:
      result.add char(c)

nbText: """
  ### The great revelation
  Now I can just apply it to my secret message and
  finally decrypt what the computer wants to tell me:"""

nbCode:
  let msg = decode secret
  echo msg

nbText:
  fmt"_Hey_, there must be a bug somewhere, the message (`{msg}`) is not even addressed to me!"

nbSave # use nbShow to automatically open a browser tab with html output
```

compile and run:

```
nim c examples/hello_nimib
examples/hello_nimib docs/hello_nimib.html > examples/hello_nimib.md
```

output:

* [html](https://pietroppeter.github.io/nimib/hello_nimib.html)
* [markdown](https://github.com/pietroppeter/nimib/blob/main/examples/hello_nimib.md)

## ❓ Q & A

### why the name?

corruption of [ninib](https://www.vocabulary.com/dictionary/Ninib):

> a solar deity; firstborn of Bel and consort was Gula;
> god of war and the _chase_ and agriculture; sometimes identified with biblical *Nimrod*

also:

> He explains that the seven directions were interpreted by the Babylonian theologians
> as a reference to the seven great celestial bodies, the sun and moon, Ishtar, Marduk, Ninib, Nergal and Nabu.
>
> This process, which reached its culmination in the post-Khammurabic period, led to identifying
> the planet Jupiter with Marduk, Venus with Ishtar, Mars with Nergal, Mercury with Nebo, and Saturn with Ninib.

and I should not need to tell you what [Marduk](https://jupyter.org/) is
and why [Saturn is the best planet](https://www.theatlantic.com/science/archive/2016/01/a-major-correction/422514/).

### why the whale 🐳?

why do you need a logo when you have emojis?

no particular meaning about the whale apart the fact that I like the emoji and this project is something I have been [chasing](https://en.wikipedia.org/wiki/Captain_Ahab) for a while
and I expect to be chasing it indefinitely.

also googling `nimib whale` you might learn about [Skeleton Coast](https://en.wikipedia.org/wiki/Skeleton_Coast) which is definitely a plus.

### why the emojis?

because I made a [package](https://github.com/pietroppeter/nimoji) for that and someone has to use it

### why the Q & A?

because [someone made it an art form](https://github.com/oakes/vim_cubed#q--a)
and they tell me [imitation is the sincerest form of flattery](https://www.goodreads.com/quotes/558084-imitation-is-the-sincerest-form-of-flattery-that-mediocrity-can)


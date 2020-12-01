## Secret talk with a computer
Let me show you how to talk with the computer like a [real hacker](https://mango.pdf.zone/)
and incidentally you might learn the basics of [nimib](https://github.com/pietroppeter/nimib).
### A secret message
Inside this document is hidden a secret message. I will ask the computer to spit it out:

```nim
echo secret
```

```
[104, 101, 108, 108, 111, 44, 32, 119, 111, 114, 108, 100]
```

what does this integer sequence mean?
Am I supposed to [recognize it](https://oeis.org/search?q=104%2C+101%2C+108%2C+108%2C+111%2C+44%2C+32%2C+119%2C+111%2C+114%2C+108%2C+100&language=english&go=Search)?

### A cryptoanalytic weapon
Luckily I happen to have a [nim](https://nim-lang.org/) implementation of
a recently declassified top-secret cryptoanalytic weapon:
```nim
func decode(secret: openArray[int]): string =
  ## classified by NSA as <a href="https://www.nsa.gov/Portals/70/documents/news-features/declassified-documents/cryptologic-histories/EC-121.pdf">TOP SECRET</a>
  for c in secret:
    result.add char(c)

```

  ### The great revelation
  Now I can just apply it to my secret message and
  finally decrypt what the computer wants to tell me:
```nim
let msg = decode secret
echo msg
```

```
hello, world
```

_Hey_, there must be a bug somewhere, the message (`hello, world`) is not even addressed to me!

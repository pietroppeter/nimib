import std / [strutils]
import nimib

nbInit

let rootId = "caesar_root"
nbRawOutput: """<div id="$1"></div>""" % [rootId]
nbCodeToJs(rootId):
  import std / [strutils, math]
  import karax / [kbase, karax, karaxdsl, vdom, compact, jstrutils, kdom]

  proc encryptChar(c: char, key: int): char =
    let c_normalized = c.ord - 'a'.ord # a is 0, z is 25
    var c_encrypted = euclMod(c_normalized + key, 26) + 'a'.ord
    result = c_encrypted.char

  proc encryptString(s: string, key: int): string =
    for c in s:
      if c in 'a' .. 'z':
        result.add encryptChar(c, key)
      else:
        result.add c

  var cipherText, plainText: string
  let ciphertextId = "ciphertext"
  let plaintextId = "plaintext"
  let keySliderId = "keySlider"
  let encodeButtonId = "encodeButton"
  let decodeButtonId = "decodeButton"
  var keyString = "0"
  proc createDom(): VNode =
    result = buildHtml(tdiv):
      label:
        text "Plaintext"
      input(id = plaintextId)
      hr()
      label:
        text "Ciphertext"
      input(id = ciphertextId)
      hr()
      label:
        text "Key: " & keyString
      input(`type` = "range", min = "-25", max = "25", value = "0", id = keySliderId):
        proc oninput() =
          let slider = getVNodeById(keySliderId)
          keyString = $slider.getInputText
      button(id = encodeButtonId):
        text "Encrypt"
        proc onClick() =
          let key = ($getVNodeById(keySliderId).getInputText).parseInt
          let plaintext = ($getVNodeById(plaintextId).getInputText).toLower
          let ciphertext = encryptString(plaintext, key)
          getVNodeById(ciphertextId).setInputText ciphertext
      button(id = decodeButtonId):
        text "Decrypt"
        proc onClick() =
          let key = ($getVNodeById(keySliderId).getInputText).parseInt
          let ciphertext = ($getVNodeById(ciphertextId).getInputText).toLower
          let plaintext = encryptString(ciphertext, -key) # encrypt with -key to decrypt
          getVNodeById(plaintextId).setInputText plainText
  setRenderer(createDom, root=rootId.cstring)


nbSave
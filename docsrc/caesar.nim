import std / [strutils]
import nimib

nbInit


let rootId = "caesar_root"
nbRawOutput: """<div id="$1"></div>""" % [rootId]
nbCodeToJs(rootId):
  import std / [strutils, math]
  import karax / [kbase, karax, karaxdsl, vdom, compact, jstrutils, kdom]

  proc encryptChar(c: char, shift: int): char =
    let c_normalized = c.ord - 'a'.ord # a is 0, z is 25
    var c_encrypted = euclMod(c_normalized + shift, 26) + 'a'.ord
    result = c_encrypted.char

  proc encryptString(s: string, shift: int): string =
    for c in s:
      if c in 'a' .. 'z':
        result.add encryptChar(c, shift)
      else:
        result.add c

  var cipherText, plainText: string
  let ciphertextId = "ciphertext"
  let plaintextId = "plaintext"
  let shiftSliderId = "shiftSlider"
  let encodeButtonId = "encodeButton"
  let decodeButtonId = "decodeButton"
  var shiftString = "3"
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
        text "Shift/Key: " & shiftString
      input(`type` = "range", min = "0", max = "25", value = "3", id = shiftSliderId):
        proc oninput() =
          let slider = getVNodeById(shiftSliderId)
          shiftString = $slider.getInputText
      button(id = encodeButtonId):
        text "Encrypt"
        proc onClick() =
          let shift = ($getVNodeById(shiftSliderId).getInputText).parseInt
          let plaintext = ($getVNodeById(plaintextId).getInputText).toLower
          let ciphertext = encryptString(plaintext, shift)
          getVNodeById(ciphertextId).setInputText ciphertext
      button(id = decodeButtonId):
        text "Decrypt"
        proc onClick() =
          let shift = ($getVNodeById(shiftSliderId).getInputText).parseInt
          let ciphertext = ($getVNodeById(ciphertextId).getInputText).toLower
          let plaintext = encryptString(ciphertext, -shift) # encrypt with -shift to decrypt
          getVNodeById(plaintextId).setInputText plainText
  setRenderer(createDom, root=rootId.cstring)


nbSave
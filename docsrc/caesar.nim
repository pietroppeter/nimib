import std / [strutils]
import nimib

nbInit


nbKaraxCode:
  import std / [strutils, math]

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
  karaxHtml:
    label:
      text "Plaintext"
    textarea(id = plaintextId, placeholder = "You can encrypt this message or you can try to decrypt the message below...")
    hr()
    label:
      text "Ciphertext"
    textarea(id = ciphertextId):
      text "oek vekdt jxu iushuj auo! weet meha! dem oek sqd uqj q squiqh iqbbqt qi q fhypu, okcco!"
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
  


nbSave
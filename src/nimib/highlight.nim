import std/strutils
from std/cgi import xmlEncode

import packages/docutils/highlite

func nimNormalize(s: string): string =
  # Copied from strutils.normalize
  # Normalizes a Nim identifier to all lowercase:
  # - All letters except the first one are lower-cased
  # - Underscores are ignores
  result = newString(s.len)
  var j = 0
  for i in 0 .. len(s) - 1:
    # First char is case-sensitive
    if i == 0: 
      result[j] = s[i]
      inc j
    # Lowercase all upper-case chars
    elif s[i] in {'A'..'Z'}:
      result[j] = chr(ord(s[i]) + (ord('a') - ord('A')))
      inc j
    # Ignore underscores
    elif s[i] != '_':
      result[j] = s[i]
      inc j
  # Trim the string if it's shorter than the original
  if j != s.len: setLen(result, j)

# Constants below are taken from highlight.js and saem/vscode-nim
const builtin = [
  "int", "int8", "int16", "int32", "int64", 
  "uint", "uint8", "uint16", "uint32", "uint64",
  "float", "float32", "float64",
  "bool", "char", "string", "cstring", "pointer", 
  "expr", "stmt", "untyped", "typed", "void", "auto", 
  "any", "range", "openArray", "varargs", "seq", "set",
  "clong", "culong", "cchar", "cschar", "cshort", "cint", "csize",
  "clonglong", "cfloat", "cdouble", "clongdouble", "cuchar", "cushort",
  "cuint", "culonglong", "cstringArray", "array"
]

const literal = [
  "stdin", "stdout", "stderr", "result", "true",
  "false", "Inf", "NegInf", "NaN", "nil"
]

const commonFuncs = [
  "new", "await", "assert", "echo", "defined", "declared",
  "newException", "countup", "countdown", "high", "low"
]

func tokClass(str: string, kind: TokenClass): string = 
  let norm = nimNormalize(str)
  case norm
  of builtin: "hljs-built_in"
  of literal: "hljs-literal"
  of commonFuncs: "hljs-keyword"
  else:
    case kind
    of gtKeyword: "hljs-keyword"
    of gtComment, gtLongComment: "hljs-comment"
    of gtStringLit, gtLongStringLit, gtCharLit, gtRawData: "hljs-string"
    # All number types
    of gtDecNumber..gtFloatNumber: "hljs-number"
    of gtRegularExpression: "hljs-regexp"
    of gtEscapeSequence, gtDirective: "hljs-meta"
    of gtIdentifier:
      # Most types are PascalCase (start with an upper-case letter)
      if norm.len > 0 and norm[0] in {'A'..'Z'}: "hljs-type"
      else: ""
    else: ""

func highlightNim*(code: string): string = 
  var g: GeneralTokenizer
  g.initGeneralTokenizer(code)

  while true:
    g.getNextToken(langNim)
    # Get the string for the current identifier
    var istr = substr(code, g.start, g.length + g.start - 1)

    case g.kind
    of gtEof: break
    else:
      # Get Highlight.js-compatible token class
      let cls = tokClass(istr, g.kind)
      # Don't forget to escape (X|HT)ML stuff
      istr = istr.xmlEncode()
      result.add(
        if cls != "": "<span class=\"$2\">$1</span>" % [istr, cls]
        else: istr
      )
  
  g.deinitGeneralTokenizer()

import types, logging, parsetoml, jsony, std / [json, os, math, sequtils]

const nimibVersion* = "0.4.3"
  ## nimib's version. Keep it in sync with `version` in nimib.nimble
  ## (tests/tnimib.nim checks that they match).

proc getNimibVersion*(): string = nimibVersion

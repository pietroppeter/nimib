import std/strformat

const nimibLog* = not defined(nimibNoLog)

proc log*(label: string, message: string) =
  when nimibLog:
    if label.len > 0:
      echo fmt"[nimib.{label}] {message}"
    else:
      echo fmt"[nimib] {message}"

proc log*(message: string) =
  log("", message)

proc info*(message: string) =
  log("info", message)

proc error*(message: string) =
  log("error", message)

proc warning*(message: string) =
  log("warning", message)

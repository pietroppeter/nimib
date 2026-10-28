#!/usr/bin/env bash
# Prepare an environment (CI runner, sandbox, cloud agent container) to build nimib documents
# and run the skill checks and evals. Safe to rerun.
#
#   bash harness/setup-nim.sh            # nimib + nimibook + karax from the nimble registry
#   NIMIB_SRC=. bash harness/setup-nim.sh  # install nimib from a local checkout (e.g. the repo root)
#
# Env: NIM_NIGHTLY (default latest-version-2-2), NIM_HOME (default $HOME/.local/nim),
#      SKIP_KARAX=1 to skip karax.
set -euo pipefail

NIM_NIGHTLY="${NIM_NIGHTLY:-latest-version-2-2}"
NIM_HOME="${NIM_HOME:-$HOME/.local/nim}"
export PATH="$NIM_HOME/bin:$HOME/.nimble/bin:$PATH"

log() { echo "[setup-nim] $*"; }

# 1. Nim compiler
if ! command -v nim >/dev/null 2>&1; then
  log "nim not found: downloading GitHub nightly $NIM_NIGHTLY (nim-lang.org is often blocked in sandboxes)"
  tmp="$(mktemp -d)"
  if curl -sSfL -o "$tmp/nim.tar.xz" "https://github.com/nim-lang/nightlies/releases/download/$NIM_NIGHTLY/linux_x64.tar.xz"; then
    tar -xf "$tmp/nim.tar.xz" -C "$tmp"
    rm -rf "$NIM_HOME" && mkdir -p "$(dirname "$NIM_HOME")"
    mv "$tmp"/nim-*/ "$NIM_HOME"
  else
    log "nightly download failed; trying PyPI (pip install nimlang)"
    python3 -m pip install --user nimlang
    log "nimlang installed: it provides 'nim' but not 'nimble'; clone deps and use --path (see skills/nimib/references/setup.md)"
  fi
  rm -rf "$tmp"
fi
log "$(nim -v | head -1)"

# 2. nimble package list (nimble's own download fails behind some HTTPS proxies with status 405)
mkdir -p "$HOME/.nimble"
if [ ! -s "$HOME/.nimble/packages_official.json" ]; then
  log "fetching nimble package list"
  curl -sSfL -o "$HOME/.nimble/packages_official.json" \
    https://raw.githubusercontent.com/nim-lang/packages/master/packages.json || log "could not fetch package list (nimble will try itself)"
fi

# 3. PCRE runtime (nim-markdown uses std/re, which dlopens libpcre.so.3)
if ! ldconfig -p 2>/dev/null | grep 'libpcre\.so\.[13]' >/dev/null; then   # no -q: SIGPIPE + pipefail
  log "libpcre not found: installing libpcre3"
  if command -v apt-get >/dev/null 2>&1; then
    SUDO=""; [ "$(id -u)" -ne 0 ] && SUDO="sudo"
    $SUDO apt-get update -qq && $SUDO apt-get install -y -qq libpcre3 || log "WARNING: could not install libpcre3"
  else
    log "WARNING: install PCRE (libpcre3 / pcre) with your package manager"
  fi
fi

# 4. packages
if command -v nimble >/dev/null 2>&1; then
  if [ -n "${NIMIB_SRC:-}" ]; then
    log "installing nimib from $NIMIB_SRC"
    (cd "$NIMIB_SRC" && nimble install -y)
  else
    (cd "${TMPDIR:-/tmp}" && nimble install -y nimib)
  fi
  # run from a neutral dir: inside a nimble project (e.g. the nimib repo),
  # `nimble install pkg` installs the project's deps and silently skips pkg
  (cd "${TMPDIR:-/tmp}" && nimble install -y nimibook)
  [ -z "${SKIP_KARAX:-}" ] && (cd "${TMPDIR:-/tmp}" && nimble install -y karax@1.3.3) || true
  log "installed: $(ls "$HOME/.nimble/pkgs2" | sed 's/-[0-9a-f]\{40\}$//' | tr '\n' ' ')"
fi

# 5. smoke test
tmp="$(mktemp -d)"
printf 'import nimib\nnbInit\nnbCode:\n  echo "ok"\nnbSave\n' > "$tmp/smoke.nim"
(cd "$tmp" && nim r --hints:off --warnings:off -d:nimibQuiet smoke.nim >/dev/null && test -f smoke.html) \
  && log "smoke test OK: nimib builds documents" || { log "smoke test FAILED"; exit 1; }
rm -rf "$tmp"
echo "export PATH=\"$NIM_HOME/bin:\$HOME/.nimble/bin:\$PATH\""

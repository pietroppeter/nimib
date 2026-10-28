# Installing Nim and nimib

nimib 0.4 needs Nim >= 1.4 on paper; use Nim 2.x (CI tests stable and devel).
Dependencies (installed automatically by nimble): `fusion`, `markdown`,
`parsetoml`, `jsony`. Runtime: the markdown package uses `std/re`, which loads
**PCRE** (`libpcre.so.3`) dynamically on Linux.

## Usual ways

- **choosenim** (official installer): `curl https://nim-lang.org/choosenim/init.sh -sSf | sh`,
  then `export PATH=$HOME/.nimble/bin:$PATH`.
- **Package managers**: `brew install nim`, `scoop install nim`,
  `apt install nim` (Debian/Ubuntu packages are often old, check `nim -v`).
- **From PyPI**: `pip install nimlang` (or `uv add nimlang`) ships a Nim
  compiler in a wheel and uses `zig cc` from the `ziglang` package as C
  compiler, so it needs no system Nim or C compiler. nimib >= 0.4.2 works with
  it (it no longer needs the compiler sources or nimble at runtime). nimlang
  bundles atlas rather than nimble; dependencies can be cloned and passed with
  `--path:`.
- **Release tarballs / nightlies**: `https://nim-lang.org/download/nim-<ver>-linux_x64.tar.xz`,
  or `https://github.com/nim-lang/nightlies/releases` (e.g.
  `latest-version-2-2/linux_x64.tar.xz`); unpack and add `bin/` to `PATH`.
- **GitHub Actions**: `jiro4989/setup-nim-action@v2` or `iffy/install-nim@v5`;
  on `ubuntu-24.04` add `sudo apt-get install -y libpcre3` (newer Ubuntu
  images no longer package libpcre3).

Then:

```sh
nimble install -y nimib            # library
nimble install -y nimibook         # if you build books
nimble install -y karax            # only for nbKaraxCode
```

Check: `nim -v`, `nimble path nimib`, and build any small document.

## PCRE

Symptom: the document compiles, then fails at runtime with
`could not load: libpcre.so(.3|.1|)`. Fix: `sudo apt-get install -y libpcre3`
(Debian/Ubuntu), `dnf install pcre` (Fedora), `brew install pcre` (macOS).
On distributions that only ship PCRE2, install the legacy `pcre` package.

## Restricted networks, sandboxes, CI behind a proxy

Seen in sandboxed agent environments where nim-lang.org is blocked but GitHub
is reachable:

- Download the compiler from GitHub nightlies (see above) or PyPI (`nimlang`).
- `nimble` first downloads the package list; if that fails (`Refresh failed`,
  `Could not download: Server returned status: 405`, typical behind an HTTPS
  proxy that nimble's http client does not tunnel), fetch it yourself:
  `curl -sSfL -o ~/.nimble/packages_official.json https://raw.githubusercontent.com/nim-lang/packages/master/packages.json`
  and rerun `nimble install`. Packages themselves are cloned with git, which
  usually works through the proxy.
- Without nimble at all: `git clone` the dependencies and compile with
  `--path:<dep>/src` for each (nimib: fusion, markdown, parsetoml, jsony).

## Using a local checkout of nimib

To test documents against nimib `main` or a branch: `cd nimib && nimble install`
(installs that version), or point the compiler at the sources without
installing: `nim r --path:/path/to/nimib/src doc.nim` (nimib's own
`docsrc/config.nims` does `switch("path", "$projectDir/../src")`).

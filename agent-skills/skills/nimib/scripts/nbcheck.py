#!/usr/bin/env python3
"""Build a nimib document and check the rendered HTML.

usage:
  python3 nbcheck.py doc.nim [nim options...]      build with `nim r`, then check
  python3 nbcheck.py --html doc.html                only check an existing html file
  python3 nbcheck.py doc.nim --json                 machine-readable report

The build runs `nim r --hints:off --warnings:off [nim options] doc.nim` from the
current directory (nimib finds nimib.toml from there), reads nimib's log to find
the written file, then reports what the page contains and flags common
rendering mistakes. Exit code: 0 ok (warnings allowed), 1 build failed or
errors found, 2 usage error.
"""
import html
import json
import os
import re
import subprocess
import sys
from html.parser import HTMLParser


class Page(HTMLParser):
    """Collects the parts of a nimib page we care about (only inside <main>)."""

    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.title = ""
        self._in_title = False
        self.in_main = 0
        self.stack = []  # open tags inside main
        self.code_blocks = []  # nim code shown by nbCode (statically highlighted)
        self.outputs = []  # <pre class="nb-output">
        self.md_code = []  # <pre><code> from markdown (``` or indented)
        self.texts = []  # prose text chunks (outside pre/code/script)
        self.headings = []
        self.images = []
        self.scripts = 0
        self.figures = 0
        self._pre = None  # (kind, buffer)

    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if tag == "title":
            self._in_title = True
        if tag == "main":
            self.in_main += 1
            return
        if not self.in_main:
            return
        self.stack.append(tag)
        cls = a.get("class", "") or ""
        if tag == "pre":
            kind = "output" if "nb-output" in cls else "pre"
            self._pre = [kind, []]
        elif tag == "code" and self._pre is not None and self._pre[0] == "pre":
            self._pre[0] = "nim" if ("nim" in cls and "nohighlight" in cls) else "md"
            self._pre.append(cls)
        elif tag == "img":
            self.images.append(a.get("src", ""))
        elif tag == "script":
            self.scripts += 1
        elif tag == "figure":
            self.figures += 1

    def handle_endtag(self, tag):
        if tag == "title":
            self._in_title = False
        if tag == "main":
            self.in_main -= 1
            return
        if not self.in_main:
            return
        if tag == "pre" and self._pre is not None:
            kind, buf = self._pre[0], "".join(self._pre[1])
            if kind == "output":
                self.outputs.append(buf)
            elif kind == "nim":
                self.code_blocks.append(buf)
            elif kind == "md":
                self.md_code.append((buf, self._pre[2] if len(self._pre) > 2 else ""))
            # a bare <pre> (e.g. the file name of nbFile) is ignored
            self._pre = None
        if self.stack and self.stack[-1] == tag:
            self.stack.pop()
        elif tag in self.stack:
            while self.stack and self.stack.pop() != tag:
                pass

    def handle_data(self, data):
        if self._in_title:
            self.title += data
        if not self.in_main:
            return
        if self._pre is not None:
            self._pre[1].append(data)
            return
        if "script" in self.stack or "style" in self.stack or "code" in self.stack:
            return
        if self.stack and self.stack[-1] in ("h1", "h2", "h3", "h4", "h5", "h6"):
            self.headings.append(data.strip())
        if data.strip():
            self.texts.append(data)


def build(nim_file, nim_opts):
    cmd = ["nim", "r", "--hints:off", "--warnings:off", *nim_opts, nim_file]
    proc = subprocess.run(cmd, capture_output=True, text=True)
    out = proc.stdout + proc.stderr
    saved, cwd = None, os.getcwd()
    for line in out.splitlines():
        m = re.search(r"current directory: (.+)$", line)
        if m:
            cwd = m.group(1).strip()
        m = re.search(r"saving file: \]?\s*(.+)$", line)
        if m:
            saved = m.group(1).strip()
    path = None
    if saved:
        path = saved if os.path.isabs(saved) else os.path.normpath(os.path.join(cwd, saved))
    return proc.returncode, out, path, cmd


def guess_html(nim_file):
    base = os.path.splitext(nim_file)[0]
    for cand in (base + ".html", base + ".md"):
        if os.path.exists(cand):
            return cand
    return None


def check(html_path, nim_file=None):
    report = {"file": html_path, "errors": [], "warnings": [], "info": {}}
    text = open(html_path, encoding="utf-8").read()
    if html_path.endswith(".md"):
        report["info"]["markdown_chars"] = len(text)
        report["info"]["code_fences"] = text.count("```") // 2
        return report
    p = Page()
    p.feed(text)
    prose = "\n".join(p.texts)
    report["info"] = {
        "title": p.title.strip(),
        "headings": p.headings[:20],
        "nim_code_blocks": len(p.code_blocks),
        "outputs": len(p.outputs),
        "markdown_code_blocks": len(p.md_code),
        "images": p.images,
        "scripts_in_main": p.scripts,
        "prose_chars": len(prose),
    }
    if not p.code_blocks and not prose.strip() and not p.images and not p.scripts and not p.md_code:
        report["errors"].append("the page has no blocks: nothing between nbInit and nbSave, or blocks have no html renderer")
    if nim_file:
        rel = os.path.basename(nim_file)
        if p.title.strip().endswith(rel):
            report["warnings"].append(f"title is the default (file path '{p.title.strip()}'): set nb.title = \"...\" after nbInit")
    # markdown that did not render
    for line in prose.splitlines():
        s = line.strip()
        if re.match(r"^#{1,6}\s", s):
            report["warnings"].append(f"raw markdown heading in text (indentation or missing blank line?): {s[:80]!r}")
        elif s.startswith("```"):
            report["warnings"].append(f"raw code fence in text: {s[:80]!r}")
        elif re.search(r"\*\*[^*\s][^*]*\*\*", s):
            report["warnings"].append(f"raw **bold** markers in text: {s[:80]!r}")
    # prose that became a code block because of 4-space indentation
    for content, cls in p.md_code:
        words = re.findall(r"[A-Za-z]{3,}", content)
        looks_like_prose = len(words) >= 6 and not re.search(r"[=(){};:\[\]]|^\s*(import|let|var|proc|echo|def)\b", content, re.M)
        if not cls.strip() and looks_like_prose:
            report["warnings"].append(
                "text rendered as a code block (lines indented 4+ spaces in nbText?): " + repr(content.strip()[:80]))
    # fmt placeholders left in text (string not interpolated)
    for m in re.finditer(r"\{[A-Za-z_][\w.\[\]()]*\}", prose):
        report["warnings"].append(f"possible un-interpolated placeholder {m.group(0)} in text (missing & or fmt before the string?)")
        break
    # local images that do not exist
    base = os.path.dirname(os.path.abspath(html_path))
    for src in p.images:
        if re.match(r"^(https?:|data:|//)", src) or not src:
            continue
        if not os.path.exists(os.path.normpath(os.path.join(base, src))):
            report["warnings"].append(f"image not found relative to the page: {src} (nbImage urls are relative to the root, see SKILL.md)")
    if p.code_blocks and not p.outputs:
        report["info"]["note"] = "no code block produced output (only echo/stdout is shown)"
    for out in p.outputs:
        if re.search(r"(Error|Traceback|unhandled exception)", out):
            report["warnings"].append("an output contains an error message: " + repr(out.strip()[:80]))
    return report


def main(argv):
    if not argv or argv[0] in ("-h", "--help"):
        print(__doc__)
        return 2
    as_json = "--json" in argv
    argv = [a for a in argv if a != "--json"]
    if argv[0] == "--html":
        if len(argv) < 2:
            print(__doc__)
            return 2
        rep = check(argv[1])
    else:
        nim_file, opts = argv[0], argv[1:]
        code, out, path, cmd = build(nim_file, opts)
        if code != 0:
            lines = out.strip().splitlines()
            first_err = next((l for l in lines if "Error" in l), None)
            if as_json:
                print(json.dumps({"build": "failed", "command": " ".join(cmd), "first_error": first_err,
                                  "tail": lines[-30:]}, indent=2))
            else:
                print("BUILD FAILED:", " ".join(cmd))
                if first_err:
                    print("first error:", first_err)
                print("\n".join(lines[-30:]))
            return 1
        path = path or guess_html(nim_file)
        if not path or not os.path.exists(path):
            print("built, but could not find the output file (run without -d:nimibQuiet so nimib logs where it saves)")
            return 1
        rep = check(path, nim_file)
    if as_json:
        print(json.dumps(rep, indent=2))
    else:
        info = rep["info"]
        print(f"output: {rep['file']}")
        for k, v in info.items():
            print(f"  {k}: {v}")
        for w in rep["warnings"]:
            print("WARNING:", w)
        for e in rep["errors"]:
            print("ERROR:", e)
        print("OK" if not rep["errors"] else "FAILED")
    return 1 if rep["errors"] else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

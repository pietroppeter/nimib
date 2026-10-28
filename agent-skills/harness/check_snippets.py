#!/usr/bin/env python3
"""Compile the code the skills teach, so the skills cannot drift from nimib.

usage: python3 harness/check_snippets.py [--keep] [--verbose]

1. Every file in skills/*/examples/*.nim is built with nimib's nbcheck.py
   (compile + run + inspect the html). Pages with nbJs/karax are also opened in
   headless Chromium (when node + playwright are available) to catch JS errors.
2. Every ```nim fence in skills/**/*.md that is a complete document
   (has an `import ...nimib...` line and a top-level `nbSave` line) is
   extracted and built the same way.
3. Every ```nim fence that declares a nimibook (contains `nimibookCli`) is
   built as a book in a temporary folder: `init`, `build`, then bookcheck.py.

A fence can opt out with a line `# snippet: skip` (for deliberately broken code).
Fences that are fragments (no nbInit/nbSave) are not compiled here: put the
pattern in an example file instead.

Exit code 0 only if everything builds.
"""
import os
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SKILLS = os.path.join(ROOT, "skills")
NBCHECK = os.path.join(SKILLS, "nimib", "scripts", "nbcheck.py")
BROWSER = os.path.join(SKILLS, "nimib", "scripts", "browser_check.mjs")
BOOKCHECK = os.path.join(SKILLS, "nimibook", "scripts", "bookcheck.py")
VERBOSE = "--verbose" in sys.argv
KEEP = "--keep" in sys.argv


def have_module(mod):
    """True if `import mod` compiles (e.g. karax is installed)."""
    with tempfile.TemporaryDirectory() as d:
        f = os.path.join(d, "probe.nim")
        open(f, "w").write(f"import {mod}\n")
        return subprocess.run(["nim", "check", "--hints:off", f], capture_output=True).returncode == 0


def have_playwright():
    if not shutil.which("node"):
        return False
    r = subprocess.run(["node", "-e", "require('playwright')"], capture_output=True, cwd=ROOT)
    return r.returncode == 0


def run(cmd, cwd):
    r = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True)
    return r.returncode, r.stdout + r.stderr


def check_doc(path, results, label, browser):
    cwd = os.path.dirname(path)
    code, out = run([sys.executable, NBCHECK, os.path.basename(path)], cwd)
    ok = code == 0
    detail = out.strip().splitlines()
    if ok and browser and re.search(r"nbJs|nbKaraxCode|nbHappyxCode", open(path).read()):
        html = os.path.splitext(path)[0] + ".html"
        bcode, bout = run(["node", BROWSER, html], cwd)
        ok = bcode == 0
        detail += ["[browser] " + l for l in bout.strip().splitlines()]
    results.append((label, ok, detail))


def fences(md_path):
    text = open(md_path, encoding="utf-8").read()
    for m in re.finditer(r"^```nim\n(.*?)^```", text, re.S | re.M):
        yield text[: m.start()].count("\n") + 1, m.group(1)


def main():
    if not shutil.which("nim"):
        print("nim not found on PATH (see harness/setup-nim.sh)")
        return 2
    has_karax = have_module("karax/kbase")
    browser = have_playwright()
    print(f"karax: {'yes' if has_karax else 'no (karax snippets skipped)'}; browser checks: {'yes' if browser else 'no'}")
    results = []
    work = tempfile.mkdtemp(prefix="nimib-skill-snippets-")

    # 1. example files (copied, so the skill folder stays clean)
    for skill in sorted(os.listdir(SKILLS)):
        exdir = os.path.join(SKILLS, skill, "examples")
        if not os.path.isdir(exdir):
            continue
        dst = os.path.join(work, skill, "examples")
        shutil.copytree(exdir, dst)
        for f in sorted(os.listdir(dst)):
            if f.endswith(".nim"):
                src = open(os.path.join(dst, f)).read()
                if "nbKaraxCode" in src and not has_karax:
                    results.append((f"{skill}/examples/{f}", None, ["skipped: karax not installed"]))
                    continue
                check_doc(os.path.join(dst, f), results, f"{skill}/examples/{f}", browser)

    # 2./3. fenced snippets
    n = 0
    for dirpath, _, files in os.walk(SKILLS):
        if "/evals" in dirpath:
            continue
        for f in sorted(files):
            if not f.endswith(".md"):
                continue
            md = os.path.join(dirpath, f)
            rel = os.path.relpath(md, ROOT)
            for line, code in fences(md):
                if "# snippet: skip" in code:
                    continue
                n += 1
                label = f"{rel}:{line}"
                d = os.path.join(work, "snippets", f"s{n:03d}")
                os.makedirs(d)
                if "nimibookCli" in code:
                    open(os.path.join(d, "nbook.nim"), "w").write(code)
                    ok = True
                    detail = []
                    for cmd in ("init", "build"):
                        c, out = run(["nim", "r", "--hints:off", "--warnings:off", "nbook.nim", cmd], d)
                        detail += out.strip().splitlines()[-5:]
                        ok = ok and c == 0
                    if ok:
                        c, out = run([sys.executable, BOOKCHECK, "."], d)
                        detail += out.strip().splitlines()
                        ok = c == 0
                    results.append((label + " (book)", ok, detail))
                elif re.search(r"^import .*nimib", code, re.M) and re.search(r"^nbSave\b", code, re.M):
                    if "nbKaraxCode" in code and not has_karax:
                        results.append((label, None, ["skipped: karax not installed"]))
                        continue
                    if "useNimibook" in code:
                        # a chapter: needs a book around it
                        open(os.path.join(d, "nbook.nim"), "w").write(
                            'import nimibook\nvar book = initBookWithToc:\n  entry("Chapter", "chapter.nim")\nnimibookCli(book)\n')
                        os.makedirs(os.path.join(d, "book"))
                        open(os.path.join(d, "book", "chapter.nim"), "w").write(code)
                        c1, o1 = run(["nim", "r", "--hints:off", "--warnings:off", "nbook.nim", "init"], d)
                        c2, o2 = run(["nim", "r", "--hints:off", "--warnings:off", "nbook.nim", "build"], d)
                        results.append((label + " (chapter)", c1 == 0 and c2 == 0, (o1 + o2).strip().splitlines()[-8:]))
                    else:
                        p = os.path.join(d, "doc.nim")
                        open(p, "w").write(code)
                        check_doc(p, results, label, browser)

    failed = [r for r in results if r[1] is False]
    for label, ok, detail in results:
        mark = "SKIP" if ok is None else ("ok  " if ok else "FAIL")
        print(f"{mark} {label}")
        if (ok is False) or VERBOSE:
            for l in detail[-15:]:
                print("     " + l)
    print(f"\n{len(results) - len(failed)} passed or skipped, {len(failed)} failed (work dir: {work})")
    if not KEEP and not failed:
        shutil.rmtree(work, ignore_errors=True)
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())

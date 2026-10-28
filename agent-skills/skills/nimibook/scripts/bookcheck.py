#!/usr/bin/env python3
"""Check a built nimibook book.

usage: python3 bookcheck.py [book_root] [--json]

Run it from the folder that holds nimib.toml (or pass that folder). It reads
<homeDir>/book.json (written by `nim r nbook build` or `nim r nbook dump`) and
checks, for every non-draft TOC entry:
  - the source exists in srcDir and the html exists in homeDir
  - the page has the nimibook layout (sidebar) and lists every TOC title
  - the page content area is not empty
  - prev/next navigation links point to pages that exist
It also reports `.log` files left in srcDir by failed chapter builds.
Exit code 0 when there are no errors.
"""
import json
import os
import re
import sys
from html.parser import HTMLParser


def read_cfg(root):
    src, home = "book", "docs"
    path = os.path.join(root, "nimib.toml")
    if os.path.exists(path):
        section = None
        for line in open(path, encoding="utf-8"):
            line = line.strip()
            m = re.match(r"^\[(.+)\]$", line)
            if m:
                section = m.group(1).strip()
                continue
            m = re.match(r'^(srcDir|homeDir)\s*=\s*"(.*)"', line)
            if m and section == "nimib":
                if m.group(1) == "srcDir":
                    src = m.group(2)
                else:
                    home = m.group(2)
    return os.path.join(root, src), os.path.join(root, home)


class PageInfo(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.has_sidebar = False
        self.links = []
        self.in_main = 0
        self.main_text = []
        self.nav_links = []
        self._a_class = None

    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        cls = a.get("class", "") or ""
        if tag == "nav" and "sidebar" in (a.get("id", "") + cls):
            self.has_sidebar = True
        if "sidebar" in (a.get("id", "") or "") or "sidebar" in cls:
            self.has_sidebar = True
        if tag == "main":
            self.in_main += 1
        if tag == "a":
            href = a.get("href")
            if href:
                self.links.append(href)
                if "nav-chapters" in cls or "mobile-nav-chapters" in cls:
                    self.nav_links.append(href)

    def handle_endtag(self, tag):
        if tag == "main":
            self.in_main -= 1

    def handle_data(self, data):
        if self.in_main and data.strip():
            self.main_text.append(data.strip())


def main(argv):
    as_json = "--json" in argv
    argv = [a for a in argv if a != "--json"]
    if argv and argv[0] in ("-h", "--help"):
        print(__doc__)
        return 2
    root = argv[0] if argv else "."
    src_dir, home_dir = read_cfg(root)
    book_json = os.path.join(home_dir, "book.json")
    errors, warnings, pages = [], [], []
    if not os.path.exists(book_json):
        print(f"ERROR: {book_json} not found: run `nim r nbook build` (or `nim r nbook dump`) first")
        return 1
    book = json.load(open(book_json, encoding="utf-8"))
    entries = book.get("toc", {}).get("entries", [])
    titles = [e["title"] for e in entries]
    for e in entries:
        if e.get("isDraft"):
            continue
        src = os.path.join(src_dir, e["path"])
        out = os.path.join(home_dir, os.path.splitext(e["path"])[0] + ".html")
        page = {"title": e["title"], "source": src, "output": out}
        pages.append(page)
        if not os.path.exists(src):
            errors.append(f"missing source for '{e['title']}': {src}")
        if not os.path.exists(out):
            errors.append(f"missing output for '{e['title']}': {out}")
            continue
        info = PageInfo()
        info.feed(open(out, encoding="utf-8").read())
        text = open(out, encoding="utf-8").read()
        if not info.has_sidebar:
            errors.append(f"'{e['title']}' has no nimibook sidebar (did the chapter use nbInit(theme = useNimibook)?): {out}")
        missing = [t for t in titles if t not in text]
        if missing:
            warnings.append(f"'{e['title']}' sidebar does not list: {missing} (stale book.json? rebuild)")
        content = " ".join(info.main_text)
        page["content_chars"] = len(content)
        if len(content) < 20:
            warnings.append(f"'{e['title']}' has (almost) no content: {out}")
        base = os.path.dirname(out)
        for href in info.nav_links:
            target = href.split("#")[0]
            if target and not re.match(r"^(https?:|mailto:)", target):
                if not os.path.exists(os.path.normpath(os.path.join(base, target))):
                    errors.append(f"'{e['title']}' prev/next link points to a missing page: {href}")
    for dirpath, _, files in os.walk(src_dir):
        for f in files:
            if f.endswith(".log"):
                errors.append(f"build log left by a failed chapter: {os.path.join(dirpath, f)}")
    report = {"book_json": book_json, "entries": len(entries), "pages": pages, "errors": errors, "warnings": warnings}
    if as_json:
        print(json.dumps(report, indent=2))
    else:
        print(f"book: {book.get('cfg', {}).get('title', '?')} ({len(entries)} TOC entries, {len(pages)} pages)")
        for p in pages:
            print(f"  {p['title']}: {os.path.relpath(p['output'], root)} ({p.get('content_chars', 0)} chars)")
        for w in warnings:
            print("WARNING:", w)
        for e in errors:
            print("ERROR:", e)
        print("OK" if not errors else "FAILED")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

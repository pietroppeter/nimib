#!/usr/bin/env python3
"""Grade an agent run against an eval case without `claude plugin eval`.

usage:
  python3 harness/run_graders.py evals/<case> <run_dir> [--final-message file] [--json out.json]

<run_dir> is the folder the agent worked in (its files are what the graders
check). The deterministic graders of the case are evaluated here:
  - file_exists: path relative to run_dir
  - regex: on a file of run_dir, or on the final message (pass --final-message)
`llm` graders are listed as "needs judge" (grade them with an LLM or by hand),
and `tool_used`/`tool_order` as "n/a" (they need the transcript).

Writes a grading.json compatible with skill-creator's viewer
({"expectations": [{"text", "passed", "evidence"}], "summary": {...}}) to
<run_dir>/../grading.json unless --json is given. Use it to evaluate runs made
by any agent harness (subagents, other CLIs, CI) with the same cases.
"""
import json
import os
import re
import sys


def parse_md(path):
    text = open(path, encoding="utf-8").read()
    m = re.match(r"^---\n(.*?)\n---\n?(.*)$", text, re.S)
    if not m:
        return None, text
    return parse_yaml(m.group(1)), m.group(2).strip()


def parse_yaml(src):
    """Tiny YAML subset: `key: value` and one level of nested mapping."""
    out, cur = {}, None
    for line in src.splitlines():
        if not line.strip() or line.strip().startswith("#"):
            continue
        if line.startswith("  ") and cur is not None:
            k, _, v = line.strip().partition(":")
            out[cur][k.strip()] = scalar(v.strip())
            continue
        k, _, v = line.partition(":")
        k, v = k.strip(), v.strip()
        if v == "":
            out[k] = {}
            cur = k
        else:
            out[k] = scalar(v)
            cur = None
    return out


def scalar(v):
    if v.startswith('"') and v.endswith('"'):
        return json.loads(v)
    if v.startswith("[") and v.endswith("]"):
        return [x.strip() for x in v[1:-1].split(",") if x.strip()]
    if v in ("true", "false"):
        return v == "true"
    try:
        return int(v)
    except ValueError:
        return v


def js_flags(flags):
    f = 0
    if "i" in flags:
        f |= re.I
    if "m" in flags:
        f |= re.M
    if "s" in flags:
        f |= re.S
    return f


def grade(case_dir, run_dir, final_message=None):
    results = []
    gdir = os.path.join(case_dir, "graders")
    for name in sorted(os.listdir(gdir)):
        if not name.endswith(".md"):
            continue
        fm, body = parse_md(os.path.join(gdir, name))
        if not fm or "type" not in fm:
            continue
        typ = fm["type"]
        label = os.path.splitext(name)[0]
        if typ == "file_exists":
            path = fm["path"]
            want = fm.get("exists", True)
            have = os.path.exists(os.path.join(run_dir, path))
            results.append({"text": f"{path} {'exists' if want else 'does not exist'}", "passed": have == want,
                            "evidence": f"{path} {'found' if have else 'missing'}", "grader": label})
        elif typ == "regex":
            pattern = fm.get("pattern") or body
            target = fm.get("target", "last_message")
            match = fm.get("match", "contains")
            flags = js_flags(fm.get("flags", ""))
            if isinstance(target, dict):
                path = target["path"]
                src_label = path
                p = os.path.join(run_dir, path)
                content = open(p, encoding="utf-8", errors="replace").read() if os.path.exists(p) else None
            else:
                src_label = "final message"
                content = open(final_message, encoding="utf-8").read() if final_message and os.path.exists(final_message) else None
            if content is None:
                results.append({"text": f"{src_label} {match} /{pattern}/", "passed": False,
                                "evidence": f"{src_label} not available", "grader": label})
                continue
            hits = re.findall(pattern, content, flags)
            n = len(hits)
            if match == "contains":
                ok = n > 0
            elif match == "not_contains":
                ok = n == 0
            else:
                ok = n == int(match.split(":")[1])
            ev = f"{n} match(es)"
            if hits and isinstance(hits[0], str):
                ev += f", first: {hits[0][:80]!r}"
            results.append({"text": f"{src_label} {match} /{pattern}/", "passed": ok, "evidence": ev, "grader": label})
        elif typ in ("llm", "baseline"):
            results.append({"text": fm.get("criteria") or body, "passed": None, "evidence": "needs judge", "grader": label})
        else:
            results.append({"text": f"{typ} {fm.get('tool', '')}".strip(), "passed": None, "evidence": "n/a (needs transcript)", "grader": label})
    graded = [r for r in results if r["passed"] is not None]
    passed = sum(1 for r in graded if r["passed"])
    return {"expectations": results,
            "summary": {"passed": passed, "failed": len(graded) - passed, "total": len(graded),
                        "pass_rate": round(passed / len(graded), 2) if graded else 0.0}}


def main(argv):
    if len(argv) < 2 or argv[0] in ("-h", "--help"):
        print(__doc__)
        return 2
    case_dir, run_dir = argv[0], argv[1]
    final = argv[argv.index("--final-message") + 1] if "--final-message" in argv else None
    out = argv[argv.index("--json") + 1] if "--json" in argv else os.path.join(os.path.dirname(os.path.abspath(run_dir)), "grading.json")
    rep = grade(case_dir, run_dir, final)
    json.dump(rep, open(out, "w"), indent=2)
    for r in rep["expectations"]:
        mark = {True: "PASS", False: "FAIL", None: "----"}[r["passed"]]
        print(f"{mark} {r['text'][:110]}  [{r['evidence'][:70]}]")
    s = rep["summary"]
    print(f"{s['passed']}/{s['total']} deterministic graders passed -> {out}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

#!/usr/bin/env python3
"""Summarize a `claude plugin eval` trace.jsonl: tool calls, their results (truncated) and the final message.

usage: python3 harness/trace_summary.py path/to/trace.jsonl [--width 300]
"""
import json
import sys


def main(argv):
    if not argv:
        print(__doc__)
        return 2
    width = 300
    if "--width" in argv:
        width = int(argv[argv.index("--width") + 1])
    for line in open(argv[0], encoding="utf-8"):
        try:
            e = json.loads(line)
        except json.JSONDecodeError:
            continue
        t = e.get("type")
        if t == "assistant":
            for c in e["message"].get("content", []):
                if c.get("type") == "tool_use":
                    inp = c.get("input", {})
                    s = inp.get("command") or inp.get("skill") or inp.get("file_path") or json.dumps(inp)
                    print(f"> {c['name']}: {str(s)[:width]}")
                elif c.get("type") == "text" and c.get("text", "").strip():
                    print(f"  says: {c['text'].strip()[:width]}")
        elif t == "user":
            content = e.get("message", {}).get("content", [])
            if isinstance(content, list):
                for c in content:
                    if c.get("type") == "tool_result":
                        r = c.get("content")
                        if isinstance(r, list):
                            r = " ".join(x.get("text", "") for x in r if isinstance(x, dict))
                        r = str(r).replace("\n", " | ")
                        print(f"  <- {'ERROR ' if c.get('is_error') else ''}{r[:width]}")
        elif t == "result":
            print(f"RESULT ({e.get('subtype')}, turns={e.get('num_turns')}): {str(e.get('result', ''))[:width * 3]}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

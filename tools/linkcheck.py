"""Weekly link check (plan §5.6, §8.4): every checked video is still public
(YouTube oEmbed) and every source URL still answers.

  python -m tools.linkcheck
"""

from __future__ import annotations

import sys
import urllib.error
import urllib.parse
import urllib.request

from tools.pack.load import load


def fetch(url: str) -> int:
    req = urllib.request.Request(url, method="GET", headers={"User-Agent": "GanitaVeda link check"})
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            return r.status
    except urllib.error.HTTPError as e:
        return e.code
    except Exception:
        return 0


def main() -> int:
    c, _ = load()
    failures = []
    for m in c.media.values():
        if m["status"] != "checked":
            continue
        watch = f"https://www.youtube.com/watch?v={m['external_id']}"
        status = fetch("https://www.youtube.com/oembed?format=json&url=" + urllib.parse.quote(watch, safe=""))
        if status != 200:
            failures.append(f"{m['id']}: video not public (oEmbed {status})")
    for s in c.sources.values():
        if s.get("url"):
            status = fetch(s["url"])
            if not 200 <= status < 400:
                failures.append(f"{s['id']}: {s['url']} answered {status}")
    for f in failures:
        print(f"error: {f}")
    print(f"{len(failures)} broken links")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())

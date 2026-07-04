#!/usr/bin/env python3
"""Fetch an X/Twitter post (and its self-thread) via the FxTwitter API,
download all media, and print a JSON summary for composing a brain note.

- Uses api.fxtwitter.com (no auth). The public front-end URLs (fixupx.com /
  fxtwitter.com) 302-redirect to x.com and fail; only the api. subdomain works.
- Thread handling walks BACKWARD via replying_to_status while the author stays
  the same (a self-thread). Forward replies (tweets *after* the given one) are
  NOT reachable via this API — to capture a whole thread, pass the LAST tweet's
  URL. The script reports how many replies the newest captured tweet has so the
  caller can warn about this.

Usage:
    python3 fetch_thread.py <tweet-url-or-id> [--out DIR] [--max N]

Images are saved into --out (default: ~/brain/reference/twitter/attachments).
A JSON summary is printed to stdout.
"""
import sys, os, re, json, time, argparse, urllib.request

UA = "Mozilla/5.0 (brain capture-tweet skill)"


def http_json(url):
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=20) as r:
        return json.load(r)


def http_download(url, path):
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=30) as r, open(path, "wb") as f:
        f.write(r.read())


def parse_url(s):
    """Return (handle_or_None, id_or_None) from a URL, @handle/status/id, or bare id."""
    s = s.strip()
    m = re.search(r"(?:https?://)?[\w.]+/(\w+)/status(?:es)?/(\d+)", s)
    if m:
        return m.group(1), m.group(2)
    m = re.search(r"status(?:es)?/(\d+)", s)
    if m:
        return None, m.group(1)
    if re.fullmatch(r"\d+", s):
        return None, s
    return None, None


def fetch_tweet(handle, tid):
    forms = []
    if handle and handle.lower() not in ("i", "web", "status"):
        forms.append(f"https://api.fxtwitter.com/{handle}/status/{tid}")
    forms.append(f"https://api.fxtwitter.com/status/{tid}")
    last_err = None
    for u in forms:
        try:
            d = http_json(u)
            if isinstance(d, dict) and d.get("tweet"):
                return d["tweet"]
            last_err = f"no tweet in response from {u}"
        except Exception as e:  # noqa: BLE001
            last_err = f"{type(e).__name__}: {e} ({u})"
    raise RuntimeError(f"could not fetch tweet {tid}: {last_err}")


def ext_from_url(url):
    m = re.search(r"\.(jpg|jpeg|png|gif|webp|mp4)\b", url, re.I)
    return "." + m.group(1).lower() if m else ".jpg"


def datestr(tw):
    ts = tw.get("created_timestamp")
    if ts:
        return time.strftime("%Y-%m-%d", time.gmtime(int(ts)))
    return "unknown-date"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("url")
    ap.add_argument("--out", default=os.path.expanduser("~/brain/reference/twitter/attachments"))
    ap.add_argument("--max", type=int, default=50)
    args = ap.parse_args()

    handle, tid = parse_url(args.url)
    if not tid:
        print(json.dumps({"error": f"could not parse a tweet id from: {args.url!r}"}))
        sys.exit(1)

    os.makedirs(args.out, exist_ok=True)

    try:
        root = fetch_tweet(handle, tid)
    except Exception as e:  # noqa: BLE001
        print(json.dumps({"error": str(e)}))
        sys.exit(1)

    root_author = root["author"]["screen_name"].lower()

    # Walk backward through the self-thread (given tweet -> its ancestors).
    chain = [root]
    cur = root
    steps = 0
    while cur.get("replying_to_status") and steps < args.max:
        steps += 1
        try:
            parent = fetch_tweet(cur.get("replying_to"), cur["replying_to_status"])
        except Exception:  # noqa: BLE001
            break
        if parent["author"]["screen_name"].lower() != root_author:
            break  # replying to someone else -> not a self-thread; stop here
        chain.append(parent)
        cur = parent
    chain.reverse()  # chronological (root first)

    out = {"root_author": root["author"].get("name"), "root_handle": root["author"]["screen_name"],
           "count": len(chain), "tweets": []}

    for idx, tw in enumerate(chain, 1):
        date = datestr(tw)
        h = tw["author"]["screen_name"]
        images = []
        media = (tw.get("media") or {}).get("all") or []
        for m_i, m in enumerate(media, 1):
            url = m.get("url")
            if not url:
                continue
            fname = f"{date}-{h}-{tw['id']}-{m_i}{ext_from_url(url)}"
            try:
                http_download(url, os.path.join(args.out, fname))
                images.append({"file": fname, "type": m.get("type"),
                               "w": m.get("width"), "h": m.get("height")})
            except Exception as e:  # noqa: BLE001
                images.append({"file": None, "type": m.get("type"), "error": str(e), "url": url})
        body = tw.get("text")
        if not isinstance(body, str) or not body:
            rt = tw.get("raw_text")
            body = rt.get("text") if isinstance(rt, dict) else (rt if isinstance(rt, str) else "")
        out["tweets"].append({
            "n": idx,
            "id": tw["id"],
            "url": tw.get("url"),
            "author_name": tw["author"].get("name"),
            "handle": h,
            "date": date,
            "is_note_tweet": tw.get("is_note_tweet"),
            "text": body,
            "images": images,
        })

    # Forward-reply warning: the NEWEST captured tweet is chain[-1].
    newest = chain[-1]
    out["newest_reply_count"] = newest.get("replies")
    out["forward_replies_possible"] = bool(newest.get("replies"))
    out["attachments_dir"] = args.out
    print(json.dumps(out, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()

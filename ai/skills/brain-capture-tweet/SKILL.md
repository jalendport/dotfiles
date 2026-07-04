---
name: brain-capture-tweet
description: Capture an X/Twitter post or thread into the ~/brain vault — fetches the text, all images, and the self-thread via the FxTwitter API, then saves a drafted reference note (and distilled convention notes). Use when the user gives an x.com / twitter.com / fixupx.com / fxtwitter.com URL (or a tweet id) to save, clip, capture, or add to their brain / second brain.
---

Capture a tweet (or self-thread) into Jalen's brain vault at `~/brain`. Follow the vault's contracts in `~/brain/AGENTS.md` — this skill is the tweet-specific procedure. Everything you write is a **draft** (`status: draft`, `author: claude`); never self-promote to `best-practice`/`adopted`. Sync is automatic — don't run git.

## 1. Fetch the tweet, thread, and images
Run the helper (it uses `api.fxtwitter.com` — no auth; the plain fixupx/fxtwitter URLs 302 to x.com and fail, so always let the script hit the `api.` subdomain):

```bash
python3 ~/.claude/skills/brain-capture-tweet/fetch_thread.py "<TWEET_URL>"
```

It downloads all media into `~/brain/reference/twitter/attachments/` and prints JSON:
- `tweets[]` — the self-thread in chronological order; each has `text`, `date`, `handle`, `author_name`, `url`, `is_note_tweet`, and `images[]` (each with a saved `file` name).
- `forward_replies_possible` / `newest_reply_count` — if true, the newest captured tweet has replies the API **cannot** fetch forward.

If the JSON has an `error` key, report it and stop. If `forward_replies_possible` is true, tell Jalen at the end: "to capture a full thread, paste the **last** tweet's URL — this API only walks backward."

## 2. Read any code / text screenshots (don't paraphrase)
For each downloaded image that is a code or text screenshot, **Read it** (vision) from `~/brain/reference/twitter/attachments/<file>` and transcribe the code exactly. If part of a screenshot is cut off, transcribe what's visible and mark the rest `/* …cut off in source screenshot */` — never invent the missing part. Photos that are just pictures don't need transcription.

## 3. Write the reference note
Create `~/brain/reference/twitter/<date>-<handle>-<slug>.md` (`<date>` = first tweet's date, `<slug>` = a short kebab topic). Use today's date for `captured` (run `date +%F`). Follow the reference contract:

```yaml
---
type: reference
source: twitter
status: draft
author: "<author_name>"
handle: "@<handle>"
url: <url of the first tweet>
published: <first tweet date, YYYY-MM-DD>
captured: <today, YYYY-MM-DD>
tags: [reference, twitter, <topic tags>]
rating:
---
```
Body:
- `# <one-line gist>`
- One `> [!quote]` block per tweet **in thread order** (verbatim text). For a multi-tweet thread, label them `(1/N)`, `(2/N)`, … and embed each tweet's images right after its quote with `![[<file>]]`.
- For a single tweet, one quote block, then the images.
- `## My take` — why it matters, how Jalen would apply it, any disagreement.
- `## Distilled into` — links to the convention note(s) from step 4 (or "—" if none).
- `## Related` — at least `[[Home]]` plus any related notes (a note with no links is a bug).

## 4. Distill actionable best-practices into conventions
If the tweet teaches a concrete, reusable rule for part of Jalen's stack (craftcms, laravel, php, twig, vuejs, tailwindcss, git, general), draft a convention note at `~/brain/conventions/<topic>/<imperative-kebab-title>.md` using the convention contract (`status: draft`, `author: claude`, `source: <tweet url>`). Put the **real transcribed code** in `## Example`. Link it back to the reference note under `## Related`, and link the reference's `## Distilled into` to it. Skip this step for tweets that are just interesting, not actionable.

## 5. Report
Tell Jalen: how many tweets + images were captured, the reference note path, any convention notes drafted, and the forward-reply caveat if relevant. Remind him they're `status: draft` in `~/brain/Review.md` — promote (flip `status`) or delete on review. Don't commit or push.

## Notes
- Prefer editing/linking an existing note over creating a near-duplicate — grep `~/brain` first.
- The script caps thread-walk at 50 tweets and only follows the same author (stops at a reply to someone else).
- Images already live in the vault after step 1; you only reference them by filename in `![[...]]`.

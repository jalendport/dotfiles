# Capture a tweet

The tweet branch of [`capture-to-brain`](SKILL.md): capture a tweet (or self-thread) into the user's vault. Read `~/brain/AGENTS.md` first and follow it in full — the note contracts, draft-only authorship, and git rules all live there; this file adds only the tweet-specific procedure.

## 1. Fetch the tweet, thread, and images
Run the helper (it uses `api.fxtwitter.com` — no auth; the plain fixupx/fxtwitter URLs 302 to x.com and fail, so always let the script hit the `api.` subdomain):

```bash
python3 ~/.claude/skills/capture-to-brain/fetch_thread.py "<TWEET_URL>"
```

It downloads all media into `~/brain/reference/twitter/attachments/` and prints JSON:
- `tweets[]` — the self-thread in chronological order; each has `text`, `date`, `handle`, `author_name`, `url`, `is_note_tweet`, and `images[]` (each with a saved `file` name).
- `forward_replies_possible` / `newest_reply_count` — if true, the newest captured tweet has replies the API **cannot** fetch forward.

If the JSON has an `error` key, report it and stop. If `forward_replies_possible` is true, tell the user at the end: "to capture a full thread, paste the **last** tweet's URL — this API only walks backward."

## 2. Read any code / text screenshots (don't paraphrase)
For each downloaded image that is a code or text screenshot, **Read it** (vision) from `~/brain/reference/twitter/attachments/<file>` and transcribe the code exactly. If part of a screenshot is cut off, transcribe what's visible and mark the rest `/* …cut off in source screenshot */` — never invent the missing part. Photos that are just pictures don't need transcription.

## 3. Write the reference note
Create the note in `~/brain/reference/twitter/` per AGENTS.md's reference contract (`source: twitter`), with the tweet-branch specifics:
- Frontmatter: `status: draft` (the draft-authorship rule wins over the reference enum); `url` = the first tweet's URL; `published` = the first tweet's date; `captured` = today — run `date +%F`.
- Body: `# <one-line gist>`, then one `> [!quote]` block per tweet **in thread order** (verbatim text). For a multi-tweet thread, label them `(1/N)`, `(2/N)`, … and embed each tweet's images right after its quote with `![[<file>]]`; for a single tweet, one quote block, then the images.
- After `## My take`, add `## Distilled into` — links to the convention note(s) from step 4, or "—" if none — then `## Related` with at least `[[Home]]`.

## 4. Distill actionable best-practices into conventions
If the tweet teaches a concrete, reusable rule for part of the user's stack (the convention topics in AGENTS.md), draft a convention note per the convention contract (`status: draft`, `source: <tweet url>`). Put the **real transcribed code** in `## Example`. Link it back to the reference note under `## Related`, and link the reference's `## Distilled into` to it. Skip this step for tweets that are just interesting, not actionable.

## 5. Report
Tell the user: how many tweets + images were captured, the reference note path, any convention notes drafted, and the forward-reply caveat if relevant. Remind them they're `status: draft` in `~/brain/Review.md` — promote (flip `status`) or delete on review.

## Notes
- The script caps thread-walk at 50 tweets and only follows the same author (stops at a reply to someone else).
- Images already live in the vault after step 1; you only reference them by filename in `![[...]]`.

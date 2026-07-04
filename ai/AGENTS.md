# Commit messages

Write a single-line git commit message following these conventions:

- Start the description with an imperative verb (Add, Fix, Update, Remove, Tweak, Improve, Prevent, Make, Handle, Switch, Rename, Migrate, Patch, Clean up, Overhaul, Rebuild, Standardize, Retain, Hide, Re-enable, etc.).
- Use sentence case — capitalize the first word only, plus proper nouns.
- Do not end with a period.
- Keep it concise: aim for 4–10 words. Favor specificity over verbosity.
- Focus on what changed; include a brief "why" only when it adds clarity the diff doesn't reveal.
- For two closely related changes in one commit, join with a semicolon: "Fix credit card form; add validation improvements".

## Co-authorship trailer

When you (an AI agent) make the commit on my behalf, end the message with a blank line followed by a single `Co-Authored-By:` trailer identifying yourself. The trailer is a footer — it never counts against the single-line subject above. Add only the trailer for the agent actually doing the committing:

- Claude → `Co-Authored-By: Claude <noreply@anthropic.com>` (append the model name when you know it, e.g. `Claude Opus 4.8 <noreply@anthropic.com>`)
- Codex → `Co-Authored-By: Codex <noreply@openai.com>`
- Gemini / Antigravity (agy) → `Co-Authored-By: Gemini <noreply@google.com>`

If I'm committing by hand with no agent involved, omit the trailer entirely.

# Second brain vault (`~/brain`)

I keep a git-synced Obsidian knowledge base at `/Users/jalendport/brain`. It's the *cold store* of my decisions, coding conventions, and curated best-practice notes (my Claude memory system is the always-loaded *hot cache* that links into it).

- **When a coding task touches my preferences, a past decision, or a language/framework I keep conventions for, read the vault first**: start with `~/brain/Home.md` (the index), then the relevant `~/brain/conventions/<topic>/` and `~/brain/decisions/` notes. Use grep/glob over `~/brain`.
- **Honor the tag contract** defined in `~/brain/AGENTS.md`: `status: best-practice` = prefer over your defaults; `status: adopted` conventions = how I want code written; `source: twitter` without `best-practice` = unverified lead; `status: draft`/`experimental`/`deprecated` = don't apply silently.
- **Writing to the vault**: you may draft notes (set `author: claude`, `status: draft`, use `~/brain/templates/`). `~/brain` auto-syncs (obsidian-git commits + pushes every ~10 min), so you don't manage git at all — just write the file. The approval gate is the **`status` field, not git**: everything you write stays `status: draft` and unreviewed until I promote it (I work a `~/brain/Review.md` queue). **Never promote your own notes** to `accepted`/`adopted`/`best-practice` — that's my call. Grep before creating to avoid duplicates; every note needs at least one `[[wikilink]]`.
- Full operating rules live in `~/brain/AGENTS.md` — read it if you're doing substantial vault work.

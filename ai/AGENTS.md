# Working rules

- Match existing patterns before inventing new ones — the naming, file structure, styling utilities, and idioms already in the codebase win by default.
- Verify a change actually works before calling it done. Exercise the affected flow; don't declare success from the diff alone.
- Build exactly what was asked. Anything beyond the literal ask — an extra flag, a nice-to-have, a drive-by refactor, any size — gets raised as a question first, never silently shipped. For big features or destructive/irreversible changes, propose the approach and wait for approval before building.
- Never commit unless asked. When asked, follow the commit conventions below.
- My conventions live in my knowledge vault at `~/brain` — check it before writing code or prose. See "Second brain vault" below.

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

I keep a git-synced Obsidian knowledge base at `/Users/jalendport/brain`. It's the *single store* of my decisions, coding conventions, and curated best-practice notes — Claude's auto-memory is disabled, so anything durable lives here or nowhere.

- **When a task touches my preferences, a past decision, or a language/framework I keep conventions for — code or docs/prose (e.g. markdown, READMEs) — read the vault first**: start with `~/brain/Home.md` (the index), grep/glob from there, and pass relevant conventions along when delegating to subagents.
- **The operating contract lives in `~/brain/AGENTS.md`** — the status/tag weighting, the rules for writing notes back (draft-only; the `status` field is the approval gate, not git), and the don'ts. Read it before applying or authoring any note.

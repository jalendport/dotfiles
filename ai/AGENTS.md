# Working rules

- Match existing patterns before inventing new ones — the naming, file structure, styling utilities, and idioms already in the codebase win by default.
- Verify a change actually works before calling it done. Exercise the affected flow; don't declare success from the diff alone.
- For big features or destructive/irreversible changes, propose the approach and wait for approval before building. Small, reversible changes: just do them.
- Never commit unless asked. When asked, follow the commit conventions below.
- My conventions live in my knowledge vault at `~/brain` (read its `AGENTS.md` for how to use it) — they cover **both code and docs/prose**. Before writing code, check `~/brain/conventions/<topic>/` for the stack in play; before writing markdown, READMEs, or any documentation, check `~/brain/conventions/general/` (e.g. never hard-wrap markdown prose). Pass the relevant conventions along when delegating writing to subagents.

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

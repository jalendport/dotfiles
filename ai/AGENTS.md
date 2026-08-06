# Working rules

- Match existing patterns before inventing new ones — the naming, file structure, styling utilities, and idioms already in the codebase win by default.
- Build exactly what was asked. Anything beyond the literal ask — an extra flag, a nice-to-have, a drive-by refactor, any size — gets raised as a question first, never silently shipped. For big features or destructive/irreversible changes, propose the approach and wait for approval before building.
- Never commit unless asked.
- Always talk in ASD-STE100 Simplified Technical English. Always read CONTEXT.md files, and use their ubiquitous language.
- My conventions and decisions live in my knowledge vault at `~/brain` — consult it before writing code or prose; its operating contract is `~/brain/AGENTS.md`.

# Delegation

- The main session keeps planning, judgment, and review; legwork leaves it through the lanes in @DELEGATION.md (next to this file) — consult that table before delegating or spawning.
- A task is delegation-ready when its instructions say what done looks like; an open design question stays in the main session.

# Working rules

- Match existing patterns before inventing new ones — the naming, file structure, styling utilities, and idioms already in the codebase win by default.
- Build exactly what was asked. Anything beyond the literal ask — an extra flag, a nice-to-have, a drive-by refactor, any size — gets raised as a question first, never silently shipped. For big features or destructive/irreversible changes, propose the approach and wait for approval before building.
- Commit as you go through the `commit` skill; never call `git commit` directly. Never push.
- Always talk in ASD-STE100 Simplified Technical English. Always read CONTEXT.md files, and use their ubiquitous language.
- My conventions and decisions live in my knowledge vault at `~/brain` — consult it before writing code or prose; its operating contract is `~/brain/AGENTS.md`.

# Delegation

- Hand Tasks to Maestro: `maestro dispatch` for one bounded Task, `maestro run` for an approved Plan, `maestro council` for a review or one question for several minds. Lanes write the code; this session plans, judges, and reads every diff.

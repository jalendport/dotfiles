# Working rules

- Match existing patterns before inventing new ones — the naming, file structure, styling utilities, and idioms already in the codebase win by default.
- Build exactly what was asked. Anything beyond the literal ask — an extra flag, a nice-to-have, a drive-by refactor, any size — gets raised as a question first, never silently shipped. For big features or destructive/irreversible changes, propose the approach and wait for approval before building.
- Commit through the `commit` skill; never call `git commit` directly. Never push. Cadence follows the vault note `conventions/git/commit-once-per-finished-feature.md`: with Maestro, one commit per verified Task; without Maestro, leave the changes uncommitted until I confirm the feature is done — ask "Are we done with X? I want to commit it."
- Always talk in ASD-STE100 Simplified Technical English. Always read CONTEXT.md files, and use their ubiquitous language.
- My conventions and decisions live in my knowledge vault at `~/brain` — consult it before writing code or prose; its operating contract is `~/brain/AGENTS.md`.

# Delegation

- Hand Tasks to Maestro: `maestro dispatch` for one bounded Task, `maestro run` for an approved Plan, `maestro council` for a review or one question for several minds. Lanes write the code; this session plans, judges, and reads every diff.
- A Maestro Task title becomes the commit subject, so write every Plan and Brief title as a commit subject per the vault's git convention: imperative verb, sentence case, 4–10 words, no period. This is my layer on top of Maestro; never bake it into Maestro itself.

---
name: consult-brain
description: Consult Jalen's ~/brain vault — his conventions, decisions, and captured knowledge. Use before writing nontrivial code or prose in his stacks (Craft CMS, Laravel, PHP, Twig, Vue, Tailwind, git), when asked "how do I usually do X" or "what did I decide about X", or when the user mentions the brain/vault.
---

# Consult brain

`~/brain` is Jalen's git-synced knowledge base — `conventions/`, `decisions/`, `reference/`, `knowledge/`. The operating contract (status weighting, write rules, frontmatter, don'ts) lives in `~/brain/AGENTS.md`; this skill is the retrieval procedure only.

1. Read `~/brain/AGENTS.md` (the contract) and `~/brain/Home.md` (the map).
2. Grep/glob the topic in play — e.g. `Grep(pattern: "twig", path: "~/brain/conventions", -il)`; check `decisions/` too when the question is "why is it this way".
3. Read every note the search surfaces and apply it per the contract's status weighting, citing each applied note by filename and status (e.g. "applying `conventions/craftcms/keep-module-classes-lean` (adopted)") — a citation replaces pasting the note's text into the conversation. A `draft` note gets flagged as unconfirmed when relied on.
4. Nothing found → say so and proceed on general judgment. Absence of a note is a data point, not an error.

Writing something new *to* the vault is the capture-to-brain skill's job.

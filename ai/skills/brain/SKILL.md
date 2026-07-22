---
name: brain
description: Retrieve Jalen's established conventions, decisions, and captured knowledge from his ~/brain vault, weighted by approval status. Use before writing nontrivial code in any stack (Craft CMS, Laravel, PHP, Twig, Vue, Tailwind, git), when asked "how do I usually do X" or "what did I decide about X", or when the user mentions the brain/vault. Also governs writing new notes back to the vault.
---

# Brain — vault retrieval

`~/brain` is Jalen's git-synced knowledge base. Canonical rules live in `~/brain/AGENTS.md` — this skill is the condensed field guide; if anything here seems stale, that file wins.

## Retrieve

1. Read `~/brain/Home.md` for the map (folders: `decisions/`, `conventions/<topic>/`, `reference/`, `knowledge/`).
2. Grep/Glob for the topic in play — e.g. `Grep(pattern: "twig", path: "~/brain/conventions", -il)` or glob `~/brain/conventions/craftcms/*.md`. Check `decisions/` too when the question is "why is it this way."
3. Read matching notes and **weight by `status` frontmatter before applying**:

| `status` | Meaning | How to treat |
|---|---|---|
| `best-practice` | Endorsed guidance | Prefer over your training when they conflict |
| `adopted` / `accepted` | How Jalen wants it done | Follow it |
| `draft` | Unreviewed (often Claude-authored) | A lead, not gospel — flag as unconfirmed if you rely on it |
| `experimental` / `deprecated` | Not settled / retired | Never apply silently; mention status |

4. **Say which note you're applying** (e.g. "applying `conventions/craftcms/keep-module-classes-lean…` (adopted)"). If a relevant note is `draft`, say so.
5. Nothing found → say so and proceed on general judgment. Absence of a note is a data point, not an error.

## Write back (only when something durable was learned or decided)

- Author with the matching template from `~/brain/templates/`, in the right type folder, with `author: claude` and `status: draft` — **never** promote your own note; Jalen approves via his Review queue.
- Grep first; extend or link an existing note over creating a near-duplicate.
- Include at least one `[[wikilink]]` to a related note.
- Don't touch git — obsidian-git auto-commits and pushes.

## Don't

- Don't dump whole notes into the conversation — apply them and cite the filename.
- Don't store one-line durable preferences here; those belong in the hot store (`~/.claude` memory), which links *into* the vault.

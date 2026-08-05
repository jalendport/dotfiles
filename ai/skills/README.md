# Shared agent skills

Canonical home for [Agent Skills](https://docs.claude.com/en/docs/claude-code/skills) shared across **Claude Code**, **Codex**, and **agy** (Antigravity CLI). All three read the same `SKILL.md` format, so each skill gets authored once here and symlinked into every tool by `dotbot` (see `../../install.conf.yaml`).

## Layout

Skills are grouped one level deep by category:

```
ai/skills/
└── <category>/           # brain | writing | workflow | dev
    └── <skill-name>/
        ├── SKILL.md      # required: YAML frontmatter (name, description) + body
        ├── agents/
        │   └── openai.yaml   # required: Codex UI metadata (see Authoring rules)
        ├── references/   # optional: docs the agent reads on demand
        └── resources/    # optional: scripts, templates, assets
```

- **brain** - the `~/brain` vault (retrieval, capture)
- **writing** - prose in my voice
- **workflow** - process skills (planning, releases, reviews)
- **dev** - development tooling (Craft CMS, PHP, and friends)

## How linking works

Running `./install` from the repo root symlinks every directory containing a `SKILL.md` into `~/.claude/skills/<name>`, `~/.codex/skills/<name>`, and `~/.gemini/antigravity-cli/skills/<name>`, leaving each tool's managed built-ins (e.g. Codex's `.system/`) untouched. The tools only discover skills at the top level of their skills dir, so the mirrors stay flat while this repo stays categorized. Dangling symlinks (from a skill deleted here) get pruned on each run.

## Authoring rules

Every skill in this repo - new, overhauled, or stolen from someone else's repo - follows these rules:

1. **Name it with an imperative command verb**, kebab-case: `write-for-agents`, not `writing-for-agents`. The folder name and the `name:` frontmatter always match.
2. **Put it under a category folder** (see Layout above), and keep the name unique across all categories - every tool sees one flat list, so the category is purely organizational.
3. **Ship an `agents/openai.yaml`** with `interface.display_name` (title-case, e.g. "Write for Agents") and `interface.short_description` (25–64 chars, e.g. "Write documents agents consume"). Codex shows these in its `$` skill picker; Claude and agy ignore the file, so it costs nothing there.
4. **Write the `description:` frontmatter as the trigger, not a summary** - state what the skill is, then the "Use when …" branches that should invoke it.
5. **Read the `write-for-agents` skill before writing or editing any SKILL.md body** - it's the house reference for how documents agents consume should be built.
6. **Rename imported skills to comply** - folder, frontmatter `name:`, `display_name`, and any internal cross-references.

## Adding a skill

1. Create `ai/skills/<category>/<skill-name>/SKILL.md` (plus its `agents/openai.yaml`) following the rules above.
2. Run `./install` (or just `git pull` - the repo git hook re-runs dotbot).
3. Confirm the link landed: `ls ~/.claude/skills/<skill-name>` should resolve in all three tools' skills dirs.

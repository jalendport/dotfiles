# Shared agent skills

Canonical home for [Agent Skills](https://docs.claude.com/en/docs/claude-code/skills) shared across **Claude Code**, **Codex**, **agy** (Antigravity CLI), and **Grok**. All four read the same `SKILL.md` format, so each skill gets authored once here and symlinked by `dotbot` into three mirrors: `~/.claude/skills`, `~/.gemini/antigravity-cli/skills`, and `~/.agents/skills` (see `../../install.conf.yaml`). Codex and Grok read `~/.agents/skills`.

## Layout

Skills are grouped one level deep by category:

```
ai/skills/
└── <category>/           # brain | writing | workflow | dev
    └── <skill-name>/
        ├── SKILL.md      # required: YAML frontmatter (name, description) + body
        ├── references/   # optional: docs the agent reads on demand
        └── resources/    # optional: scripts, templates, assets
```

- **brain** - the `~/brain` vault (retrieval, capture)
- **writing** - prose in my voice
- **workflow** - process skills (planning, releases, reviews)
- **dev** - development skills and tooling (code-shaped work: TDD, review, debugging, design)

## How linking works

Running `./install` from the repo root symlinks every directory containing a `SKILL.md` into three mirrors: `~/.claude/skills/<name>`, `~/.gemini/antigravity-cli/skills/<name>`, and `~/.agents/skills/<name>` (Codex and Grok read `~/.agents/skills`), leaving each tool's managed built-ins (e.g. Codex's `.system/`) untouched. The tools only discover skills at the top level of their skills dir, so the mirrors stay flat while this repo stays categorized. Dangling symlinks (from a skill deleted here) get pruned on each run.

## Authoring rules

Every skill in this repo - new, overhauled, or stolen from someone else's repo - follows these rules:

1. **Name it with an imperative command verb**, kebab-case: `write-for-agents`, not `writing-for-agents`. The folder name and the `name:` frontmatter always match.
2. **Put it under a category folder** (see Layout above), and keep the name unique across all categories - every tool sees one flat list, so the category is purely organizational.
3. **Write the `description:` frontmatter as the trigger, not a summary** - state what the skill is, then the "Use when …" branches that should invoke it.
4. **Read the `write-for-agents` skill before writing or editing any SKILL.md body** - it's the house reference for how documents agents consume should be built.
5. **Rename imported skills to comply** - folder, frontmatter `name:`, and any internal cross-references.

## Adding a skill

1. Create `ai/skills/<category>/<skill-name>/SKILL.md` following the rules above.
2. Run `./install` (or just `git pull` - the repo git hook re-runs dotbot).
3. Confirm the link in all three mirrors: `~/.claude/skills/<skill-name>`, `~/.gemini/antigravity-cli/skills/<skill-name>`, and `~/.agents/skills/<skill-name>`. Codex and Grok read `~/.agents/skills`.

# Shared agent skills

Canonical home for [Agent Skills](https://docs.claude.com/en/docs/claude-code/skills)
shared across **Claude Code**, **Codex**, and **agy** (Antigravity CLI). All three
read the same `SKILL.md` format, so each skill is authored once here and symlinked
into every tool by `dotbot` (see `../../install.conf.yaml`).

## Layout

```
ai/skills/
└── <skill-name>/
    ├── SKILL.md          # required: YAML frontmatter (name, description) + body
    ├── references/       # optional: docs the agent reads on demand
    └── resources/        # optional: scripts, templates, assets
```

## How linking works

Running `./install` from the repo root:

- **Claude** — `~/.claude/skills` is a symlink to this whole directory, so every
  skill here appears automatically.
- **Codex** — each skill is individually symlinked into `~/.codex/skills/<name>`,
  leaving Codex's managed `.system/` built-ins untouched.
- **agy** — each skill is individually symlinked into
  `~/.gemini/antigravity-cli/skills/<name>` for auto-discovery.

Dangling skill symlinks (from a skill you deleted here) are pruned on each run.

## Adding a skill

1. Create `ai/skills/<skill-name>/SKILL.md`.
2. Run `./install` (or just `git pull` — the repo git hook re-runs dotbot).

The folder name should be kebab-case and match the `name:` in the frontmatter.

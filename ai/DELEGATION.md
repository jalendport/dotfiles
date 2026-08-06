# Delegation lanes

The routing table for delegated work. The orchestrating session reads this before handing work to another agent or lane. `AGENTS.md` carries the principles; this file carries the lanes and their mechanics.

## Lanes

| Lane | Takes | Why this lane |
|---|---|---|
| main session | planning, design judgment, review, synthesis | context and judgment are the scarce resources — keep them on the frontier model at high effort |
| scout | read-only sweeps, file/symbol hunts, docs reading, fact-finding | volume-heavy reading where conclusions matter and prose quality doesn't — cheapest tier |
| grunt | clearly defined implementation: mechanical edits, applying a written plan, boilerplate, bulk renames, test fixups | the spec says what done looks like, so mid-tier quality suffices; ambiguity bounces back to the orchestrator |
| Solo lane | bigger autonomous chunks with a tracker deliverable | outlives the session; runtime picked per work (below) |

## Scout and grunt per harness

| Lane | Claude Code | Codex |
|---|---|---|
| scout | `scout` agent — Haiku, medium effort (`ai/claude/agents/scout.md`) | `codex exec -p scout` — config-default model, low reasoning (`ai/codex/scout.config.toml`) |
| grunt | `grunt` agent — Sonnet, medium effort (`ai/claude/agents/grunt.md`) | `codex exec -p grunt` — config-default model, medium reasoning (`ai/codex/grunt.config.toml`) |

Gemini has no configured lanes yet; give it one here when it earns a niche.

## Solo implementation lanes

- Codex lane for well-specified, self-contained implementation: `codex exec -s workspace-write "<prompt>"` — full strength; model and reasoning effort come from `~/.codex/config.toml`, the single source of truth.
- Claude lane where repo conventions or multi-file architecture need judgment: spawn with `--model opus --effort high`. An unmodified Claude spawn runs the main-session model, so always pass model and effort.

## Enforcement and truth

Claude Code hooks (`ai/claude/hooks/`) deny scout/grunt/Explore spawns on expensive models and Claude Solo spawns without a model. This table is the map; the agent frontmatter, profile tomls, and hooks are the territory — fix drift there, then here.

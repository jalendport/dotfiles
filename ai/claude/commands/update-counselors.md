---
name: update-counselors
description: Refresh the counselors config (~/.config/counselors/config.json) so tool entries point at the latest available models for each installed CLI. Use when the user wants to "update counselors", "check for new models in counselors", or after they install/upgrade an AI CLI.
---

# Update Counselors Config

Goal: bring `~/.config/counselors/config.json` up to date with the latest models exposed by each installed AI CLI (Claude, Codex, Gemini CLI, Antigravity, Amp, etc.), without breaking the user's existing group structure.

**This is a high-touch, decision-heavy task.** Model choices and group lineups depend on the user's preferences. Use `AskUserQuestion` at each fork rather than guessing. Show them the options with preview where helpful.

---

## Phase 1: Snapshot current state

Read the current config and what counselors thinks is installed:

```bash
counselors ls -v
counselors groups ls
counselors config        # prints config file path + JSON
```

Read the config file (`~/.config/counselors/config.json`) directly so you have the structure in context — you'll edit this file at the end. Note which tools have `adapter: "custom"`; those are wrappers (like `agy`) that you can't manage via `counselors tools add`.

---

## Phase 2: Back up the config

**Always.** Before any edits:

```bash
cp ~/.config/counselors/config.json ~/.config/counselors/config.json.bak-$(date +%Y%m%d-%H%M%S)
```

Tell the user the backup path so they can revert.

---

## Phase 3: Discover available models per CLI

For each binary referenced in the config, find what models are *actually available right now*. Don't trust counselors' built-in adapter defaults — they go stale fast.

### Claude (`claude` binary)

- Aliases `opus`, `sonnet`, `haiku` auto-resolve to the latest in each tier. If the existing entries use aliases, they self-update — no model string change needed.
- Check `claude --help` for new flags. Notably `--effort {low,medium,high,xhigh,max}` was added — you can add a max-effort variant (e.g. `claude-opus-max`) without bumping the model.
- For concrete model IDs, ask the user (or read the Claude Code system prompt context in the current session — it lists exact IDs like `claude-opus-4-7`).

### Codex (`codex` binary)

The Codex CLI maintains a **live model cache** at `~/.codex/models_cache.json`. Parse it:

```bash
python3 -c "import json; data=json.load(open('/Users/'+__import__('os').environ['USER']+'/.codex/models_cache.json')); [print(m['slug'], '|', m.get('visibility',''), '|', [e['effort'] for e in m.get('supported_reasoning_levels',[])]) for m in data['models']]"
```

Also check `~/.codex/config.toml` for `[notice.model_migrations]` — Codex publishes deprecation mappings there (e.g. `"gpt-5.3-codex" = "gpt-5.4"` meant 5.3 was deprecated). If the user has entries pinned to a deprecated slug, surface that prominently.

The Codex adapter passes models via `-m <slug>` and effort via `-c model_reasoning_effort=<level>`.

### Gemini CLI (`gemini` binary, if installed)

**Check whether it's still installed first** — users replace it with Antigravity. Run `which gemini`.

If present, model constants live in:
`<gemini-install>/node_modules/@google/gemini-cli-core/dist/src/config/models.js`

```bash
GEMINI_CORE=$(find /opt/homebrew/Cellar/gemini-cli -name "models.js" -path "*core*config*" 2>/dev/null | head -1)
[ -n "$GEMINI_CORE" ] && grep -E "^export const (PREVIEW|DEFAULT)_GEMINI[A-Z_]*MODEL" "$GEMINI_CORE"
```

Look for both `PREVIEW_GEMINI_*` (newer, preview tier) and `DEFAULT_GEMINI_*` (GA tier). Preview-tier models often have tighter quotas — flag this risk.

### Antigravity (`agy` binary, if installed)

**Important caveats (as of agy 1.0.1):**
- No `-m`/`--model` CLI flag. `agy -m foo` errors with `flags provided but not defined: -m`.
- No env var for model selection (no `AGY_MODEL`, `ANTIGRAVITY_MODEL`, `GEMINI_MODEL`).
- Model is set **globally** via `~/.gemini/antigravity-cli/settings.json` (the `"model"` key, with a display-name value like `"Gemini 3 Pro"` or `"Gemini 3.5 Flash"`).
- `agy` must use `adapter: "custom"` in counselors — the built-in `gemini` adapter sends `-m`, `--extensions`, `--allowed-tools`, `--output-format` which agy rejects.

**Consequence: only one `agy` entry per counselors config.** Don't try to create `agy-pro`/`agy-flash` variants unless the user explicitly opts into wrapper scripts (which race on the shared settings.json or require per-profile HOME dirs with symlinked auth — fragile).

To check what model agy is currently using:

```bash
cat ~/.gemini/antigravity-cli/settings.json | python3 -c "import json,sys; print(json.load(sys.stdin).get('model','(unset)'))"
```

Recheck this in future updates — if agy adds `-m` support, the constraint drops and per-model variants become possible.

### Amp / other CLIs

Run `<cli> --help` and look for `--model` or `-m`. Check the install dir for a models config (e.g. `~/.amp/`, JSON or TOML).

### Sanity-check binary paths

If a config entry's `binary` no longer exists (e.g. the user uninstalled gemini-cli), the entry is dead — `counselors doctor` will flag it but won't auto-remove. Plan to drop or replace it.

```bash
for path in $(python3 -c "import json; [print(t['binary']) for t in json.load(open('$HOME/.config/counselors/config.json'))['tools'].values()]"); do
  [ -x "$path" ] || echo "MISSING: $path"
done
```

---

## Phase 4: Propose changes and confirm

Lay out what you found:

1. **Deprecated/dead entries** — model strings flagged by the CLI as deprecated, or binaries that no longer exist.
2. **Available upgrades** — newer model slugs per CLI.
3. **New capabilities** — new CLI flags worth wiring up (e.g. `--effort max`).

Then use `AskUserQuestion` (one question per decision area, parallel where independent):

- **Migration choices** per CLI (e.g. "migrate codex entries to gpt-5.5, also add gpt-5.4-mini, or full ladder?").
- **New tool variants** (e.g. "add `claude-opus-max` with `--effort max`?").
- **Group restructure** if tool IDs change. Existing groups in this user's setup are typically `quick` / `default` / `deep`, ordered by reasoning depth. Use `preview` in the question to show ASCII lineups side-by-side.

**Don't move on until the user has confirmed.** If a group references a tool ID that's about to change, the group must be updated in the same write — never leave dangling references.

---

## Phase 5: Edit `config.json` directly

For non-trivial changes, **edit `~/.config/counselors/config.json` with the Edit/Write tool — not via `counselors tools add`** (which is interactive and forces you through prompts one tool at a time, with no way to set exact flags).

Each tool entry has the shape:

```json
"<tool-id>": {
  "binary": "/abs/path/to/cli",
  "adapter": "claude" | "codex" | "gemini" | "amp" | "custom",
  "readOnly": { "level": "enforced" | "bestEffort" },
  "extraFlags": ["...", "..."],
  "timeout": 900
}
```

Notes:
- `adapter` selects which built-in invocation shape counselors uses. Built-ins know their CLI's quirks (e.g. the `gemini` adapter adds `--extensions`, `--allowed-tools`). Use `"custom"` for unknown CLIs — counselors then just appends `extraFlags` and trails a `Read the file at <path>...` instruction.
- `extraFlags` is what model/effort flags go in (e.g. `["-m", "gpt-5.5", "-c", "model_reasoning_effort=high"]`).
- `timeout` (seconds) overrides the global `defaults.timeout`. Long-reasoning models (xhigh, max effort) often need 900+.
- `readOnly.level`: `"enforced"` for adapters that have a built-in read-only mode; `"bestEffort"` for custom adapters where you can't guarantee read-only via CLI flags.

Groups are just arrays of tool IDs:

```json
"groups": {
  "quick": ["claude-haiku", "codex-5.4-mini", "agy"],
  "default": ["claude-sonnet", "codex-5.5-high", "agy"],
  "deep":  ["claude-opus-max", "codex-5.5-xhigh", "agy"]
}
```

Each tier should mix providers (Claude + Codex + Gemini/agy) so the user gets diverse perspectives at every depth level.

---

## Phase 6: Verify

After writing the new config, run **both** of these — `doctor` alone isn't enough:

```bash
counselors ls
counselors groups ls
counselors doctor              # checks binary + version + readOnly mode + group membership
counselors tools test <ids>    # actually invokes each tool with "Reply OK" prompt
```

**Critical:** `counselors doctor` does NOT validate that the model slug is accepted by the CLI — it only checks the binary exists and runs `--version`. A typo in a model slug (e.g. `gpt-5.5-foo` instead of `gpt-5.5`) will pass doctor and fail at runtime.

`counselors tools test` uses a hardcoded 30s timeout. If a model legitimately takes longer than that on first response (e.g. a preview Gemini tier), the test will report failure even when the config is correct. When you see a timeout-only failure on one tool, run the underlying command directly with a longer timeout to confirm.

### Reading test failures

- **`Error: Timed out after 30s`** — likely cold start. Re-run direct.
- **`You have exhausted your capacity on this model`** (Gemini 429) — quota/rate-limit, NOT a config bug. Config is correct; the user's account is throttled. Note it and continue.
- **`flags provided but not defined: -X`** — the CLI doesn't accept that flag. Wrong adapter or wrong extraFlag.
- **`gpt-X.Y not found`** or model-id errors — bad slug. Cross-check against `~/.codex/models_cache.json` or the CLI's model constants.

---

## Phase 7: Summarize and update related state

Tell the user:

1. The final tool list and group structure.
2. Where the backup is (`~/.config/counselors/config.json.bak-YYYYMMDD-HHMMSS`).
3. Any tools that test-failed and *why* (so they know what's actually broken vs. account-side).
4. For any non-trivial behavior — e.g. "agy uses settings.json model globally, not per-call" — surface that one more time in the summary so the user remembers when running counselors later.

If something changed that affects the existing `counselors` slash-command (e.g. group names renamed), check whether `~/.claude/commands/counselors.md` references the old names and update it.

---

## Reference: lessons learned in this user's setup

These are sticky details that have come up before — don't re-derive every time:

- **Claude CLI** — aliases (`opus`/`sonnet`/`haiku`) auto-track the latest models, so those entries usually don't need touching.
- **Codex CLI** — `~/.codex/models_cache.json` is the source of truth for available models; `~/.codex/config.toml` publishes deprecations under `[notice.model_migrations]`.
- **Gemini CLI** — if uninstalled, the `gemini-*` entries are dead binaries. Users sometimes replace it with Antigravity (`agy`).
- **Antigravity (agy)** — no per-call model flag in 1.0.1. One entry per config. Recheck on future versions: `agy --help | grep -i model`.
- **Preview-tier models** often have tighter Google quotas. A 429 right after switching to a preview model is expected, not a config bug.
- **`counselors tools test`** has a hardcoded 30s timeout that doesn't honor per-tool `timeout` overrides.

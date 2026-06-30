---
name: update-counselors
description: Refresh the counselors config (~/.config/counselors/config.json) so tool entries point at the latest available models for each installed CLI. Use when the user wants to "update counselors", "check for new models in counselors", or after they install/upgrade an AI CLI.
---

# Update Counselors Config

Goal: bring the counselors config up to date with the latest models exposed by each installed AI CLI (Claude, Codex, Antigravity/`agy`, Gemini CLI, Amp, etc.), without breaking the user's group structure.

**This is a high-touch, decision-heavy task.** Model choices and group lineups depend on the user's preferences. Use `AskUserQuestion` at each fork rather than guessing. Show options with `preview` (ASCII lineups) where helpful.

## Two principles this user has settled on

1. **All available tools live in the config.** Every user-visible model × every supported effort gets a tool entry — even ones not in any group. Config entries are inert until referenced, so the only cost is list clutter, and this user always runs via groups anyway. So default to *full ladders* per CLI; don't trim unless they ask.
2. **Groups are the curated interface.** The user picks work via `--group <name>`, almost never ad-hoc single tools. So the real design work is the group lineups (see Phase 4). Tools outside groups are just shelf stock, ready for ad-hoc use.

---

## Phase 1: Snapshot current state

```bash
counselors ls -v
counselors groups ls
counselors config        # prints config file path + JSON
```

Read the config file directly so you have the structure in context.

**Always resolve the real config path before editing — it's often a symlink.** `~/.config/counselors/config.json` is the canonical location, but many users (this one included) symlink it into a dotfiles repo, and the Edit/Write tools **refuse to write through symlinks**. Resolve it once and use that path for every read/edit/backup below:

```bash
CFG=$(readlink -f ~/.config/counselors/config.json)   # -> real target (dotfiles path, or the plain file if not a symlink)
echo "$CFG"
```

If `readlink -f` returns a path under a dotfiles/git repo, edits land there uncommitted (offer to commit in Phase 7). If it returns `~/.config/counselors/config.json` unchanged, it's a plain file — edit it directly. Either way, **edit `$CFG`, never the symlink.**

Note which tools have `adapter: "custom"` (e.g. `agy`) — those are wrappers you can't manage via `counselors tools add`.

---

## Phase 2: Back up the config

**Always**, before any edits (this follows the symlink and makes a real copy — good):

```bash
cp ~/.config/counselors/config.json ~/.config/counselors/config.json.bak-$(date +%Y%m%d-%H%M%S)
```

Tell the user the backup path so they can revert.

---

## Phase 3: Discover available models per CLI

Find what models are *actually available right now*. Don't trust counselors' built-in adapter defaults — they go stale fast.

> **Discovery is authoritative; every model name in this doc is a dated snapshot.** `gpt-5.5`, `Gemini 3.1 Pro`, `claude-opus-4-8`, the ladders, the lineups — all of it *will* drift. Treat the literals here as illustrative examples, not the source of truth. Each run, re-derive the real list from the live sources (`models_cache.json`, `agy models`, `claude --help`, the session system prompt). If discovery surfaces a model this doc doesn't name (a `gpt-5.6`, a `Gemini 4`, a new effort level), that's **expected, not an error** — slot it in with the rules in Phase 4 ("When discovery shows a model this doc doesn't name").

### Claude (`claude` binary)

- Aliases `opus`, `sonnet`, `haiku` auto-resolve to the latest in each tier and **self-update** — no model-string maintenance needed. (Current: opus → `claude-opus-4-8`, sonnet → `claude-sonnet-4-6`, haiku → `claude-haiku-4-5`. The session system prompt lists exact IDs.)
- `--effort {low,medium,high,xhigh,max}` applies on top of any model. Confirm the accepted values: `claude --help | grep -iA3 -- --effort`.
- Adapter shape: `["--model", "sonnet"]`, plus `["--effort", "max"]` for boosted variants.
- A full Claude ladder is the 3 tiers × the effort variants you care about, e.g.: `claude-opus`, `claude-opus-high`, `claude-opus-xhigh`, `claude-opus-max`, `claude-sonnet`, `claude-sonnet-high`, `claude-sonnet-max`, `claude-haiku`, `claude-haiku-high`.

### Codex (`codex` binary)

Live model cache at `~/.codex/models_cache.json` — the source of truth. Parse it:

```bash
python3 -c "import json,os; d=json.load(open(os.path.expanduser('~/.codex/models_cache.json'))); [print(m['slug'],'|',m.get('visibility',''),'|',[e['effort'] for e in m.get('supported_reasoning_levels',[])]) for m in d['models']]"
```

- `visibility: "list"` = user-facing; `visibility: "hide"` = internal (e.g. `codex-auto-review`) → **exclude**.
- Current visible: `gpt-5.5`, `gpt-5.4`, `gpt-5.4-mini`, each with efforts `low/medium/high/xhigh`.
- Check `~/.codex/config.toml` `[notice.model_migrations]` for deprecations (e.g. `"gpt-5.3-codex" = "gpt-5.4"`). If an entry is pinned to a deprecated slug, surface it prominently.
- Adapter shape: model via `-m <slug>`, effort via `-c model_reasoning_effort=<level>`.
- Full ladder = 3 models × 4 efforts = 12 tools: `codex-5.5-{low,medium,high,xhigh}`, `codex-5.4-{low,medium,high,xhigh}`, `codex-5.4-mini-{low,medium,high,xhigh}`. Note `gpt-5.4` is largely superseded by `gpt-5.5` (same generation) — its main value is a *different-model* opinion in the top group; mention this if the user wants to trim.

### Antigravity (`agy` binary, if installed)

**As of agy 1.0.5, `agy` supports per-call model selection — the old "one entry only" constraint is GONE.** Update first if behind: `agy update` (self-updating Go binary; 1.0.5 added `--model` + the `models` subcommand).

- List models: `agy models` — prints **display names**, e.g. `Gemini 3.5 Flash (Low/Medium/High)`, `Gemini 3.1 Pro (Low/High)`, `Gemini 3 Flash`.
- `--model` takes the **display name verbatim** (with the effort in parens): `agy --model "Gemini 3.1 Pro (High)" -p "..."`. agy resolves it internally to a slug (e.g. `gemini-3.1-pro-preview`).
- **Still uses `adapter: "custom"`** — the built-in `gemini` adapter sends flags agy rejects. The model flag goes in `extraFlags`, *before* `-p`:
  ```json
  "extraFlags": ["--model", "Gemini 3.1 Pro (Low)", "--print-timeout", "10m", "-p"]
  ```
  (`readOnly.level: "bestEffort"`, `timeout: 900`. counselors appends the prompt after `-p`.)
- **Per-model variants are now the norm**, e.g.: `agy-flash-low/med/high` (Gemini 3.5 Flash), `agy-pro-low/high` (Gemini 3.1 Pro), `agy-3-flash` (Gemini 3 Flash).

**Two agy gotchas — both bit us:**
- **Silent fallback on a bad model name.** An unknown `--model` value does *not* error — agy quietly runs a default model and exits 0. So a typo passes `doctor` AND produces plausible output. Only `agy models` (verbatim strings) + `counselors tools test` + the log will catch it. Copy display names exactly.
- **Preview/Pro tiers can 404 on account access.** `Gemini 3.1 Pro (*)` maps to `gemini-3.1-pro-preview`; if the user's GCP/Vertex project lacks access, print mode returns **empty, exit 0** (~1.5s, no stderr). The reason is only in the log:
  ```bash
  grep -iE "NOT_FOUND|not have access|model_resolver|Resolving model" "$(readlink -f ~/.gemini/antigravity-cli/cli.log)" | tail
  ```
  A `NOT_FOUND (404): Publisher Model ... was not found or your project does not have access` means **account access, not a config bug**. Flag it; the user enables access on their side (they did, and Pro then worked).

### Gemini CLI (`gemini` binary, if installed)

**Check what's actually installed first — don't assume.** `which gemini` and `which agy`. Antigravity (`agy`) is the successor most setups are migrating to, so on many machines the standalone `gemini` CLI is on its way out or already gone — but verify rather than presume either way:
- `gemini` absent → any `gemini-*` config entries are dead binaries; plan to drop or replace them (with `agy` variants, if `agy` is present).
- `gemini` present → it's still a valid source. Constants live in `<install>/node_modules/@google/gemini-cli-core/dist/src/config/models.js` (`PREVIEW_GEMINI_*` = newer/tighter-quota, `DEFAULT_GEMINI_*` = GA).
- Both present → fine to keep both; they're different binaries with different adapters.

If you find a `gemini`→`agy` migration is warranted, treat it as a proposal to confirm with the user (Phase 4), not a foregone conclusion.

### Amp / other CLIs

`<cli> --help` → look for `--model`/`-m`. Check the install dir for a models config (`~/.amp/`, etc.).

### Sanity-check binary paths

```bash
for p in $(python3 -c "import json,os; [print(t['binary']) for t in json.load(open(os.path.expanduser('~/.config/counselors/config.json')))['tools'].values()]"); do
  command -v "$p" >/dev/null 2>&1 || [ -x "$p" ] || echo "MISSING: $p"; done
```

---

## Phase 4: Propose changes and confirm

Lay out what you found: deprecated/dead entries, available upgrades (new slugs/models), and new capabilities (new CLI flags worth wiring up). Then use `AskUserQuestion` (parallel questions where independent), showing ASCII lineups in `preview`.

### Tool coverage

Per Principle 1, default to proposing **full ladders** for each CLI. Only ask about trimming if the user raises it. When they want every combo, say so explicitly in the question so they're opting into the longer `counselors ls`.

### The four groups — construction & intent

This user's groups are a **4-rung intensity ladder**. Current names and meaning:

```
light       quick & cheap
daily       bread & butter — ~75% of runs (Sonnet anchors it)
heavy       a problem that needs extra umph to review
impossible  max effort, max tokens, cost-no-object
```

Construction rules:
- **Every group mixes all three providers** (Claude + Codex + Gemini/agy) for diverse, independent perspectives at every depth.
- **Each provider steps up one rung per tier**, cheapest model/effort in `light` → flagship at peak effort in `impossible`.
- **`impossible` may widen past 3 tools** — it's the cost-no-object panel, so a 2nd Claude and a different-model Codex buy extra independent high-effort opinions.

These are the *rules*; the specific rungs are a **dated snapshot** (re-derive the actual flagship/cheapest from Phase 3 each run). Snapshot ladders + lineup as of this writing — a baseline to diff against, **not** literals to copy blindly:

```
ladders   Claude:  haiku → sonnet → opus-high → opus-max
          Codex:   gpt-5.4-mini → gpt-5.5-medium → gpt-5.5-high → gpt-5.5-xhigh
          agy:     flash-med → flash-high → pro-low → pro-high

light       : claude-haiku      codex-5.4-mini-medium  agy-flash-med
daily       : claude-sonnet     codex-5.5-medium       agy-flash-high
heavy       : claude-opus-high  codex-5.5-high         agy-pro-low
impossible  : claude-opus-max   claude-opus-xhigh  codex-5.5-xhigh  codex-5.4-xhigh  agy-pro-high
```

If the user retunes, drive it with the same axes: how beefy is `daily` (75% of runs — the most important call), and how maximal is `impossible` (3 tools vs. a wider panel).

### When discovery shows a model this doc doesn't name

Phase 3 will surface models newer than anything written here. Slot them by *role*, not by name:

- **A new flagship in an existing family** (e.g. `gpt-5.6` joins `gpt-5.5`/`gpt-5.4`; a new Gemini Pro gen): per Principle 1, give it its **own full effort ladder** as new tools. In the groups, it **takes the rung the prior flagship held** (so `gpt-5.6-high` replaces `gpt-5.5-high` in `heavy`, `-xhigh` replaces it in `impossible`, etc.). The prior flagship **demotes one rung or becomes the different-model diversity pick** in `impossible` — don't delete it (Principle 1: all available tools stay) unless the live source marks it deprecated/removed, in which case migrate per the `[notice.model_migrations]` map.
- **Claude specifically needs no change for a version bump** — the `opus`/`sonnet`/`haiku` aliases auto-track the latest. Only a brand-new *tier name* (not a version) would need wiring.
- **agy / a new Gemini gen**: confirm the exact display string via `agy models`, add its effort variants, slot the strongest into the rungs the prior Gemini held.
- **A genuinely new tier or provider** (not a version bump of something you already place) — don't guess the ladder position; **ask the user** where it belongs.

Rule of thumb: the doc names *roles* ("cheapest", "flagship", "75%-of-runs anchor", "diversity pick") that survive model churn — map the freshly-discovered models onto those roles and confirm the diff with the user.

**Don't move on until the user confirms.** If a group references a tool ID that's about to change/rename, update the group in the **same write** — never leave dangling references.

---

## Phase 5: Edit the config (the real dotfiles file)

Edit the **resolved** path (`$CFG` from Phase 1), not the symlink. Don't use `counselors tools add` — it's interactive, one tool at a time, with no way to set exact flags.

**For many entries (full ladders), rebuild programmatically with Python** — far more reliable than hand-writing 20+ JSON blocks. Load the JSON, regenerate `tools` from helper functions over the model×effort matrix, preserve the agy variants, rewrite `groups`, assert no dangling refs, dump with `indent=2` + trailing newline. The skeleton resolves the real path itself so it works whether or not the config is symlinked:

```python
import json, os
# resolve symlink -> real target (same as Phase 1's $CFG)
path = os.path.realpath(os.path.expanduser('~/.config/counselors/config.json'))
cfg = json.load(open(path))
def codex(slug, eff): return {"binary":"codex","adapter":"codex","readOnly":{"level":"enforced"},
    "extraFlags":["-m",slug,"-c",f"model_reasoning_effort={eff}"],"timeout":900}
# ...build tools dict in desired display order, set cfg["tools"], cfg["groups"]...
missing=[r for g in cfg["groups"].values() for r in g if r not in cfg["tools"]]; assert not missing, missing
json.dump(cfg, open(path,"w"), indent=2); open(path,"a").write("\n")
```

Tool entry shape:
```json
"<tool-id>": {
  "binary": "claude" | "codex" | "agy" | "/abs/path",
  "adapter": "claude" | "codex" | "gemini" | "amp" | "custom",
  "readOnly": { "level": "enforced" | "bestEffort" },
  "extraFlags": ["..."],
  "timeout": 900
}
```
- `adapter`: built-ins know their CLI's quirks; use `"custom"` for CLIs whose flags the built-ins would get wrong (e.g. `agy`) — counselors then just appends `extraFlags` and trails a `Read the file at <path>...` instruction.
- `extraFlags`: where model/effort flags live (codex `["-m","gpt-5.5","-c","model_reasoning_effort=high"]`; agy `["--model","Gemini 3.1 Pro (Low)","--print-timeout","10m","-p"]`).
- `timeout` (seconds) overrides `defaults.timeout`. High/xhigh/max effort want 900+.
- `readOnly.level`: `"enforced"` for adapters with a built-in read-only mode; `"bestEffort"` for custom adapters.

Groups are arrays of tool IDs (`"impossible"` can have >3). Keep names lowercase/no-spaces (they become `--group <name>`).

---

## Phase 6: Verify

```bash
counselors ls
counselors groups ls
counselors doctor              # binary + version + readOnly + group membership
counselors tools test <ids>    # actually invokes each tool with "Reply OK"
```

**`doctor` does NOT validate model slugs/effort** — it only checks the binary exists and runs `--version`. A bad slug passes doctor and fails at runtime. So always `tools test` the genuinely new shapes (a newly added model, a new effort flag), not just rely on doctor.

`counselors tools test` has a **hardcoded 30s timeout** that ignores per-tool `timeout`. High-effort and Gemini Pro tiers legitimately take longer (Pro ran ~7s here, but cold/loaded can exceed 30s). A timeout-only failure on one tool → re-run the underlying command directly with a longer `--print-timeout`.

### Reading test failures

- **`Timed out after 30s`** — likely cold start / heavy model. Re-run direct with longer timeout.
- **agy returns empty, exit 0, very fast (~1.5s)** — almost always a Pro/preview **account-access 404**. Check the agy log (Phase 3). Config is correct; it's account-side.
- **agy produces plausible output but you suspect the wrong model** — remember agy **silently falls back** on a bad `--model`. Recheck the string against `agy models` and grep the log for `Resolving model "<your string>"`.
- **`You have exhausted your capacity on this model`** (Gemini 429) — quota/rate-limit, not a config bug.
- **`flags provided but not defined: -X`** — wrong adapter or wrong extraFlag for that CLI.
- **`gpt-X.Y not found`** / model-id errors — bad slug; cross-check `~/.codex/models_cache.json`.

---

## Phase 7: Summarize and update related state

Tell the user:
1. Final tool list + group structure.
2. Backup path (`~/.config/counselors/config.json.bak-…`).
3. Any test failures and *why* — config bug vs. account-side (quota/access) vs. test-harness timeout.
4. Where the edits landed (the resolved `$CFG`). If that's inside a git/dotfiles repo, they're **uncommitted** — offer to commit.

The `counselors` slash-command (`~/.claude/commands/counselors.md`) **discovers groups dynamically** (`counselors groups ls`) and doesn't hardcode group names — so renaming groups needs no edit there. Double-check anyway if the rename was large.

---

## Reference: sticky facts for this user's setup

- **Resolve the config path first** — `~/.config/counselors/config.json` is often a symlink (this user dotfiles it). Always `readlink -f` / `os.path.realpath` and edit the real target; Write/Edit refuse symlinks. If the target is in a git repo, changes land uncommitted.
- **Claude** — aliases (`opus`/`sonnet`/`haiku`) auto-track latest; `--effort low/medium/high/xhigh/max` stacks on top.
- **Codex** — `~/.codex/models_cache.json` is source of truth; `[notice.model_migrations]` in `config.toml` lists deprecations. Current models: `gpt-5.5`, `gpt-5.4`, `gpt-5.4-mini`. `codex-auto-review` is hidden — exclude.
- **agy (Antigravity)** — **1.0.5+ has `--model`** (display-name strings from `agy models`); per-model variants are normal. Still `adapter: "custom"`. **Silently falls back on a bad model name.** **Pro/preview tiers can 404 on account access** → empty output, exit 0; the reason is only in `~/.gemini/antigravity-cli/cli.log`. Update via `agy update`.
- **Gemini CLI vs agy** — `agy` is the successor most setups are moving to, but don't assume the switch is done: `which gemini` / `which agy` and work from what's actually installed. A `gemini`→`agy` migration is a Phase-4 proposal to confirm, not a given.
- **The four groups** are `light` / `daily` / `heavy` / `impossible` (intensity ladder). `daily` ≈ 75% of runs (Sonnet-anchored). `impossible` is cost-no-object and may run >3 tools. Each group mixes all three providers.
- **`counselors tools test`** has a hardcoded 30s timeout that ignores per-tool `timeout`. **`counselors doctor`** never validates model slugs.

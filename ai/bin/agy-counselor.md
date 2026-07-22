# `agy-counselor` — why this wrapper exists

`agy-counselor` is a thin `bash` wrapper around the [Antigravity CLI](https://antigravity.google) (`agy`),
used **only** by [counselors](https://github.com/aarondfrancis/counselors) (see `../counselors-config.json`,
which sets `"binary": "agy-counselor"` for every `agy-*` tool). It exists to work around two
**print-mode** (`-p`) failure modes that affect the **Gemini Pro** models. It does nothing but append
output-steering text to the prompt — if `agy` ever fixes these, the wrapper can be deleted (see below).

## The problem it solves

When counselors runs `agy ... -p "<prompt>"` it reads the model's answer from **stdout**. The Pro models
(`Gemini 3.1 Pro (Low)` / `(High)`) misbehave under that contract in two ways — Flash models do not:

1. **Answer goes to a file, not stdout.** Pro sometimes uses its file-write tool to dump the review into
   a file (e.g. `review.md`) and prints only a short pointer like *"You can read the full review here…"*.
   counselors captures stdout, so the actual answer is lost.
2. **Print-mode timeout → all work discarded.** Pro's agentic planner loop is slow and high-variance. On a
   heavy prompt it can exceed `--print-timeout`, at which point `agy` prints
   `Error: timed out waiting for response`, exits 0, and **throws away everything it produced**. Counselors
   faithfully records the 6-word error as the model's "review".

### Diagnosis signature (how this was confirmed — 2026-06-10)

A real `heavy`-group run had `agy-pro-low` return only `Error: timed out waiting for response`.
`run.json` showed `durationMs: 602064` (≈602s = exactly the `--print-timeout 10m`), `wordCount: 6`, exit 0.
The agy log for that run (`~/.gemini/antigravity-cli/log/cli-*.log`) showed the fingerprint:

```
printmode_manager.go:90] PlannerResponse without ModifiedResponse encountered   (repeated ~20×)
printmode.go:280] Print mode: timed out after 2984 polls (printed=57)
```

The error string comes from **agy itself**, not counselors. Re-running the *same* prompt sometimes finished
in <2 min with a full review — it's nondeterministic, which is why Pro looked "sometimes broken".

## A third failure mode the wrapper canNOT fix: headless permission denials (agy ≥ 1.1.3)

**Symptom (2026-07-20, agy 1.1.4):** every agy counselor — Flash included — returns nothing (or only a
one-line `jetski: no output produced — a tool required the "…" permission…` stderr notice). Runs end in
seconds. The agy log fingerprint is:

```
tool_confirmation_manager.go:183] Print mode: soft-denying tool confirmation "ReadFile" at step N
```

**Cause:** agy 1.1.3 changed headless (`-p`) behavior — tools that need a permission confirmation are now
**soft-denied** instead of auto-approved ("Fixed headless (`-p`) runs hanging or silently auto-approving
tools…" in `agy changelog`). The model can't read files or run commands, so it produces no review.

**Fix:** allow-rules in `~/.gemini/antigravity-cli/settings.json` (a live file, not dotfiles-managed)
under `permissions.allow`. Rules are `<permission>(<target>)`; `read_file(*)` covers reads, and
`command(<argv-prefix>)` matches a command whose argv starts with the target (`command(git log)` matches
`git log --oneline -2`; bare `command(git)` matches any git command — kept scoped to read-only
subcommands instead). The deliberately read-only allowlist as of 2026-07-20: `read_file(*)` plus
`cat ls head tail grep rg find wc pwd echo which diff tree sort uniq cut basename dirname file stat
realpath` and `git log/diff/show/status/branch`. If a future counselor run dies with a new
`a tool required the "X" permission` notice, add the rule the notice names.

Note these rules also auto-approve those tools in **interactive** agy sessions — that's why the git rules
are scoped (a bare `command(git)` would silently allow `git push`).

**Two extra findings from re-testing raw agy 1.1.4 without the wrapper (2026-07-20, 2× Pro Low on a real
heavy review prompt):**

- **A single denied tool call aborts the whole print-mode run** — no partial output, exit 0. One run did
  17 steps of review work, tried `pnpm build && pnpm lint && pnpm test` (rightly not allowlisted), and
  died with empty stdout. The denial is not fed back to the model as a recoverable error. Hence the
  steering now explicitly forbids builds/tests/state-changing commands.
- **Artifacts bypass the permission regime.** The other run finished cleanly but wrote the full review to
  an internal artifact (`~/.gemini/antigravity-cli/brain/<id>/review.md`) and printed only a ~165-word
  teaser + pointer. Artifact writes are not workspace file-writes, so `permissions.allow` cannot block
  them — original failure mode 1 is alive in 1.1.4 and only the steering prevents it.

## What the wrapper does

On runs that include `-p`/`--print`/`--prompt`, it appends a `CRITICAL OUTPUT REQUIREMENTS` block to the
last argument (the prompt) instructing the model to: print the complete answer inline, never write/modify
files, and budget time so a complete answer lands before the timeout. Non-print invocations
(`--version`, `--help`, subcommands) pass through untouched so `counselors doctor` still works.

Companion config changes (in `../counselors-config.json`): the two Pro tools also got
`--print-timeout 18m` and counselors `timeout: 1200` for headroom. Flash tools were never affected but
route through the wrapper too, for uniformity.

## How to check whether `agy` still needs this

`agy` ships print-mode fixes regularly (the 1.0.x changelog has several "stuck state" fixes). After an
`agy` upgrade, re-evaluate. **Point me (Claude) at this file** and ask me to re-test, or do it by hand:

1. Pick a heavy review prompt (or reuse an old one under `<repo>/agents/counselors/*/prompt.md`).
2. Run **raw `agy`** (NOT the wrapper) several times — Pro is nondeterministic, so test 3–5×:
   ```
   agy --model "Gemini 3.1 Pro (Low)" --print-timeout 10m --log-file /tmp/agy.log \
       -p "Read the file at <abs/path/to/prompt.md> and follow the instructions within it."
   ```
3. The wrapper is **no longer needed** if, across runs, raw `agy` reliably:
   - prints the full answer to **stdout** (doesn't write it to a file and point at it), and
   - finishes well inside the timeout (no `Print mode: timed out` / `PlannerResponse without
     ModifiedResponse` storm in `/tmp/agy.log`).

## How to remove it once it's no longer needed

1. In `../counselors-config.json`, change each `agy-*` tool's `"binary": "agy-counselor"` back to
   `"binary": "agy"`. Optionally restore the Pro tools to `--print-timeout 10m` / `timeout: 900`.
2. Delete the dotbot link block for `~/.local/bin/agy-counselor` in `../../install.conf.yaml`.
3. Delete `agy-counselor` and this file from `ai/bin/`, and remove the symlink:
   `rm ~/.local/bin/agy-counselor`.
4. `counselors doctor` to confirm the `agy-*` tools still resolve (now directly to `agy`).

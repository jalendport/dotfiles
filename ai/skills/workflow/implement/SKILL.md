---
name: implement
description: "Implement a piece of work based on a spec or set of tickets."
disable-model-invocation: true
---

# Implement

Implement the work described by the user in the spec or tickets. Work tracking follows the `/track-work` skill — fetch the spec or tickets through it, and keep ticket state current as you go: claim before starting, progress in comments, complete on landing.

## Inside Solo: lead/worker orchestration

You are the **lead agent**: you plan, dispatch, and integrate — workers build. Before dispatching a multi-lane run, `mcp_smoke_test` once — five workers against a broken Solo install is an expensive way to find out.

### 1. Gather the lanes

- **Tickets already exist** (a `/create-todos` run published todos for this work): adopt them as the lanes. Read the frontier — `todo_list` with `is_blocked: false`, tag `ready-for-agent` — and take the blocking edges as the orchestration plan. Create nothing.
- **No tickets yet** (working straight from a spec or conversation): settle goal, constraints, files in play, risks, and verification with the user — one round in the `/grilling-base` format, skipping whatever the spec answers — then convert the plan into bounded todos per `/track-work`, each carrying its objective, its **ownership boundary** (the exact files the lane owns), and its expected output, wired with `todo_set_blockers`.

**Single lane?** When the tickets form a linear chain (or there is one ticket), skip the workers and build it yourself: `todo_lock`, `/tdd` at the pre-agreed seams, typecheck regularly, progress in comments, then straight to step 5.

### 2. Plan in a scratchpad

Write (or update) a scratchpad tagged `plan`: goal, branch/worktree, code paths, constraints and non-goals, the lanes and their dependencies, verification steps, handoff expectations. Link the spec pad with its `solo://` link. The pad is the durable record — chat scrollback is not.

### 3. Dispatch one worker per unblocked lane

For each frontier todo: `spawn_agent` (pick the tool via `list_agent_tools`; include the returned `agent_instructions` in the first prompt), then `send_input` a prompt stating the exact objective, the files the worker owns, what to leave untouched, which todo to `todo_lock` and comment on, and `/tdd` at the lane's pre-agreed seams. One lane, one worker, one expected handoff. When two lanes genuinely must touch one shared file (a route table, a barrel export), have them coordinate through `lock_acquire` on an agreed lock key — acquisition is non-blocking, so poll to retry — rather than widening either ownership boundary.

### 4. Monitor and integrate lane by lane

Set `timer_fire_when_idle_any` over the worker processes, with a max wait. When woken, inspect the worker's real output and diff — its summary is triage, not evidence. Review each finished lane's diff, run its tests, integrate, and tell still-running workers about relevant edits via `send_input` before they continue. `todo_complete` each landed lane; newly unblocked lanes get workers (back to step 3) until no open todos remain.

### 5. Verify and close out

Run the full test suite and typecheck. Review the whole change with `/code-review`. Capture handoffs — changed files, tests run, remaining risks — in todo comments and the plan pad, then commit with `/commit` and close the worker processes (`close_process`).

## Outside Solo (no `SOLO_PROCESS_ID`)

Single-agent flow. Claim the ticket file (`Status: claimed`), use `/tdd` where possible at pre-agreed seams, run typechecking regularly, single test files regularly, and the full test suite once at the end. Review with `/code-review`, commit with `/commit`, then resolve the ticket file (`## Answer`, `Status: resolved`).

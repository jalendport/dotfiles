---
name: track-work
description: Where agent work is tracked on this machine — Solo todos and scratchpads inside Solo, `.agents/` markdown files outside it. Read before creating, reading, or updating any ticket, todo, spec, research note, or work map, and before delegating work to another agent.
---

# Track Work

One tracker convention, two backends. Detect the backend once per session, then follow its rules. Every skill that publishes or fetches tracked work (tickets, specs, research, maps) goes through this document — it is the single place the convention changes.

## Detection

- `SOLO_PROCESS_ID` env var is set → this is a Solo-managed process. Use the **Solo backend** through the `solo` MCP tools. Call `whoami` once to confirm identity and effective project scope.
- Otherwise → plain terminal (Ghostty, CI, anywhere else). Use the **markdown backend**.

## State vocabulary

Five triage states, used identically by both backends:

`needs-triage` · `needs-info` · `ready-for-agent` · `ready-for-human` · `wontfix`

A work item carries **exactly one** state at a time. Skills that reference "triage labels" or "the label vocabulary" mean this list.

## Solo backend

Speak the MCP tools directly (`todo_*`, `scratchpad_*`); keep the default `slim` response mode unless the full payload is needed.

**Tickets are todos.**

- Create with `todo_create` — title, markdown body, `priority` (`high`/`medium`/`low`).
- Blocking edges are native: `todo_set_blockers` / `todo_add_blocker`. Query the frontier with `todo_list` + `is_blocked: false`.
- Todo statuses are fixed (`open`, `in_progress`, `backlog`, `completed`), so the state vocabulary rides on **tags**: apply the state as a tag, and swap tags (`todo_add_tag` / `todo_remove_tag`) on transition. A `wontfix` todo also moves to status `backlog` — parked, never falsely completed.
- To work a todo: `todo_lock` it (a visible lease — the documented "an agent is on this" signal), set status `in_progress`; finish with `todo_complete`.
- Activity, findings, and handoffs go in **comments** (`todo_comment_create`), not body rewrites — the body stays the ticket, the comments are the timeline.

**Specs, research notes, and work maps are scratchpads.**

- One pad per artifact; the leading H1 is the title. Tag the pad by kind: `spec`, `research`, or `map`. A pad may also carry one state tag from the vocabulary — a `spec` tagged `ready-for-agent` is implementable as-is.
- Edit with revision guards (`expected_revision` on `scratchpad_edit` / `scratchpad_append_section`) — read before write.
- Cross-link with `solo://` deep links in todo bodies and comments (ticket ↔ spec).

**File bridge.** When a file copy is wanted (or a pad must travel to a non-Solo session): `scratchpad_save_to_file` exports to `.agents/…` per the markdown layout below; `scratchpad_load_from_file` imports back.

## Markdown backend

Every agent-generated artifact that does not belong in the repo lives under `.agents/` at the repo root. The folder is ignored by the machine-global gitignore — never commit it, and never add it to a repo's own `.gitignore`.

Layout:

- `.agents/todos/<feature-slug>/NN-<slug>.md` — one file per ticket, numbered from `01`
- `.agents/specs/<feature-slug>.md` — specs; a wayfinder map is `.agents/specs/<effort-slug>-map.md`
- `.agents/research/<slug>.md` — research findings
- `.agents/handoffs/<slug>.md` — session handoff documents
- Anything else groups under a kind-named folder, `.agents/<kind>/` — the skill that writes the artifact names its own (reports, wizards, diagnostics, prototypes, …)

Ticket file conventions (the local mirror of the todo fields):

- A `Status:` line near the top carrying one state from the vocabulary; a claiming agent sets `Status: claimed` before any work, and `Status: resolved` (with the answer under an `## Answer` heading) when done
- A `Blocked by: NN, NN` line for blocking edges; a ticket is unblocked when every listed ticket is resolved
- The frontier: scan the feature's folder for files that are open, unblocked, and unclaimed — first by number wins
- Conversation history appends under a `## Comments` heading

## Delegation

Two ways to hand work to another agent; **the output's home decides**:

- **Native subagents** (your tool's own — e.g. Claude's `Agent` tool) for legwork that feeds the current conversation: fact-finding, parallel review axes, design sketches, codebase exploration. Results return inline, automatically, and die with the session.
- **Solo agents** (`spawn_agent`) for lanes with their own deliverable in the tracker: implementation lanes, research tickets, AFK tasks. A Solo agent gets visibility (its own tab), persistence beyond the session, and todo/scratchpad coordination — and any configured runtime can take the lane (`list_agent_tools`: Claude, Codex, Gemini, …), so match the model to the work. Handoffs come back through the tracker (todo comments, scratchpads), never inline.

If the output's home is the conversation, use a native subagent; if its home is the tracker, spawn a Solo agent.

## Notes

- Solo also exposes a loopback HTTP API for tooling that cannot speak MCP — port, bearer token, and endpoint catalog live in `~/.config/soloterm/http-api.json` (token regenerates on every server start).
- Solo's docs are agent-readable at `https://soloterm.com/api/v1/docs/<section>/<page>` (for example `/todos/using-todos`, `/mcp-tools/todos`); `help(topic="todos")` on the MCP server is the runtime equivalent.

---
name: research
description: Investigate a question against high-trust primary sources and capture cited findings per the track-work convention. Use when the user wants a topic researched, docs or API facts gathered, or reading legwork delegated to a background agent.
---

Spin up a **background agent** to do the research, so you keep working while it reads. The findings' home is the tracker, so delegate per `/track-work`: `spawn_agent` in Solo (reading legwork suits a cheap runtime), your tool's native background subagent otherwise — spawned on your cheap tier from the delegation table (`DELEGATION.md`, beside your instructions file), passed explicitly rather than inherited from the session. The researcher writes files, so pick a write-capable agent type, not a read-only one.

Its job:

1. Investigate the question against **primary sources** — official docs, source code, specs, first-party APIs — not a secondary write-up of them. Follow every claim back to the source that owns it.
2. Write the findings as a single Markdown document, citing each claim's source.
3. Publish it per `/track-work` as a `research` artifact, and say where it landed.

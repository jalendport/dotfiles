---
name: research
description: Investigate a question against high-trust primary sources and write the cited findings as one Markdown document. Use when the user wants a topic researched, docs or API facts gathered, or reading legwork handed to a Lane.
---

Research is reading legwork, so it leaves the session: write a Brief with `category: research` (read access by default) whose Goal is the question and whose Done is the document below, then `maestro dispatch <brief.md>` and keep working while the Lane reads. `maestro help brief` prints the format. Read it yourself only when one or two sources answer the question.

The contract, whoever reads:

1. Investigate the question against **primary sources** — official docs, source code, specs, first-party APIs — not a secondary write-up of them. Follow every claim back to the source that owns it.
2. Write the findings as a single Markdown document, citing each claim's source.
3. Publish it as a research artifact — a scratchpad tagged `research` in Solo (`SOLO_PROCESS_ID` is set), `.agents/research/<slug>.md` otherwise (`.agents/` is globally gitignored, never committed) — and say where it landed.

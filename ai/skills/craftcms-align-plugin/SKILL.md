---
name: craftcms-align-plugin
description: Audit and retrofit a Craft CMS plugin against Jalen's authoring standards stored in the brain vault. Use when asked to align, audit, retrofit, standardize, or check standards compliance for a craft-* plugin (or when scaffolding a new one). The standards themselves live in ~/brain — this skill only carries the procedure.
---

Align a Craft plugin to Jalen's authoring standards. **This skill contains no rules.** The standards are the brain vault's, and only the vault's — never apply generic Craft habits or third-party guideline packs.

## 1. Load the standards (every run — they evolve)

1. Read `~/brain/conventions/craftcms/craft-plugin-authoring-standards.md` (the hub), then every convention note it wikilinks.
2. **Completeness sweep** (the hub index can lag new notes): glob `~/brain/conventions/{craftcms,php,general}/*.md` and compare against what the hub links. For any note the hub doesn't reach, read its Rule line; if it bears on plugin authoring, apply it like any other note and flag it in the report as "not yet indexed by the hub" (offer to add the wikilink). Notes that are legitimately out of scope (agent-workflow conventions, site/project-only rules) just get skipped — say so only if borderline.
3. Honor the tag contract from `~/brain/AGENTS.md`: `adopted`/`best-practice` notes apply unconditionally; `draft` notes apply too (they're Jalen's settled-but-unreviewed decisions) but flag them as draft in the report; `deprecated`/`experimental` never apply silently.
4. If notes conflict, the hub note's summary line is the tiebreaker; mention the conflict.

## 2. Audit

Survey the target plugin against each dimension the hub lists (composer.json shape, src/ layout, plugin class patterns, settings/config, logging, code style, docblocks, QA stack, changelog, README, branches, hygiene files). Produce a compliance table: **dimension → pass / drift / missing → the convention note it comes from**, with file:line evidence for drifts. Report first; don't fix during the audit pass.

## 3. Retrofit (only when asked, or when invoked with "align"/"retrofit")

- Fix in this order: composer.json shape → plugin class + services → settings/config.php → style sweep → hygiene files (CI, issue templates, .gitattributes, translations) → README/CHANGELOG format.
- Base-package rule: if the plugin duplicates something `jalendport/craft-base` provides (logging, controller helpers, configWarning macro), switch it to the base package rather than fixing the local copy. If you find boilerplate repeated across plugins that base *doesn't* provide yet, propose promoting it — don't copy-paste a third instance.
- Run the QA scripts (`check-cs`, `phpstan`, `test`) after the retrofit; all green before reporting done. No host PHP on this machine — use the composer Docker image (`docker run --rm -v "$PWD":/app -w /app composer:2 …`), or `docker compose exec php …` when working inside a site.
- Never bump versions, tag, or push releases from this skill — that's `/cut-release`.

## 4. Gaps in the standards

If the plugin raises a decision no convention note covers, don't invent a rule. Ask Jalen (or note it as an open question in the report) and offer to capture the answer as a new draft note in `~/brain/conventions/craftcms/` per the vault's template and contract.

---
name: align-craftcms-plugin
description: Audit and retrofit a Craft CMS plugin against the authoring standards in the brain vault. Use when asked to align, audit, or retrofit a craft-* plugin, or when scaffolding a new one.
---
# Align Craft CMS plugin

Align a Craft plugin to the vault's authoring standards — the vault's, and only the vault's. This skill carries no rules, only the procedure.

## 1. Load the standards (every run — they evolve)

1. Read `~/brain/conventions/craftcms/craft-plugin-authoring-standards.md` (the hub), then every convention note it wikilinks.
2. Completeness sweep — the hub index can lag new notes: glob `~/brain/conventions/{craftcms,php,general}/*.md` and compare against what the hub links. For each note the hub misses, read its Rule line; if it bears on plugin authoring, apply it like any other note and flag it in the report as "not yet indexed by the hub" (offer to add the wikilink).
3. Weight each note by its `status` per the tag contract in `~/brain/AGENTS.md`; flag any applied `draft` note as draft in the report.
4. When notes conflict, the hub's summary line wins; mention the conflict.

## 2. Audit

Survey the plugin against every dimension the hub lists. Produce a compliance table — dimension → pass / drift / missing → the convention note it comes from — with `file:line` evidence for each drift. The audit pass is report-only; fixes wait for the retrofit.

## 3. Retrofit (when asked, or when invoked with "align" / "retrofit")

- Fix in this order: composer.json shape → plugin class + services → settings/config.php → style sweep → hygiene files (CI, issue templates, `.gitattributes`, translations) → README/CHANGELOG format.
- Duplicated boilerplate follows `~/brain/conventions/craftcms/craft-base-shared-package.md`: switch it to the base package, or propose promotion for boilerplate the base lacks.
- Run the plugin's QA scripts in Docker per `~/brain/conventions/general/run-dev-tooling-in-docker.md`; the retrofit is done only when every script passes.
- Version bumps, tags, and releases belong to `/cut-release`.

## 4. Gaps in the standards

A decision no convention note covers is the user's to make: ask, or log it as an open question in the report. Offer to capture the answer through the capture-to-brain skill so the vault gains the rule.

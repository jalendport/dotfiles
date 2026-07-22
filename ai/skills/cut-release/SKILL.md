---
name: cut-release
description: Cut a tagged release for one of Jalen's projects — pull latest, verify what's pending, finalize the version bump + changelog, merge to the release branch, tag, and push. Use when Jalen says "cut a release", "cut X.Y.Z", "release", "tag X.Y.Z", "bump the version", or "push and tag". Auto-detects git-flow vs. trunk and where the version number lives.
---

Cut a release the way Jalen already does it by hand. **Never invent the process — detect it from the repo, then mirror the last release exactly.** Follow the git convention in `~/brain/conventions/git/` and the commit-message rules in the global `AGENTS.md`.

## 0. Preconditions
- Confirm the target version if not given (`X.Y.Z`, semver). If Jalen just says "cut a release," infer the bump from the pending changes and propose it.
- **Pull latest first** — Jalen almost always says "pull the latest before you start." Fetch and pull every branch involved (`main`/`master` *and* `develop` if git-flow).

## 1. Detect the release pattern (don't assume)
Read the repo's own history so you copy it precisely:
- **Branch model** — does `develop` exist and lead `master`/`main`? `develop` + a `master` that only ever moves at releases = **git-flow-lite** (Jalen's plugin repos). No develop branch / releases straight off main = **trunk**. Note older releases in these repos show a `Merge branch 'develop' for X.Y.Z release` commit — that `--no-ff` pattern is **retired**, don't copy it forward (see step 3).
- **Where the version lives** — grep for the current version string. Common homes: `composer.json` (`"version"`), `package.json`, a `VERSION` file, a plugin main class constant. Craft plugins: `composer.json` only — `schemaVersion` is unrelated, leave it unless there are new migrations.
- **Changelog format** — Keep a Changelog with an `## Unreleased` (or `## [Unreleased]`) heading is Jalen's norm. New features are usually already staged there.
- **Tag format** — `git tag --list | tail`. Jalen tags **bare semver, no `v` prefix** (`3.1.0`, not `v3.1.0`), as a **lightweight tag**. On git-flow-lite it lands on the `Finalize X.Y.Z release` commit (which `master` fast-forwards onto); older tags sit on retired merge commits — match the version format, not the old placement.

## 2. Finalize the release on the working branch
On `develop` (git-flow) or `main` (trunk):
1. **Bump the version** in the file(s) found in step 1.
2. **Finalize the changelog**: rename the `## Unreleased` section to `## X.Y.Z - YYYY-MM-DD` (use `date +%F`). Keep the Keep-a-Changelog subsection order (`Added` / `Changed` / `Fixed` / `Removed`). Add a fresh empty `## Unreleased` above it only if the project keeps one between releases. Don't rewrite existing entries — only what's genuinely pending. If entries are thin, read the diff since the last tag and draft accurate ones.
3. Commit the finalize with a single-line message per Jalen's convention, e.g. `Bump version to 3.1.0` or `Finalize 3.1.0 release` (+ `Co-Authored-By:` trailer since an agent is committing).

## 3. Merge, tag, push
- **git-flow-lite**: `git checkout master && git merge --ff-only develop`, then tag `X.Y.Z` on that commit. Push `develop`, `master`, and the tag. **Never `--no-ff`** — a release merge commit exists only on `master`, stranding a commit the default branch (`develop`) never contains, which permanently diverges the branches and makes GitHub nag "master had recent pushes" forever. Fast-forwarding keeps `master` an ancestor of `develop` at all times.
- If the fast-forward is **refused**, stop — don't reach for `--no-ff`. It means `master` has something `develop` lacks (a direct hotfix, or a legacy `--no-ff` merge from before this rule). Reconcile once by merging `master` into `develop`, then fast-forward.
- **trunk**: tag `X.Y.Z` on the release commit; push branch + tag.
- Use `git push origin <branch>` then `git push origin <tag>` (or `--tags`) — never force-push a release.

## 4. Verify and report
- Confirm the tag points at the intended commit: `git show X.Y.Z --stat | head`.
- If the repo publishes via GitHub Releases / Packagist / a Craft plugin store, note whether the push already triggers it or whether Jalen needs a manual step (don't create a GitHub Release unless asked).
- Report: version bumped in `<file>`, branches pushed (`old..new` ranges), tag created on `<sha>`, and any follow-up (e.g. "Packagist will pick this up automatically" / "publish the release notes when ready").

## Guardrails
- If tests exist and can run locally, run them before tagging; if they can't (no `vendor/`, CI-only), say so rather than silently skipping — don't `composer install` a whole tree just to test unless asked.
- **Version-consistency check before pushing**: if the version string lives in more than one file (composer.json + a manifest + a docs string), verify every site equals the tag; on mismatch, stop and name the exact file to fix rather than tagging a half-bumped release.
- **Maintenance-branch releases don't steal "Latest"**: if the tagged commit is not an ancestor of the default branch (`git merge-base --is-ancestor <tag> origin/main`), any GitHub Release created for it must pass `--latest=false` so a backport doesn't displace the real latest release.
- Don't retag or move an existing tag. If the version already exists, stop and flag it.
- Keep changelog prose factual and specific — match the detailed, issue-linked style already in the file (`([#28](...))`).

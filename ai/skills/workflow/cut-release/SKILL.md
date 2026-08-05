---
name: cut-release
description: Cut a tagged release for the current project, mirroring how the repo already releases. Use when the user says "cut a release" / "cut X.Y.Z", "tag X.Y.Z" / "push and tag", or "bump the version".
---
# Cut release

Release the way the repo already releases — detect the pattern from its own history and mirror the last release exactly. The release rules live in the vault; this skill carries only the procedure.

## 1. Sync and confirm the version

- Fetch and pull every branch involved (`main`/`master`, plus `develop` when it exists) before touching anything.
- Confirm the target version — bare semver `X.Y.Z`. Given just "cut a release", infer the bump from the pending changes and propose it. A first release is `1.0.0` (`~/brain/conventions/general/first-release-is-1-0-0.md`).

## 2. Load the rules, detect the pattern

Read the vault notes that govern releases (every run — they evolve):

- `~/brain/conventions/craftcms/plugin-versioning-branching-and-releases.md` — branch model, the fast-forward rule, tag placement, hotfix lines.
- `~/brain/conventions/general/changelog-release-notes-format.md` — heading shape, entry style, what earns an entry.
- `~/brain/conventions/git/` — commit message format and agent trailer.

Then read the repo itself:

- **Branch model** — `develop` leading `master` = git-flow-lite per the versioning note; no `develop` = trunk, releasing straight off `main`.
- **Version home** — grep for the current version string (`composer.json`, `package.json`, a `VERSION` file, a main-class constant). A plugin may carry none — the tag alone is the version (versioning note) — and then the "bump" is changelog + tag only. Craft's `schemaVersion` is migration state; a release leaves it alone.
- **Tag format** — `git tag --list | tail`: bare-semver lightweight tags (`3.1.0`, never `v3.1.0`) on the `Finalize X.Y.Z release` commit. Older tags may sit on retired `--no-ff` merge commits — match the format, not the placement.

## 3. Finalize on the working branch

On `develop` (git-flow-lite) or `main` (trunk):

1. Bump the version in every file found in step 2, if any.
2. Stamp the changelog: `## Unreleased` becomes `## X.Y.Z - YYYY-MM-DD` (`date +%F`), formatted per the changelog note. Existing entries stay as written; if they're thin, read the diff since the last tag and draft accurate ones.
3. Commit with a single-line message per the git conventions, e.g. `Finalize 3.1.0 release`.

## 4. Merge, tag, push

- **git-flow-lite**: `git checkout master && git merge --ff-only develop`, tag the result, then push `develop`, `master`, and the tag. A refused fast-forward means `master` holds something `develop` lacks — stop, reconcile per the versioning note's exception (merge `master` into `develop` once), then fast-forward.
- **trunk**: tag the release commit; push branch + tag.
- Before pushing, every file carrying the version string must equal the tag; on a mismatch, stop and name the exact file to fix.
- Push plain — `git push origin <branch>`, then `git push origin <tag>`. A release is never force-pushed.

## 5. Verify, then report

The release is done only when both checks hold:

- The tag points at the intended commit (`git show X.Y.Z --stat | head`).
- Publishing is accounted for: say whether the push already triggers it (Packagist, the Plugin Store's `create-release.yml`) or a manual step remains. A GitHub Release itself is created only on request.

Report: version bumped in `<file>`, branches pushed (`old..new` ranges), tag on `<sha>`, and any follow-up left for the user.

## Guardrails

- If tests exist and run locally, run them before tagging; if they're CI-only (no `vendor/`), say so rather than silently skipping — installing a dependency tree just to test needs an ask.
- An existing tag is immutable: if `X.Y.Z` is already taken, stop and flag it.
- A maintenance-line release (the tag is not an ancestor of the default branch — check with `git merge-base --is-ancestor`) passes `--latest=false` to any GitHub Release, so a backport never displaces the real latest.

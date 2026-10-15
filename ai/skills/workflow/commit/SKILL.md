---
name: commit
description: Commit pending work following the vault's commit conventions. Use when the user asks to commit, or another skill needs a commit made.
---

# Commit

1. Survey everything pending — staged, unstaged, and untracked.
2. Group unrelated work into separate logical commits; propose the split when it isn't obvious.
3. Read the notes in `~/brain/conventions/git/` and follow them — message format, agent trailer, and staging rules all live there.
4. Run every commit as `COMMIT_SKILL=1 git commit ...` — the Claude Code hook `enforce-commit-skill.sh` denies a `git commit` without that prefix, so commits only happen through this skill.
5. Push only when asked.
6. Report each commit made — hash and message — plus anything deliberately left uncommitted.

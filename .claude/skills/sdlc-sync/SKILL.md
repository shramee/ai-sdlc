---
name: sdlc-sync
description: Pull a merged PR's changes back with `ai-sdlc sync`. Use right after a PR merges, to fast-forward the repo's default branch and (in submodule projects) commit the updated pointer in the parent repo.
---

# Sync

```bash
ai-sdlc sync [repo ...]                  # defaults to every repo in REPOS
ai-sdlc sync --delete-merged [repo ...]  # also drop merged branches + worktrees
```

Fast-forwards each repo's default branch without moving whatever is checked
out. In submodule projects (`project_is_superrepo`), also commits the
pointers that actually moved in the parent — but does **not** push it;
review (`git show`) and push manually.

It asks GitHub which agent branches' PRs merged (squash merges never look
merged locally) and lists them. Delete those with `--delete-merged` — a
squash-merged branch left around stays "ahead" forever, and dispatch refuses
to stack new work on it.

## When to run it

Immediately after merging a PR from [`sdlc-review`](../sdlc-review/SKILL.md),
before the next spec that branches off this repo's default — otherwise the
next worktree branches off a stale base.

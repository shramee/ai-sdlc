---
name: sdlc-sync
description: Pull a merged PR's changes back with `cli sync`. Use right after a PR merges, to fast-forward the repo's default branch and (in submodule projects) commit the updated pointer in the parent repo.
---

# Sync

```bash
cli sync [repo ...]        # defaults to every repo in REPOS
```

Checks out and fast-forwards each repo's default branch. If the project root
is itself a git repo tracking the listed repos as submodules
(`project_is_superrepo` in `cli`), also stages and commits the moved
submodule pointer(s) in the parent — but does **not** push that commit;
review it (`git show`) and push manually, or fold it into the next thing
you're already pushing.

## When to run it

Immediately after merging a PR from [`sdlc-review`](../sdlc-review/SKILL.md),
before starting the next spec that branches off this repo's default —
otherwise the next `cli dispatch` worktree branches off a stale base and
inherits a merge it didn't need to.

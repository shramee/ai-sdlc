---
name: sdlc-ship
description: Validate and ship a dispatched branch with `ai-sdlc ship` — tests, the quality gate, then push and open a PR. Use when a spec's work looks complete and needs to become a reviewable PR.
---

# Ship

```bash
ai-sdlc ship --dry-run agent/<slug>   # what would be validated, pushed, opened
ai-sdlc ship agent/<slug>
```

Runs on the host, needs `gh` auth. Fetches, then runs the repo's
`test_cmd_for` command and the quality gate in the worktree that has the
branch checked out (never the repo's default checkout); pushes and
opens/updates a PR only if **both** are green. First ship opens the PR; later
ships push onto the open one.

It refuses — and exits non-zero — when the tree has uncommitted or untracked
files, when a worker still holds the worktree, or when gh can't say whether
the branch already has a PR. A bare `ship` only looks at branches under
`AGENT_BRANCH_PREFIX`; name any other branch explicitly.

## If it fails

**Do not fix it yourself, even a one-line fix** — re-dispatch on the same
branch with the failure output as the prompt (see
[`sdlc-dispatch`](../sdlc-dispatch/SKILL.md)'s "resuming a branch"). The one
sanctioned exception is `sdlc-checkout` direct-edit mode, entered
deliberately and announced — never as a shortcut around a failed ship.

Untracked files that the worker forgot to commit go back to a dispatch too;
build output that validation left behind should be gitignored (ship reports
it but never deletes it).

A quality-gate failure is not a false alarm to route around: read
`docs/REVIEW.md` for what the score means, then dispatch the fix it implies.

## Once it's pushed

Do not merge yet — hand off to [`sdlc-review`](../sdlc-review/SKILL.md).
Green `ai-sdlc ship` is a necessary gate, not the review; tests-passing doesn't
self-approve a merge (`docs/REVIEW.md`).

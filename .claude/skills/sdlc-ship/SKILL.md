---
name: sdlc-ship
description: Validate and ship a dispatched branch with `cli ship` — tests, the quality gate, then push and open a PR. Use when a spec's work looks complete and needs to become a reviewable PR.
---

# Ship

```bash
cli ship agent/<slug>
```

Runs on the host, needs `gh` auth. Runs the repo's `test_cmd_for` command
and the quality gate; pushes and opens/updates a PR only if **both** are
green. First ship opens the PR; later ships push onto it ("already exists"
is the normal resume path, not an error).

## If it fails

**Do not fix it yourself, even a one-line fix** — re-dispatch on the same
branch with the failure output as the prompt (see
[`sdlc-dispatch`](../sdlc-dispatch/SKILL.md)'s "resuming a branch"). The one
sanctioned exception is `sdlc-checkout` direct-edit mode, entered
deliberately and announced — never as a shortcut around a failed ship.

A quality-gate failure is not a false alarm to route around: read
`docs/REVIEW.md` for what the score means, then dispatch the fix it implies.

## Once it's pushed

Do not merge yet — hand off to [`sdlc-review`](../sdlc-review/SKILL.md).
Green `cli ship` is a necessary gate, not the review; tests-passing doesn't
self-approve a merge (`docs/REVIEW.md`).

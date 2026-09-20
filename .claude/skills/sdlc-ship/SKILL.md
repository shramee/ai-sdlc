---
name: sdlc-ship
description: Validate and ship a dispatched branch with `cli ship` — tests, the quality gate, then push and open a PR. Use when a spec's work looks complete and needs to become a reviewable PR.
---

# Ship

```bash
cli ship agent/<slug>
```

Runs on the host, needs `gh` auth. Checks out the branch, runs the repo's
`test_cmd_for` command, then the quality gate (`quality/grade.sh` against
`quality/thresholds.conf`) — only pushes and opens/updates a PR if **both**
are green. First ship opens the PR; later ships push onto it (`pr create`
returning "already exists" is the normal resume path, not an error).

## If it fails

**Do not fix it yourself, even a one-line fix.** The orchestrating session
orchestrates; it doesn't patch code — the one sanctioned exception is
explicit `cli checkout` direct-editing mode (see
[`sdlc-checkout`](../sdlc-checkout/SKILL.md)), entered deliberately, not as a
shortcut around a failed ship. Re-dispatch on the same branch instead, with
the failure output as the prompt — see
[`sdlc-dispatch`](../sdlc-dispatch/SKILL.md)'s "resuming a branch" section.

A quality-gate failure is not a false alarm to route around: read
`docs/REVIEW.md` for what the score means, then dispatch the fix it implies
(usually: reuse the thing it flagged as duplicated, or break up the
function it flagged as too complex).

## Once it's pushed

A PR now exists. Do not merge it yet — hand off to
[`sdlc-review`](../sdlc-review/SKILL.md). `cli ship` pushing green is a
necessary gate, not the review itself; `docs/REVIEW.md` is explicit that
tests-passing and quality-gate-passing don't self-approve a merge.

---
name: sdlc-review
description: Gate a branch before merge with the reviewer subagent. Use once `ai-sdlc ship` has pushed a branch and opened a PR, before approving or merging it, and again after every remediation dispatch.
---

# Review

The **Deploy**-stage gate (`docs/PLAYBOOK.md`). A green `ai-sdlc ship` means
tests and the quality gate passed — not that the code is right. The
`reviewer` subagent judges; per `docs/REVIEW.md` its verdict never merges
anything — it informs the human code owner who does.

## 1. Gather context

```bash
ai-sdlc review-context <repo> <branch>   # diff, log, tracking issue, PR comments — read-only
ai-sdlc quality <repo> <branch>          # quality/grade.sh's score + findings
```

## 2. Invoke the reviewer subagent

Agent tool, `subagent_type: reviewer`. Hand it: the `review-context` bundle,
the quality output, the spec(s) this branch implements, and — if you have
one — a specific worry as the PRIORITY QUESTION. Don't summarize the diff
for it; let it read the bundle.

## 3. Post the verdict

```bash
gh pr comment <n> -R <slug> --body "$(cat verdict.md)"
```

Post verbatim, gaps *and* what passed — a failures-only review reads as
unbalanced and gets discounted. This comment is the audit trail.

## 4. Remediate

**GAPS FOUND** → hand each blocker/major, as a numbered concrete
instruction, to [`sdlc-dispatch`](../sdlc-dispatch/SKILL.md)'s "remediation
dispatch" flow. Then **re-review** from step 1 — remediations introduce
their own defects; skipping re-review is how findings resurface.

**CLEAN** → ready for a human code owner's approval. Say so plainly, and
that the verdict itself doesn't merge anything.

## 5. Merge (human-gated)

Only after code owner approval:

```bash
gh pr merge <n> -R <slug> --merge --delete-branch   # --merge, not --squash —
                                                      # keeps the per-spec commit trail
```

Then [`sdlc-sync`](../sdlc-sync/SKILL.md) so the next spec branches off the
updated default.

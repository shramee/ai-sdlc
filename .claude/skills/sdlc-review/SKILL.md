---
name: sdlc-review
description: Gate a branch before merge with the reviewer subagent. Use once `cli ship` has pushed a branch and opened a PR, before approving or merging it, and again after every remediation dispatch.
---

# Review

The **Deploy**-stage gate (`docs/PLAYBOOK.md`). A green `cli ship` means
tests and the quality gate passed — it does not mean the code is right. That
judgment is the `reviewer` subagent's job, and per `docs/REVIEW.md` its
verdict never merges anything on its own; it informs the human code owner
who does.

## 1. Gather context

```bash
cli review-context <repo> <branch>   # diff, log, tracking issue, PR comments — read-only
cli quality <repo> <branch>          # quality/grade.sh's score + findings
```

## 2. Invoke the reviewer subagent

Use the Agent tool with `subagent_type: reviewer` (`.claude/agents/reviewer.md`).
Hand it: the `review-context` bundle, the quality output, the spec(s) this
branch implements (`templates/spec.md`), and — if you have one — a specific
worry stated as the PRIORITY QUESTION its own instructions call for. Do not
summarize the diff for it; let it read the actual bundle.

## 3. Post the verdict

```bash
gh pr comment <n> -R <slug> --body "$(cat verdict.md)"
```

Post it verbatim, gaps *and* what passed — a review that only lists failures
reads as unbalanced and gets discounted (`docs/REVIEW.md`). This comment is
the audit trail the playbook asks for: what was asked, what was produced,
what was found.

## 4. Remediate

**GAPS FOUND** → hand each blocker/major, as a numbered concrete
instruction, to [`sdlc-dispatch`](../sdlc-dispatch/SKILL.md)'s "remediation
dispatch" flow. Then **re-review** — go back to step 1. Remediations
introduce their own defects often enough that skipping the re-review is a
known way findings resurface (`.claude/agents/reviewer.md`'s "review the
rest" checklist exists because of exactly this pattern).

**CLEAN** → the branch is ready for a human code owner's approval. Say so
plainly, and say explicitly that the verdict itself doesn't merge anything —
don't let "CLEAN" read as "go ahead and merge."

## 5. Merge (human-gated)

Only after code owner approval:

```bash
gh pr merge <n> -R <slug> --merge --delete-branch   # --merge, not --squash —
                                                      # keeps the per-spec commit trail
```

Then [`sdlc-sync`](../sdlc-sync/SKILL.md) so the next spec branches off the
updated default.

# Review policy

Governs what `.claude/agents/reviewer.md` produces and how `cli ship` /
`cli quality` gate on it. Modeled on the "review in both directions" and
governance-as-code sections of Anthropic's
[AI-native SDLC playbook](https://claude.com/blog/the-ai-native-sdlc-playbook).

## Findings do not merge anything

**A reviewer finding, and a failing quality gate, never approve or block a
PR by themselves.** Branch protection still requires a human code owner's
approval — automation makes that approval *informed*, not replaced.
`cli ship` withholding a push over a failed quality gate is the one
exception: a build-time gate on the unreviewed branch, not a review.

## Severity tiers

Every finding gets one tier, stated explicitly — never "found some issues":

| Tier | Meaning | Example |
|---|---|---|
| **Blocker** | Acceptance criterion unmet, or a correctness/security defect. Must be fixed before merge. | A negative case from the spec isn't enforced; a vacuous test. |
| **Major** | Works, but violates the minimal-code/reuse mandate or the quality gate in a way that will cost the next person real time. | A new helper duplicating an existing one; a function over `HARD_MAX_CCN`. |
| **Minor** | Worth fixing, doesn't block. | A confusing name; a non-yet-costly missed reuse. |

The reviewer's full defect-class list and its quality-gate read live in
`.claude/agents/reviewer.md`.

## Tag-based fixes

Close a finding by re-running `cli dispatch` on the same branch with the
finding as the prompt — not a human hand-edit. Then **re-review**: skipping
it is how findings resurface.

## Findings become guardrails

A mistake caught twice is a process bug, not a worker bug: add a line to
`subagent-instructions.md` (or the repo's own `CLAUDE.md`/`AGENTS.md`)
naming the defect class.

# Review policy

Governs what `.claude/agents/reviewer.md` produces and how `cli ship` /
`cli quality` gate on it. Modeled on the "review in both directions" and
governance-as-code sections of Anthropic's
[AI-native SDLC playbook](https://claude.com/blog/the-ai-native-sdlc-playbook).

## Findings do not merge anything

**A reviewer subagent finding, and a failing quality gate, never approve or
block a PR by themselves.** Branch protection still requires a human code
owner's approval — the automation's job is to make that approval *informed*,
not to replace it. `cli ship` withholding a push over a failed quality gate
is the one exception: that's a build-time gate on the *unreviewed* branch
even reaching a human, not a substitute for review.

## Severity tiers

Every finding from the reviewer subagent gets one of these, and the verdict
states the tier explicitly — not just "found some issues":

| Tier | Meaning | Example |
|---|---|---|
| **Blocker** | Acceptance criterion unmet, or a correctness/security defect. Must be fixed before merge. | A negative case from the spec isn't actually enforced; a vacuous test (see below). |
| **Major** | Works, but violates the minimal-code/reuse mandate or the quality gate in a way that will cost the next person real time. | A new helper that duplicates an existing one; a function over `HARD_MAX_CCN`. |
| **Minor** | Worth fixing, doesn't block. | A name that will confuse a future reader; a missed opportunity for reuse that isn't yet costly. |

## Defect classes the reviewer names explicitly

Reviewers told what to hunt for find far more than reviewers told to "review
carefully" — see `.claude/agents/reviewer.md` for the full list this project
has actually shipped and caught: vacuous tests, weaker-than-spec assertions,
cross-language parity claims nothing validates, hand-edited measured numbers,
scope leakage, green-on-stale-fixture tests.

## Tag-based fixes

A PR comment addressed to the dispatched worker (mention its branch/spec, or
literally say "dispatch a fix for this") is the expected way to close a
finding — not a human hand-editing the diff. Re-run `cli dispatch` on the
same branch with the finding as the prompt, then re-review: remediations
introduce their own defects often enough that skipping the re-review is a
known way findings resurface.

## Findings become guardrails

A mistake the reviewer catches twice is a process bug, not a worker bug. When
that happens, add a line to `subagent-instructions.md` (or the repo's own
`CLAUDE.md`/`AGENTS.md`) naming the defect class — the playbook's "findings
feed back into institutional knowledge" loop. `dispatch-preamble`-style
"lessons that cost earlier work several remediation rounds" sections exist
because of exactly this.

## The quality gate is evidence, not the verdict

`quality/grade.sh`'s A-F score and hard-blocker list are inputs the reviewer
subagent reads alongside the diff — a clean grade doesn't mean the code is
right, and a middling one on code that's genuinely hard to simplify further
isn't automatically a blocker. The reviewer says which; the score just makes
sure the conversation starts from measured numbers instead of a vibe.

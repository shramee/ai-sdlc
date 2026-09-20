# Spec: <short name>

The body of a GitHub issue **and** the `cli dispatch` prompt **and** the
thing the reviewer subagent checks the diff against. Write it once, well —
length is not the goal, precision is. A spec that says exactly what "done"
means and how to prove it beats a long one that gestures. Derived from an
`templates/intent.md`; link it.

## Current state

What exists today, with **file:line** references. Quote the offending code
if short. Whoever dispatches this should not have to hunt for what you're
describing.

## Target

The intended end state. If there's a formula, write it out. If a convention
is involved, state it explicitly rather than leaving it to be inferred.

## Decisions already made — do not re-open

Anything a human has already ruled on. Say it's settled, or the dispatched
worker will relitigate it and may implement the alternative.

## The design decision this spec owns   [only if there is one]

What's left open, the constraints a solution must respect, and two or three
options worth weighing. Require a short rationale in the final report if
this gets decided during the work.

## Tasks

- [ ] Concrete, checkable steps.
- [ ] Name existing helpers to reuse, with paths — the whole point of
      `subagent-instructions.md`'s reuse-first mandate is that this section
      makes reuse the path of least resistance, not an afterthought.

## Acceptance criteria

- [ ] Properties, not activities. "A request over the rate limit is
      rejected" — not "add a test for rate limiting".
- [ ] For each, the **negative** case too: what must FAIL. A criterion with
      no failing counterpart is usually satisfiable by deleting the check.

## Do not

Scope fences. What belongs to another spec, and which one. Workers
helpfully overreach into adjacent work if not told not to.

## Gates

The exact commands that must pass — mirrors `test_cmd_for` in `sdlc.conf`
for this repo, plus the quality gate (`quality/thresholds.conf`).

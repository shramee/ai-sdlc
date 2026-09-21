# Spec: <short name>

The GitHub-issue body, the `cli dispatch` prompt, and what the reviewer
subagent checks the diff against. Derived from `templates/intent.md`; link
it. Precision beats length.

## Current state

What exists today, with **file:line** references; quote short offending code.

## Target

The intended end state. Formulas written out; conventions stated explicitly.

## Decisions already made — do not re-open

Anything a human has ruled on. Say it's settled, or the worker relitigates
it and may implement the alternative.

## The design decision this spec owns   [only if there is one]

What's left open, the constraints, and two or three options. Require a
rationale in the final report if decided during the work.

## Tasks

- [ ] Concrete, checkable steps.
- [ ] Name existing helpers to reuse, with paths (reuse-first —
      `subagent-instructions.md`).

## Acceptance criteria

- [ ] Properties, not activities — "a request over the rate limit is
      rejected", not "add a test for rate limiting".
- [ ] The **negative** case for each: what must FAIL. A criterion with no
      failing counterpart is usually satisfiable by deleting the check.

## Do not

Scope fences: what belongs to another spec, and which one.

## Gates

Exact commands that must pass — `test_cmd_for` from `sdlc.conf` for this
repo, plus the quality gate (`quality/thresholds.conf`).

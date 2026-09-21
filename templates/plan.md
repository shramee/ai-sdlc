# Plan: <branch/spec name>

The **Build**-stage artifact (`docs/PLAYBOOK.md`), written *before*
implementation by the dispatched worker (or `checkout` direct-edit session)
reading `templates/spec.md`. If plan and diff disagree, the diff wins — and
the disagreement goes in the final report.

## Understanding

What the spec is actually asking for, in your own words.

## Approach

The sequence of changes, in order, each naming its file(s). Flag reuse
(name it) versus new code (justify it) — the reviewer checks this against
the diff.

## Risks

What could make this wrong in ways tests won't catch (the "passing test is
not evidence" class), and the mutation check planned for each risky piece.

## Open questions

Ambiguities that materially change the approach. Answer before writing code
if possible; otherwise flag loudly in the final report.

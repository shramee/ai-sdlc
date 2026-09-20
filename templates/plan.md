# Plan: <branch/spec name>

The **Build**-stage artifact the playbook asks for: written *before*
implementation, by the dispatched worker (or the orchestrating session, in
`checkout` direct-editing mode) reading `templates/spec.md`, not after the
fact as documentation. If a plan and the eventual diff disagree, the diff
wins but the disagreement itself is worth a line in the final report — it
usually means the spec was wrong, not the plan.

## Understanding

What the spec is actually asking for, in the worker's own words. Surfaces
misreadings before they become wasted turns.

## Approach

The sequence of changes, in the order they'll be made, each one naming the
file(s) it touches. Flag anywhere this reuses existing code (name it) versus
adds new code (justify it) — the reviewer subagent checks this against the
diff.

## Risks

What could make this wrong in a way tests won't catch — the "passing test
is not evidence" class of failure from `subagent-instructions.md`. Name the
specific mutation check planned for each risky piece.

## Open questions

Anything the spec left ambiguous that materially changes the approach.
Answer these *before* writing code if possible; if not, flag them loudly in
the final report rather than silently picking one.

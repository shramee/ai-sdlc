---
name: sdlc-intent
description: Capture a raw ask as intent.md and split it into one or more spec.md files before any dispatch happens. Use when starting new work from a backlog item, bug report, or stakeholder ask that hasn't been broken into dispatchable specs yet.
---

# Intent capture

The **Plan** and **Design** stages (`docs/PLAYBOOK.md`). Nothing gets
dispatched from an idea that hasn't been written down and split.

## 1. Write the intent

Copy `templates/intent.md`, fill it in from what the originator actually
said — don't paraphrase upward. A section you can't fill in means a
stakeholder must answer something first; don't guess.

## 2. Resolve decision gates before writing a single spec

Batch every human-only question ("is this deprecation confirmed?", "which
of two architectures?") into one round of answers — a worker that hits an
unresolved product question stalls or guesses. Put each answer *into the
spec* as "decided, do not re-open".

## 3. Split into specs

One `templates/spec.md` per independently dispatchable unit, each mapped to
exactly one repo (`sdlc.conf`'s `REPOS`). Write them all before dispatching
the first — it surfaces dependency order and duplicate work up front.

**Sequence by file overlap, not backlog order.** Two specs can run in
parallel only if they touch disjoint files; otherwise note the required
order in each spec's "Decisions already made" section.

## 4. File them

One GitHub issue per spec, body = the spec verbatim — or let `cli dispatch`
create it automatically on first dispatch (label `status:dispatched`).
Either is fine; do the split in step 3 regardless.

## Next

Hand each spec to [`sdlc-dispatch`](../sdlc-dispatch/SKILL.md).

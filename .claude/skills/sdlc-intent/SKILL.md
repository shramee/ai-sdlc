---
name: sdlc-intent
description: Capture a raw ask as intent.md and split it into one or more spec.md files before any dispatch happens. Use when starting new work from a backlog item, bug report, or stakeholder ask that hasn't been broken into dispatchable specs yet.
---

# Intent capture

The **Plan** and **Design** stages (`docs/PLAYBOOK.md`). Nothing gets
dispatched from an idea that hasn't been written down and split — that's
where scope creep and re-litigated decisions come from.

## 1. Write the intent

Copy `templates/intent.md`, fill it in from what the originator actually
said — don't paraphrase upward into something more ambitious than they
asked for. If a section can't be filled in, that's the sign a stakeholder
needs to answer something before this proceeds, not a gap to guess through.

## 2. Resolve decision gates before writing a single spec

Scan for questions only a human can answer — "is this deprecation
confirmed?", "which of two architectures?", "is this convention
intentional or a bug?" — and batch them into one round of questions. A
dispatched worker that hits an unresolved product question mid-task either
stalls or guesses, and a wrong guess costs a full remediation cycle later.
Put every answer *into the eventual spec* as "decided, do not re-open" —
specs get relitigated by workers when a decision only looks settled.

## 3. Split into specs

One `templates/spec.md` per independently dispatchable unit of work, each
mapped to exactly one repo (see `sdlc.conf`'s `REPOS`). Write them all
before dispatching the first — doing so surfaces dependency order and
duplicate work up front, which is cheaper to catch here than after two
workers have both touched the same lines.

**Sequence by file overlap, not by backlog order.** Two specs can dispatch
in parallel only if they touch disjoint files; if both would edit the same
file, note the required order in each spec's "Decisions already made"
section — a merge conflict between two dispatched branches costs more than
the parallelism saved.

## 4. File them

One GitHub issue per spec, titled clearly, body = the spec verbatim.
`cli dispatch` creates/tracks this automatically on first dispatch (label
`status:dispatched`) if you'd rather skip filing by hand — either is fine,
but do the split in step 3 regardless.

## Next

Hand each spec to [`sdlc-dispatch`](../sdlc-dispatch/SKILL.md).

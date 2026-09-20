---
name: sdlc-dispatch
description: Turn a spec.md into a running opencode worker via `cli dispatch`. Use when a spec is ready to be worked, when resuming an interrupted dispatch, or when re-dispatching after a failed ship or a review finding.
---

# Dispatch

Runs the actual coding: `opencode` inside an `ag-sbx` sandbox, on a host git
worktree scoped to one branch. This skill is what decides *what to send it*;
`cli dispatch` (see `cli`'s own header comment) is pure mechanics underneath
it and adds `subagent-instructions.md` to every prompt automatically — don't
re-paste that file's contents into the prompt yourself.

```bash
cli dispatch <repo> agent/<slug> "$(cat spec.md)

## Branch context
<what's already landed on this branch, if resuming — see below>"
```

## First dispatch on a branch

The prompt is the spec, verbatim, from [`sdlc-intent`](../sdlc-intent/SKILL.md).
Nothing extra needed — `cli` appends `subagent-instructions.md` (reuse-first
mandate, commit discipline, "a passing test is not evidence") for you.

## Resuming a branch (multiple specs, or a remediation)

Prepend a **Branch context** section naming what's already landed and must
not be redone or disturbed — the worktree persists between dispatches, so
each worker needs to know what it's building on:

```markdown
## Branch context

Already landed here — do not disturb, do not redo:
- <commit/spec> — <what it established, and any API/value a later spec needs>

<Known-stale areas and their tracking issue, if any: "do not fix that here.">
```

Check `cli status` first for the ahead-count and whether a container is
still live for this branch.

## Resuming an *interrupted* run

The worktree persists, so uncommitted work is usually still there. Check
before re-dispatching:

```bash
git -C <repo> log --oneline origin/<default>..agent/<slug>   # what committed
docker exec <container-shown-by-cli-status> git status --short  # what's uncommitted
tail -5 .sdlc/logs/<repo>-agent-<slug>.log                       # where it stopped
```

If there's uncommitted work, tell the next dispatch it's there and instruct
it to commit a WIP checkpoint first, then treat that work as a draft to
review rather than trust — not a finished answer.

## Batching

Two or three specs in one dispatch is fine when they're genuinely coupled —
one reuses a mechanism the other establishes. State the order and require a
separate commit per spec. Don't batch specs that merely happen to be
adjacent: a failure loses all of them, and the review trail loses its
per-spec granularity.

## Remediation dispatch (after a review)

Each blocker/major from [`sdlc-review`](../sdlc-review/SKILL.md) becomes a
numbered, concrete instruction in the prompt — not a paraphrase of the
finding. Require a mutation check per fix (break it, confirm the fix's own
test catches it, revert, confirm it passes again).

## Next

Once the spec's tasks look complete, hand off to
[`sdlc-ship`](../sdlc-ship/SKILL.md).

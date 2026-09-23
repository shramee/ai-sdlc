---
name: sdlc-dispatch
description: Turn a spec.md into a running opencode worker via `ai-sdlc dispatch`. Use when a spec is ready to be worked, when resuming an interrupted dispatch, or when re-dispatching after a failed ship or a review finding.
---

# Dispatch

```bash
ai-sdlc dispatch <repo> agent/<slug> "$(cat spec.md)

## Branch context
<see below if resuming>"
```

`ai-sdlc` appends `subagent-instructions.md` (worker behavior: reuse, commits,
mutation checks, logging) to every prompt — don't re-paste it.

## First dispatch on a branch

The prompt is the spec, verbatim, from [`sdlc-intent`](../sdlc-intent/SKILL.md). Nothing extra needed.

## Resuming a branch (multiple specs, or a remediation)

Prepend a **Branch context** section — the worktree persists between
dispatches, so each worker must know what it's building on. Check `ai-sdlc
status` first for the ahead-count and live containers.

```markdown
## Branch context

Already landed here — do not disturb, do not redo:
- <commit/spec> — <what it established, and any API/value a later spec needs>

<Known-stale areas and their tracking issue, if any: "do not fix that here.">
```

## Resuming an *interrupted* run

```bash
git -C <repo> log --oneline origin/<default>..agent/<slug>   # what committed
docker exec <container-shown-by-ai-sdlc-status> git status --short  # what's uncommitted
tail -5 .sdlc/logs/<repo>-agent-<slug>.log                       # where it stopped
```

If there's uncommitted work, instruct the next dispatch to commit a WIP
checkpoint first, then treat that work as a draft to review, not a finished
answer.

## Batching

Two or three specs in one dispatch only when genuinely coupled — one reuses
a mechanism the other establishes. State the order, require a separate
commit per spec. Don't batch specs that merely happen to be adjacent: a
failure loses all of them, and the review trail loses per-spec granularity.

## Remediation dispatch (after a review)

Each blocker/major from [`sdlc-review`](../sdlc-review/SKILL.md) becomes a
numbered, concrete instruction in the prompt — not a paraphrase. Require a
mutation check per fix.

## Next

Once the spec's tasks look complete, hand off to
[`sdlc-ship`](../sdlc-ship/SKILL.md).

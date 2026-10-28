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

Exit status is the verdict: non-zero when the worker failed, timed out
(`DISPATCH_TIMEOUT`, exit 124), made no commits, or left uncommitted/untracked
files — the worktree is kept, so resume on the same branch. It also refuses
when another worker holds the branch's worktree (one worker per worktree) or
when the branch's PR already merged at its tip (use a new branch).

## First dispatch on a branch

The prompt is the spec, verbatim, from [`sdlc-intent`](../sdlc-intent/SKILL.md). Nothing extra needed.

## Resuming a branch (multiple specs, or a remediation)

Prepend a **Branch context** section — the worktree persists between
dispatches, so each worker must know what it's building on. Check `ai-sdlc
status` first for ahead/behind counts and running workers. A resumed branch is
never rebased; if it's behind and the work needs newer default-branch code,
say so in the prompt. The re-dispatch continues the branch's previous
opencode session unless you pass `--session`/`--continue` yourself or set
`DISPATCH_RESUME_SESSION=0`.

```markdown
## Branch context

Already landed here — do not disturb, do not redo:
- <commit/spec> — <what it established, and any API/value a later spec needs>

<Known-stale areas and their tracking issue, if any: "do not fix that here.">
```

## Resuming an *interrupted* run

Paths live under `STATE_DIR` (`ai-sdlc config` prints the resolved `logs` and
`worktrees` dirs; default `<project>/.sdlc`):

```bash
git -C <repo> log --oneline origin/<default>..agent/<slug>     # what committed
git -C <worktrees>/<repo>/agent-<slug> status --short          # what's uncommitted
tail -5 <logs>/<repo>-agent-<slug>.log                         # where it stopped
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

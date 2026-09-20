---
name: sdlc-status
description: Read-only fleet view via `cli status`. Use to check what's in flight before picking up more work, to answer "what's dispatched right now", or before re-dispatching to see whether a branch's container is still live.
---

# Status

```bash
cli status
```

Per repo: current host branch, dirty file count, every `agent/*` branch with
its commit count ahead of default, and — for any branch with a live host
worktree — whether its `ag-sbx` container is still running. Then open PRs.

Run this first when picking up work of any kind; it's the cheapest way to
avoid dispatching a duplicate of something already in flight, or re-creating
a worktree for a branch that's mid-run in another window.

## Reading it

- **Ahead-count > 0, no open PR** → ready for
  [`sdlc-ship`](../sdlc-ship/SKILL.md), or still being worked.
- **Container marked running** → a dispatch or `vibe` session may still be
  active there; check before starting a fresh one against the same branch.
- **Open PR listed** → belongs to [`sdlc-review`](../sdlc-review/SKILL.md)
  unless it's already been reviewed and is just waiting on a human merge.

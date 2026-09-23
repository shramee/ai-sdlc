---
name: sdlc-status
description: Read-only fleet view via `ai-sdlc status`. Use to check what's in flight before picking up more work, to answer "what's dispatched right now", or before re-dispatching to see whether a branch's container is still live.
---

# Status

```bash
ai-sdlc status
```

Per repo: current branch, dirty files, every `agent/*` branch with its
ahead-count, live `ag-sbx` containers, open PRs. Run first when picking up
work — cheapest way to avoid duplicating something in flight.

## Reading it

- **Ahead-count > 0, no open PR** → ready for
  [`sdlc-ship`](../sdlc-ship/SKILL.md), or still being worked.
- **Container running** → a dispatch or `vibe` session may be active; check
  before starting a fresh one on the same branch.
- **Open PR listed** → belongs to [`sdlc-review`](../sdlc-review/SKILL.md)
  unless already reviewed and waiting on a human merge.

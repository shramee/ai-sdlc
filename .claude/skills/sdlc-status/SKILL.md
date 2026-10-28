---
name: sdlc-status
description: Read-only fleet view via `ai-sdlc status`. Use to check what's in flight before picking up more work, to answer "what's dispatched right now", or before re-dispatching to see whether a branch's worker is still running.
---

# Status

```bash
ai-sdlc status
```

Per repo: current branch, dirty files, every branch under
`AGENT_BRANCH_PREFIX` or held by a dispatch worktree with its ahead/behind
counts, running workers (from the worktree lock), open PRs. Run first when
picking up work — cheapest way to avoid duplicating something in flight.
`ai-sdlc doctor` is the deeper check: missing tools, gh auth, CI vs
`test_cmd_for` drift, stale locks, orphan worktrees, old logs.

## Reading it

- **Ahead-count > 0, no open PR** → ready for
  [`sdlc-ship`](../sdlc-ship/SKILL.md), or still being worked.
- **Behind > 0** → the branch was cut from an older default; a resume
  dispatch won't rebase it on its own.
- **Worker running** → a dispatch holds the worktree; a second dispatch,
  `ship` or `vibe` on that branch is refused until it exits.
- **Open PR listed** → belongs to [`sdlc-review`](../sdlc-review/SKILL.md)
  unless already reviewed and waiting on a human merge.

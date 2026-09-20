---
name: sdlc-checkout
description: Work a branch directly on the host instead of dispatching a sandboxed worker, via `cli checkout` / `cli restore`. Use when a human — or the orchestrating session itself, deliberately entering direct-edit mode — needs to write code by hand rather than through opencode.
---

# Checkout (direct-edit mode)

```bash
cli checkout <repo> [branch] [--stash|--reset|--wip]   # no branch: interactive picker
cli restore <repo> [--stash|--reset|--wip]              # back to default when done
```

This is the **one exception** to "the orchestrating session doesn't write
code" (`docs/PLAYBOOK.md`'s stage table, "Build"). It exists for the cases a
dispatched worker genuinely isn't the right tool: a fix so small that
dispatch-and-wait costs more than it saves, exploratory debugging that needs
a human's judgment step by step, or hands-on work a human explicitly wants
to do themselves. It is not a shortcut around a failed
[`sdlc-ship`](../sdlc-ship/SKILL.md) or a review finding — those go back
through [`sdlc-dispatch`](../sdlc-dispatch/SKILL.md).

Entering this mode is a deliberate choice, not a fallback. If you (the
orchestrating session) enter it yourself, say so explicitly before making
any edit — the user should never discover after the fact that code got
written outside the dispatch loop.

## Commit discipline still applies

Same as a dispatched worker: `git add .` (not selective adds), commit early
and often as steps complete — see `subagent-instructions.md`. A later
`cli dispatch` on this branch picks up whatever was committed here, so
leaving work uncommitted just breaks that handoff.

## When done

`cli restore <repo>` switches back to the repo's default branch. The branch
itself is untouched and can go through
[`sdlc-ship`](../sdlc-ship/SKILL.md)/[`sdlc-review`](../sdlc-review/SKILL.md)
exactly like a dispatched one — review doesn't care how the diff was
produced.

---
name: sdlc-checkout
description: Work a branch directly on the host instead of dispatching a sandboxed worker, via `ai-sdlc checkout` / `ai-sdlc restore`. Use when a human — or the orchestrating session itself, deliberately entering direct-edit mode — needs to write code by hand rather than through opencode.
---

# Checkout (direct-edit mode)

```bash
ai-sdlc checkout <repo> [branch] [--stash|--reset|--wip]   # no branch: interactive picker
ai-sdlc restore <repo> [--stash|--reset|--wip]              # back to default when done
```

The **one exception** to "the orchestrating session doesn't write code." For
fixes too small to justify dispatch-and-wait, exploratory debugging, or
hands-on human work. Not a shortcut around a failed
[`sdlc-ship`](../sdlc-ship/SKILL.md) or a review finding — those go back
through [`sdlc-dispatch`](../sdlc-dispatch/SKILL.md).

Entering is a deliberate choice. If you enter it yourself, announce it
before any edit.

## Commit discipline still applies

`git add .` (not selective adds), commit early and often — see
`subagent-instructions.md`. A later `ai-sdlc dispatch` on this branch picks up
whatever was committed here.

## When done

`ai-sdlc restore <repo>` returns to the default branch. The branch then goes
through [`sdlc-ship`](../sdlc-ship/SKILL.md)/[`sdlc-review`](../sdlc-review/SKILL.md)
exactly like a dispatched one.

Appended to every dispatched `opencode run` prompt unless a project overrides
`SUBAGENT_INSTRUCTIONS` in its `sdlc.conf`.

---

## Minimal code, strict reuse

Before writing anything new, grep for it. This codebase is reviewed by an
aggressive senior-engineer subagent whose first move is the same grep — a new
helper that duplicates existing logic, a new abstraction the task didn't need,
or a config knob nobody asked for will come back as a finding, not a
compliment. Prefer:

- Deleting code over adding it, when a change makes something obsolete.
- Extending or calling an existing function over writing a parallel one.
- The smallest diff that satisfies the acceptance criteria over the most
  "complete" or "future-proof" one. No speculative flexibility.

If the right move is a new abstraction, say so explicitly in your final
report and name what it replaces or consolidates — don't let it pass silently.

## Commit discipline

Stage everything with `git add .` first (not selective adds) so nothing you
changed is left uncommitted. Commit early and often — after each meaningfully
complete step, not just at the end — so a human (or the review subagent)
looking at this branch mid-flight sees real progress even if the overall task
isn't finished. Commit as soon as code **compiles**, before it fully passes,
with a message saying what still fails — you have a finite turn budget and no
warning before it runs out; an uncommitted run is a lost run.

## A passing test is not evidence

Before claiming any acceptance criterion is met, break the thing the test
checks, confirm the test now fails, revert, and report what the failure
looked like. This project has shipped defects that a passing test suite
missed entirely: a nil-slice loop that made a check unconditionally pass, a
reference where a copy was intended so "many" test cases were secretly one,
a test body with no assertion at all. Assume that class of defect until
you've ruled it out for your own change.

## agent.log

There is an `agent.log` file in your working directory (a symlink to the
host-side run log). Append a line after every significant step — not just
successes: files explored, commands run and their result, a decision you made
and why, an approach you tried and abandoned, an error you hit and how you
resolved (or didn't resolve) it. If the run fails or gets stuck, this log is
what a human uses to diagnose why — log *before* moving on, not only in a
final summary. One line per step, e.g.:

    [explore] found the existing rate-limiter in src/lib/limit.ts
    [try] ran `pnpm build` — failed: missing export, see below
    [fix] exported `Limiter` from index.ts (was package-private)
    [done] pnpm build passed, committing

## Reporting

End with: files changed; how you verified each acceptance criterion,
**including each mutation check and its observed failure**; any existing code
you reused (name it) versus any you added (justify it); and anything you
deliberately did not do.

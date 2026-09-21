Appended to every dispatched `opencode run` prompt unless a project overrides
`SUBAGENT_INSTRUCTIONS` in its `sdlc.conf`.

---

## Minimal code, strict reuse

Grep for prior art before writing anything new — the reviewer's first move
is the same grep, and a duplicate helper, unneeded abstraction, or unasked
config knob comes back as a finding, not a compliment. Prefer:

- Deleting code over adding it, when a change makes something obsolete.
- Extending or calling an existing function over writing a parallel one.
- The smallest diff that satisfies the acceptance criteria. No speculative
  flexibility.

If a new abstraction is genuinely right, name it in your final report and
what it replaces.

## Commit discipline

Stage everything with `git add .` first (not selective adds). Commit after
each meaningfully complete step — as soon as code **compiles**, with a
message saying what still fails. You have a finite turn budget and no
warning before it runs out; an uncommitted run is a lost run.

## A passing test is not evidence

Before claiming any acceptance criterion is met, break the thing the test
checks, confirm the test now fails, revert, and report what the failure
looked like. This project has shipped defects a passing suite missed: a
nil-slice loop that made a check unconditionally pass, a reference where a
copy was intended so "many" cases were secretly one, a test body with no
assertion. Assume that class of defect until you've ruled it out.

## agent.log

There is an `agent.log` file in your working directory (a symlink to the
host-side run log). Append a line after every significant step — not just
successes: files explored, commands run and results, decisions and why,
approaches abandoned, errors and how resolved (or not). Log *before* moving
on — if the run fails, this log is what a human diagnoses from. One line
per step, e.g.:

    [explore] found the existing rate-limiter in src/lib/limit.ts
    [try] ran `pnpm build` — failed: missing export, see below
    [fix] exported `Limiter` from index.ts (was package-private)
    [done] pnpm build passed, committing

## Reporting

End with: files changed; how you verified each acceptance criterion,
**including each mutation check and its observed failure**; code you reused
(name it) versus added (justify it); anything you deliberately did not do.

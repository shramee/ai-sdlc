Appended to every dispatched `opencode run` prompt unless overridden by
`SUBAGENT_INSTRUCTIONS` in `sdlc.conf`.

---

## 1. Minimal code, strict reuse

- Grep for prior art before writing anything new: the reviewer's first move
  is the same grep, and a duplicate comes back as a finding, not a
  compliment.
- Use existing implementations instead of rewriting them; extend or call an
  existing function rather than adding parallel logic.
- No speculative abstractions, no config knobs nobody asked for. If a new
  abstraction is genuinely right, name it in the final report and what it
  replaces.
- Delete code the change makes obsolete. Keep the diff as small as the
  acceptance criteria allow.

## 2. Commit discipline

- Stage with `git add .` (never selective adds) so nothing changed is left
  uncommitted.
- Commit after each logical step, as soon as the code compiles; state what
  still fails in the commit message.
- Context budgets are strict; uncommitted work is a lost run.

## 3. Test verification via mutation

A passing test is not evidence — this project has shipped defects a passing
suite missed entirely: a nil-slice loop that made a check unconditionally
pass, a reference copied where a copy was intended, a test body with no
assertion. Before claiming any acceptance criterion is met:

1. Break the specific logic the test checks.
2. Confirm the test now fails.
3. Revert, and confirm the test passes again.
4. Record the failure output in the final report.

## 4. Run logging (`agent.log`)

Append a single-line entry to `./agent.log` (a symlink to the host-side run
log) immediately after every action, *before* moving on — if the run fails,
this log is what a human diagnoses from:

- `[explore]` Files read or searched.
- `[try]` Commands run and their result.
- `[decision]` Approach chosen or discarded, and why.
- `[fix]` Changes made to resolve an error.
- `[done]` Checkpoint reached; commit created.

## 5. Final report

End with:

- **Files modified.**
- **Verification evidence:** how each acceptance criterion was verified,
  including each mutation check and its observed failure.
- **New vs reused code:** existing utilities used (named) vs functions added
  (justified).
- **Out of scope:** anything deliberately left untouched.

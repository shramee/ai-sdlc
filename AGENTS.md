# ai-sdlc

Skills/subagents config for an agentic SDLC: a main agent (Claude Code)
orchestrates, and code gets written by `opencode` workers running inside
[agent-sandbox](https://github.com/shramee/agent-sandbox) containers. See
`README.md` for the full picture and `docs/PLAYBOOK.md` for how this maps to
the [AI-native SDLC playbook](https://claude.com/blog/the-ai-native-sdlc-playbook).

## The three layers

* **`cli`** — mechanics only: git worktrees, `ag-sbx`/`docker` calls, `gh`
  bookkeeping, the quality gate. No judgment about what to dispatch or
  whether work is good.
* **`.claude/skills/sdlc-*`** — the runbook. Load the one matching what
  you're doing rather than improvising the workflow from scratch.
* **`.claude/agents/reviewer.md`** — the judgment about code, gating every
  merge. Read-only, host-side, adversarial by design.

## What to do, when

Work through the skills in this order for a fresh piece of work; jump to
whichever stage you're actually at when resuming:

1. [`sdlc-intent`](.claude/skills/sdlc-intent/SKILL.md) — turn an ask into
   `templates/intent.md`, then split it into `templates/spec.md` files.
2. [`sdlc-dispatch`](.claude/skills/sdlc-dispatch/SKILL.md) — run a spec
   through `cli dispatch`.
3. [`sdlc-ship`](.claude/skills/sdlc-ship/SKILL.md) — `cli ship`: tests +
   quality gate, then push and open a PR.
4. [`sdlc-review`](.claude/skills/sdlc-review/SKILL.md) — the `reviewer`
   subagent gates the merge; remediate through `sdlc-dispatch` and re-review.
5. [`sdlc-sync`](.claude/skills/sdlc-sync/SKILL.md) — after a human merges,
   pull the default branch forward.

Anytime: [`sdlc-status`](.claude/skills/sdlc-status/SKILL.md) (read-only
fleet view — run it before picking up new work) and
[`sdlc-checkout`](.claude/skills/sdlc-checkout/SKILL.md) (the one sanctioned
exception for writing code directly instead of dispatching).

## Division of labor

- **`opencode` workers** (via `cli dispatch`) write and commit code. They
  never push and never open PRs — no GitHub credentials reach the sandbox.
- **The reviewer subagent** judges code. It never writes to git state (see
  its own file for why) and its verdict never merges anything by itself.
- **The orchestrating session** (you) drives the skills above — branching,
  validating, shipping, syncing — but does not write or commit code fixes
  itself, even small ones a failed `cli ship` surfaces. Hand those to
  `sdlc-dispatch` on the same branch. The one exception is
  `sdlc-checkout` direct-edit mode, entered deliberately and announced.
- **A human code owner** approves the PR. Nothing in this repo merges a PR
  without that — see `docs/REVIEW.md`.

## Working on this repo itself

- `bash -n cli` after every edit to the mechanics layer; `cli config` in a
  real consuming project is the cheapest end-to-end smoke test.
- Nothing project-specific belongs in `cli` — it all comes from `sdlc.conf`
  with a sane default. A change that needs a project-specific branch needs
  a new config knob instead.
- `quality/grade.sh . "" quality/thresholds.conf` should stay green here —
  this repo eats its own quality gate.

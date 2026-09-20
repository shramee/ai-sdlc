# Where this repo sits in the AI-native SDLC

Anthropic's [AI-native SDLC playbook](https://claude.com/blog/the-ai-native-sdlc-playbook)
frames development as a loop of six stages, each one committing a versioned
artifact the next stage reads. This table is the map from that loop onto
what actually exists in this repo — read it before adding a new skill or
agent, so new work lands in the stage it belongs to instead of duplicating
what another skill already owns.

| Stage | Playbook artifact | This repo | Human gate |
|---|---|---|---|
| **Plan** | `intent.md` | `templates/intent.md`, captured via the `sdlc-intent` skill | Product/issue owner accepts or rejects the intent |
| **Design** | requirements + design in one pass | `templates/spec.md` (one per dispatchable unit of work) | Spec owner sign-off on any open design decision the spec calls out |
| **Build** | `plan.md` before code, `CLAUDE.md`/`AGENTS.md` for institutional knowledge | `templates/plan.md`, written by the dispatched worker before it edits; `subagent-instructions.md` as the standing knowledge base | Orchestrating session reviews the plan before `cli dispatch` proceeds past it (for anything non-trivial) |
| **Test** | agents verify their own work before a human sees it | `subagent-instructions.md`'s "a passing test is not evidence" mutation-check requirement; `test_cmd_for` in `sdlc.conf` | None — this stage exists specifically so the human gate downstream isn't spent on catchable defects |
| **Deploy** | multi-layered agentic + human review; governance as code | `.claude/agents/reviewer.md` + `quality/grade.sh` gate, policy in `docs/REVIEW.md`; `cli ship` as the mechanical push/PR gate | Code owner approval on the PR — see `docs/REVIEW.md`: findings never self-approve |
| **Maintain** | monitoring triggers new work back into `intent.md` | Not yet built — see "Gaps" below | Service/on-call owner triages, then re-enters at Plan |

## Skills vs. agents vs. the `cli`

The playbook's "artifact-based handoff" idea is why this repo splits into
three layers rather than one bash tool:

- **`cli`** — mechanics with no judgment: git worktrees, `ag-sbx`/`docker`
  calls, `gh` issue/PR bookkeeping, the quality-gate runner. It does not
  decide what to dispatch or whether work is good.
- **`.claude/skills/*`** — the runbook a Claude Code "main agent" follows:
  when to capture an intent, how to sequence dispatches, what to do when a
  ship fails, how to hand a diff to the reviewer. This is where the judgment
  about *process* lives.
- **`.claude/agents/reviewer.md`** — the judgment about *code*. Runs
  read-only, host-side (it needs `gh` and the repo, and must never enter the
  sandbox — see its own file for why), and never on the critical path of
  dispatch itself.

## Gaps this repo does not close yet

Left out deliberately rather than half-built:

- **Maintain-stage automation.** No incident-triage agent, no production
  monitoring hook. The playbook's `intent.md` re-entry point from production
  still needs a human to open it by hand.
- **Hooks enforcing the sandbox/permission model.** The playbook's
  `failIfUnavailable`/deny-list guidance applies to Claude Code's own
  `settings.json` permission and sandbox system; see `.claude/settings.json`
  in this repo for what's wired up and what's left as a project-specific
  decision (network allowlists especially — those are per-deployment).
- **Continuous evals.** The playbook's "20-50 real tasks, regression-tested
  in CI" idea has no home here yet; it belongs in the consuming project once
  there's a corpus of specs worth replaying.

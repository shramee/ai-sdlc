# Where this repo sits in the AI-native SDLC

Anthropic's [AI-native SDLC playbook](https://claude.com/blog/the-ai-native-sdlc-playbook)
frames development as a loop of six stages, each committing a versioned
artifact the next stage reads. This is the map from that loop onto this
repo — read it before adding a skill or agent, so new work lands in the
stage it belongs to. The three-layer structure (skills / reviewer / `ai-sdlc`)
is described once in `README.md`.

| Stage | Playbook artifact | This repo | Human gate |
|---|---|---|---|
| **Plan** | `intent.md` | `templates/intent.md`, captured via `sdlc-intent` | Product/issue owner accepts or rejects the intent |
| **Design** | requirements + design in one pass | `templates/spec.md` (one per dispatchable unit) | Spec owner sign-off on open design decisions |
| **Build** | `plan.md` before code, `CLAUDE.md`/`AGENTS.md` for institutional knowledge | `templates/plan.md`, written by the worker before editing; `subagent-instructions.md` as standing knowledge | Orchestrating session reviews the plan before dispatch proceeds (non-trivial work) |
| **Test** | agents verify their own work | `subagent-instructions.md`'s mutation check; `test_cmd_for` in `sdlc.conf` | None — so the downstream gate isn't spent on catchable defects |
| **Deploy** | agentic + human review; governance as code | `reviewer.md` + `quality/grade.sh` gate; policy in `docs/REVIEW.md`; `ai-sdlc ship` as mechanical gate | Code owner approval — findings never self-approve |
| **Maintain** | monitoring triggers new work into `intent.md` | Not yet built — see "Gaps" | Service/on-call owner triages, re-enters at Plan |

## Gaps this repo does not close yet

Left out deliberately rather than half-built:

- **Maintain-stage automation.** No incident-triage agent, no production
  monitoring hook; the production → `intent.md` re-entry still needs a human.
- **Hooks enforcing the sandbox/permission model.** Playbook deny-list
  guidance vs Claude Code's `settings.json`: see `.claude/settings.json` for
  what's wired and what's per-deployment (network allowlists especially).
- **Continuous evals.** The "20-50 real tasks, regression-tested in CI" idea
  has no home here; it belongs in the consuming project once there's a
  corpus of specs worth replaying.

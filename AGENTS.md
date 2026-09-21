# ai-sdlc

An agentic SDLC: a main agent (Claude Code) orchestrates, `opencode` workers
in [agent-sandbox](https://github.com/shramee/agent-sandbox) containers write
the code. Full picture: `README.md`; playbook mapping: `docs/PLAYBOOK.md`.

## The three layers

* **`cli`** — mechanics only: worktrees, `ag-sbx`/`docker`, `gh`, the quality
  gate. No judgment.
* **`.claude/skills/sdlc-*`** — the runbook. Load the one matching your stage.
* **`.claude/agents/reviewer.md`** — code judgment, gates every merge.
  Read-only, host-side, adversarial.

## What to do, when

Fresh work follows this order; jump to your stage when resuming:

1. [`sdlc-intent`](.claude/skills/sdlc-intent/SKILL.md) — ask → `intent.md` → `spec.md` files.
2. [`sdlc-dispatch`](.claude/skills/sdlc-dispatch/SKILL.md) — run a spec through `cli dispatch`.
3. [`sdlc-ship`](.claude/skills/sdlc-ship/SKILL.md) — tests + quality gate, push, open PR.
4. [`sdlc-review`](.claude/skills/sdlc-review/SKILL.md) — reviewer subagent gates the merge; remediate via dispatch, re-review.
5. [`sdlc-sync`](.claude/skills/sdlc-sync/SKILL.md) — after a human merges, pull default forward.

Anytime: [`sdlc-status`](.claude/skills/sdlc-status/SKILL.md) (fleet view)
and [`sdlc-checkout`](.claude/skills/sdlc-checkout/SKILL.md) (sanctioned
direct-edit exception).

## Division of labor

* Workers write and commit code; they never push or open PRs (no GitHub
  credentials reach the sandbox).
* The reviewer judges code, never writes git state; its verdict never merges
  anything.
* You (the orchestrating session) drive the skills but never write or commit
  code fixes — re-dispatch instead. Sole exception: `sdlc-checkout`
  direct-edit mode, entered deliberately and announced.
* A human code owner approves every PR — `docs/REVIEW.md`.

## This repo itself

* `bash -n cli` after every `cli` edit; `cli config` in a consuming project
  is the end-to-end smoke test.
* Nothing project-specific in `cli` — everything comes from `sdlc.conf` with
  a default; project-specific needs a new config knob.
* `quality/grade.sh . "" quality/thresholds.conf` stays green here.

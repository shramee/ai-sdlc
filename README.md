# ai-sdlc

An agentic SDLC where a main agent orchestrates and a worker executes:
**Claude Code, driven by skills, dispatches [`opencode`](https://opencode.ai)
workers into per-branch git worktrees on the same machine — no Docker**,
gates every merge with an aggressive read-only reviewer subagent, and grades
code quality with self-hosted tooling instead of a SaaS dashboard.

Repo-agnostic by design — point it at any project via `sdlc.conf` — and
mapped explicitly against
[Anthropic's AI-native SDLC playbook](https://claude.com/blog/the-ai-native-sdlc-playbook):
see `docs/PLAYBOOK.md` for the stage mapping and deliberate gaps.

## The three layers

```
┌─────────────────────────────────────────────────────────┐
│  .claude/skills/sdlc-*/SKILL.md   — the runbook          │
│  (what a main Claude Code agent follows: when to         │
│  capture intent, how to sequence dispatch, what to do    │
│  when ship fails, how to hand a diff to review)           │
├─────────────────────────────────────────────────────────┤
│  .claude/agents/reviewer.md       — the judgment          │
│  (aggressive, read-only, host-side subagent; gates every  │
│  merge; verdict never self-approves — docs/REVIEW.md)     │
├─────────────────────────────────────────────────────────┤
│  ai-sdlc                          — the mechanics          │
│  (git worktrees, gh bookkeeping, opencode runs,            │
│  the quality-gate runner — no judgment, just plumbing)    │
└─────────────────────────────────────────────────────────┘
         │
         ▼
   opencode run --auto ── host git worktree
   (guard/ shims refuse the worker's `git push` and `gh`)
```

A bash tool alone can dispatch and ship, but it can't hold judgment —
"is this spec ready," "does this diff satisfy the criteria," "should this
merge." That judgment lives in skills (process) and a subagent (code), on
top of mechanics that stayed boring on purpose.

## Install

```bash
# 1. This repo
git clone https://github.com/shramee/ai-sdlc ~/.ai-sdlc
ln -s ~/.ai-sdlc/ai-sdlc /usr/local/bin/ai-sdlc

# 2. opencode — the worker
npm install -g opencode-ai && opencode auth login

# 3. the quality tools — `ai-sdlc ship`/`ai-sdlc quality` run them
pip install lizard && npm install -g jscpd
```

Then, in a consuming project:

```bash
cd ~/code/myproject
ai-sdlc init                 # writes sdlc.conf — edit REPOS / test_cmd_for / OPENCODE_MODEL
ai-sdlc config               # check what resolved
ai-sdlc status               # read-only fleet view
```

## Use

Drive it through the skills, not the bash commands directly — they carry the
judgment the mechanics don't have. Start at
[`AGENTS.md`](AGENTS.md#what-to-do-when) for the full sequence:
`sdlc-intent` → `sdlc-dispatch` → `sdlc-ship` → `sdlc-review` → `sdlc-sync`,
with `sdlc-status` and `sdlc-checkout` available any time.

Subcommand reference: the `ai-sdlc` header comment (`ai-sdlc` with no args prints it).

## Isolation without a container

Workers run `opencode run --auto` on the host, from inside a per-branch git
worktree (`git worktree add` — never the default branch). The worker's commit
identity comes from `AGENT_GIT_NAME`/`AGENT_GIT_EMAIL` as per-process env vars,
so the host's git config is untouched. `guard/` is first on the worker's PATH
and refuses `git push` and `gh`, so workers commit locally and the host ships.

That is a guard against accidents, not a sandbox: the worker runs as you, can
read and write anything you can, and `/usr/bin/git push` still works. If you
need real isolation (untrusted prompts or models), run `ai-sdlc` itself inside
a VM or container of your own.

## Quality gate

`quality/grade.sh` runs [lizard](https://github.com/terryyin/lizard)
(per-function complexity, length, parameter count) and
[jscpd](https://github.com/kucherenko/jscpd) (cross-file duplication), rolled
into a 0–10 / A–F score against `quality/thresholds.conf`, with a hard
ceiling on any single function's complexity. No SaaS account; same in CI, in
`ai-sdlc ship`, and inside the reviewer's own review. What the grade means:
`docs/REVIEW.md`.

## Review policy

The reviewer subagent (`.claude/agents/reviewer.md`) is deliberately
adversarial: it hunts duplicated logic, unjustified abstractions,
architecture drift, and defect classes LLM-authored code is prone to. Its
verdict is evidence for a human code owner, never a merge decision —
`docs/REVIEW.md`.

## Layout

```
ai-sdlc                      mechanics: dispatch/ship/sync/status/checkout/quality
subagent-instructions.md     appended to every dispatch prompt
examples/sdlc.conf.example   starter config, copied by `ai-sdlc init`
guard/                       PATH shims that refuse `git push` and `gh` for dispatched workers
quality/                     grade.sh + thresholds.conf — the self-hosted quality gate
templates/                   intent.md / spec.md / plan.md — the Plan→Design→Build artifact chain
docs/                        REVIEW.md (policy) and PLAYBOOK.md (stage mapping, gaps)
.claude/skills/sdlc-*/       the runbook a main Claude Code agent follows
.claude/agents/reviewer.md   the read-only adversarial review subagent
.claude/settings.json        permission allow/deny — secrets denied, read-only loop allowlisted
```

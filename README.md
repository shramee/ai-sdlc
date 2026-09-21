# ai-sdlc

An agentic SDLC where a main agent orchestrates and a sandboxed worker
executes: **Claude Code, driven by skills, dispatches [`opencode`](https://opencode.ai)
workers into [`ag-sbx`](https://github.com/shramee/agent-sandbox) containers**,
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
│  cli                              — the mechanics          │
│  (git worktrees, gh bookkeeping, ag-sbx/docker calls,      │
│  the quality-gate runner — no judgment, just plumbing)    │
└─────────────────────────────────────────────────────────┘
         │
         ▼
   ag-sbx container ── opencode run --auto ── host git worktree
   (shramee/agent-sandbox + docker/Dockerfile's opencode/lizard/jscpd layer)
```

A bash tool alone can dispatch and ship, but it can't hold judgment —
"is this spec ready," "does this diff satisfy the criteria," "should this
merge." That judgment lives in skills (process) and a subagent (code), on
top of mechanics that stayed boring on purpose.

## Install

```bash
# 1. This repo
git clone https://github.com/shramee/ai-sdlc ~/www/ai-sdlc
ln -s ~/www/ai-sdlc/cli /usr/local/bin/ai-sdlc-cli   # or add it to $PATH as `cli`

# 2. agent-sandbox — owns image/container lifecycle, referenced not vendored
git clone https://github.com/shramee/agent-sandbox ~/www/agent-sandbox
~/www/agent-sandbox/install.sh

# 3. opencode, on the host too (cli copies auth.json into each container —
#    docker/README.md)
npm install -g opencode-ai && opencode auth login

# 4. this repo's sandbox layer (opencode + lizard + jscpd on top of
#    agent-sandbox) — see docker/README.md for build/push
docker build -t youorg/ai-sdlc-sandbox:latest -f docker/Dockerfile docker/

# 5. the quality tools, on the HOST too — `cli ship`/`cli quality` run there
pip install lizard && npm install -g jscpd
```

Then, in a consuming project:

```bash
cd ~/code/myproject
cli init                 # writes sdlc.conf — edit REPOS / test_cmd_for / AG_SBX_IMAGE_OVERRIDE
cli config               # check what resolved
cli status               # read-only fleet view
```

## Use

Drive it through the skills, not the bash commands directly — they carry the
judgment the mechanics don't have. Start at
[`AGENTS.md`](AGENTS.md#what-to-do-when) for the full sequence:
`sdlc-intent` → `sdlc-dispatch` → `sdlc-ship` → `sdlc-review` → `sdlc-sync`,
with `sdlc-status` and `sdlc-checkout` available any time.

Subcommand reference: the `cli` header comment (`cli` with no args prints it).

## Why worktrees live on the host

A container mounting the project at one fixed path (e.g. `/workspace`)
forces worktrees to be created *inside* the container — a worktree's `.git`
pointer is an absolute path baked in at creation, so it only resolves from
the side that created it, and host/container contention needs its own
prune/lock machinery.

`ag-sbx` sidesteps this: it mounts a directory at the **identical path**
inside as on the host. Worktrees live on the host (`git worktree add`), the
container `cd`s into the same path, and the `.git` pointer just works.
Mechanics: `docker/README.md`.

## Quality gate

`quality/grade.sh` runs [lizard](https://github.com/terryyin/lizard)
(per-function complexity, length, parameter count) and
[jscpd](https://github.com/kucherenko/jscpd) (cross-file duplication), rolled
into a 0–10 / A–F score against `quality/thresholds.conf`, with a hard
ceiling on any single function's complexity. No SaaS account; same in CI, in
`cli ship`, and inside the reviewer's own review. What the grade means:
`docs/REVIEW.md`.

## Review policy

The reviewer subagent (`.claude/agents/reviewer.md`) is deliberately
adversarial: it hunts duplicated logic, unjustified abstractions,
architecture drift, and defect classes LLM-authored code is prone to. Its
verdict is evidence for a human code owner, never a merge decision —
`docs/REVIEW.md`.

## Layout

```
cli                          mechanics: dispatch/ship/sync/status/checkout/quality
subagent-instructions.md     appended to every dispatch prompt
examples/sdlc.conf.example   starter config, copied by `cli init`
docker/                      Dockerfile extending agent-sandbox with opencode + quality tools
quality/                     grade.sh + thresholds.conf — the self-hosted quality gate
templates/                   intent.md / spec.md / plan.md — the Plan→Design→Build artifact chain
docs/                        REVIEW.md (policy) and PLAYBOOK.md (stage mapping, gaps)
.claude/skills/sdlc-*/       the runbook a main Claude Code agent follows
.claude/agents/reviewer.md   the read-only adversarial review subagent
.claude/settings.json        permission allow/deny — secrets denied, read-only loop allowlisted
```

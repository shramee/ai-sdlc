# ai-sdlc

An agentic SDLC where a main agent orchestrates and a sandboxed worker
executes: **Claude Code, driven by skills, dispatches [`opencode`](https://opencode.ai)
workers into [`ag-sbx`](https://github.com/shramee/agent-sandbox) containers**,
gates every merge with an aggressive read-only reviewer subagent, and grades
code quality with self-hosted tooling instead of a SaaS dashboard.

Extracted from a working, single-project bash tool (`sdlc/cli`, driving
Claude Code directly in a bespoke container) into something repo-agnostic and
layered, and re-armed against
[Anthropic's AI-native SDLC playbook](https://claude.com/blog/the-ai-native-sdlc-playbook)
to fill the gaps that tool never had time to cover — see `docs/PLAYBOOK.md`
for exactly what maps where and what's still missing.

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

Why split it this way: a bash tool alone can dispatch and ship, but it can't
hold judgment — "is this spec ready," "does this diff actually satisfy the
criteria," "should this merge." That judgment now lives in skills (process)
and a subagent (code), on top of mechanics that stayed boring on purpose.

## Install

```bash
# 1. This repo
git clone https://github.com/shramee/ai-sdlc ~/www/ai-sdlc
ln -s ~/www/ai-sdlc/cli /usr/local/bin/ai-sdlc-cli   # or add it to $PATH as `cli`

# 2. agent-sandbox — owns image/container lifecycle, referenced not vendored
git clone https://github.com/shramee/agent-sandbox ~/www/agent-sandbox
~/www/agent-sandbox/install.sh

# 3. opencode, on the host too (cli copies ~/.local/share/opencode/auth.json
#    into each dispatch container — see docker/README.md)
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
cli config                # check what resolved
cli status                 # read-only fleet view
```

## Use

Drive it through the skills, not the bash commands directly — they carry the
judgment the mechanics don't have. Start at
[`AGENTS.md`](AGENTS.md#what-to-do-when) for the full sequence:
`sdlc-intent` → `sdlc-dispatch` → `sdlc-ship` → `sdlc-review` → `sdlc-sync`,
with `sdlc-status` and `sdlc-checkout` available any time.

The underlying commands, if you want the mechanics directly:

| | |
|---|---|
| `cli dispatch <repo> <branch> "<spec>"` | Run `opencode` on a host worktree inside its `ag-sbx` container |
| `cli vibe <repo> <branch>` | Same worktree/container, interactive session for a human |
| `cli checkout <repo> [branch]` / `cli restore <repo>` | Work the branch directly on the host instead |
| `cli ship [branch]` | Test + quality gate, then push and open a PR |
| `cli review-context <repo> <branch>` | Read-only diff/log/issue/PR bundle for the reviewer subagent |
| `cli quality <repo> [branch]` | Run the quality gate standalone |
| `cli sync [repo ...]` | Pull merged default branches; move submodule pointers |
| `cli status` | Per-repo branches, ahead counts, live containers, open PRs |
| `cli container <repo> [build\|deploy\|update\|clean\|status]` | Proxy to `ag-sbx` |
| `cli config` / `cli init` | Print / write `sdlc.conf` |

## Why `ag-sbx` changes the worktree story

The original tool created worktrees *inside* the container's own filesystem,
because its container mounted the whole project at a single `/workspace` path
unrelated to the host layout — so a worktree's `.git` pointer (an absolute
path baked in at creation) only resolved from one side, and every prune/lock
dance existed to keep the host and container from fighting over it.

`ag-sbx` mounts a directory at the **identical path** inside the container as
on the host. So worktrees now live on the host, created with plain
`git worktree add`, and the container `cd`s into the same path — the `.git`
pointer just works from both sides. No container-side worktree surgery, no
locking against a host-side prune, no dead-pointer class of bug. See the
comment at the top of `cli` and `docker/README.md` for the mechanics.

## Quality gate

`quality/grade.sh` runs [lizard](https://github.com/terryyin/lizard)
(per-function cyclomatic complexity, length, parameter count — multi-language)
and [jscpd](https://github.com/kucherenko/jscpd) (cross-file duplication),
rolls them into a 0–10 / A–F score against `quality/thresholds.conf`, with a
hard ceiling on any single function's complexity that fails the gate
regardless of the overall score. It's the self-hosted answer to what a tool
like Scrutinizer CI graded — no SaaS account, runs the same in CI, in
`cli ship`, and inside the reviewer subagent's own review. See
`docs/REVIEW.md` for what the grade means and doesn't mean.

## Review policy

The reviewer subagent (`.claude/agents/reviewer.md`) is deliberately
adversarial: it hunts for duplicated logic, unjustified abstractions,
architecture drift, and the specific defect classes (vacuous tests, weaker-
than-spec assertions, scope leakage) that have shipped in projects this was
extracted from. Its verdict is evidence for a human code owner, never a
merge decision by itself — full policy, severity tiers, and the tag-based
remediation flow in `docs/REVIEW.md`.

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

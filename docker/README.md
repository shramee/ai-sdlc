# The sandbox

`ai-sdlc dispatch` never talks to Docker directly for image/container lifecycle —
that's [`ag-sbx`](https://github.com/shramee/agent-sandbox)'s job. Install it
once, separately from this repo:

```bash
git clone https://github.com/shramee/agent-sandbox ~/.agent-sandbox
~/.agent-sandbox/install.sh   # symlinks ag-sbx onto your PATH
```

`ag-sbx` pulls `shramee/agent-sandbox:latest` by default and gives every
directory you run it from its own container, bind-mounted at the *identical
path* inside as out — which is exactly what `ai-sdlc`'s host-side worktree model
(`prepare_worktree`/`ensure_worker_container`) leans on: a worktree's
`.git` pointer is an absolute path, and because ag-sbx doesn't translate
paths the way a monolithic `/workspace` mount would, that pointer resolves
the same from both sides with no container-side worktree surgery.

## Why this repo has its own Dockerfile

The base `shramee/agent-sandbox` image has Claude Code and Command Code, but
not [opencode](https://opencode.ai) (the execution backend `ai-sdlc dispatch`
runs) or the quality-gate tools (`lizard`, `jscpd`). [`Dockerfile`](Dockerfile)
layers exactly those three things on top — it changes nothing about
agent-sandbox's user, mounts, or entrypoint.

Build and publish it the same way agent-sandbox's own `ag-sbx build`/`deploy`
would, then point `sdlc.conf` at it:

```bash
docker build -t youorg/ai-sdlc-sandbox:latest -f docker/Dockerfile docker/
docker push youorg/ai-sdlc-sandbox:latest   # if sharing across machines
```

```bash
# sdlc.conf
AG_SBX_IMAGE_OVERRIDE="youorg/ai-sdlc-sandbox:latest"
```

`ai-sdlc` exports `AG_SBX_IMAGE` from that value before every `ag-sbx` call, so
ag-sbx pulls/uses the derivative image instead of the stock one — see
`ag_sbx_env` in `ai-sdlc`.

## Credentials

ag-sbx already mounts `~/.claude` and `~/.commandcode` read-only plus live
transcript/session overlays (see agent-sandbox's own README for the full
list) — that machinery is untouched here. opencode's credentials
(`~/.local/share/opencode/auth.json`) sit next to a multi-GB local database
(`opencode.db`) that must never be mounted or copied wholesale, so `ai-sdlc`
doesn't lean on ag-sbx's mount set for them at all: `ensure_worker_container`
`docker cp`s just `auth.json` and `~/.config/opencode/opencode.json` into the
container after ag-sbx has it up. That works against any container regardless
of how it was created, and never requires a change to agent-sandbox itself.

Run `opencode auth login` on the host at least once before dispatching —
`ai-sdlc` copies whatever's in `~/.local/share/opencode/auth.json`.

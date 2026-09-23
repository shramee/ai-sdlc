# ai-sdlc sandbox: layers opencode + the quality-gate tools onto
# shramee/agent-sandbox (https://github.com/shramee/agent-sandbox), so
# `ag-sbx` (from that repo, installed separately — see docker/README.md)
# can run it unmodified. This Dockerfile owns nothing about ag-sbx's mount
# or credential model; it only adds what a dispatched opencode worker needs
# on top of the toolchain agent-sandbox already provides (node/pnpm, go,
# foundry, python).
FROM shramee/agent-sandbox:latest

USER root

# opencode: the execution backend for `ai-sdlc dispatch`.
RUN npm install -g opencode-ai@latest

# Quality gate tools (quality/grade.sh): lizard for complexity/length/params,
# jscpd for cross-file duplication. Both need to exist in the sandbox AND on
# whatever host runs `ai-sdlc ship` / `ai-sdlc quality` — see docs/REVIEW.md.
RUN pip install --break-system-packages --no-cache-dir lizard \
    && npm install -g jscpd@latest

USER agent
WORKDIR /workspace

# Plan: de-bloat instructions (everything, duplication-first)

Date: 2026-09-21
Status: saved, not yet executed

**Scope:** everything.
**Cut policy:** cut duplication, make language clear and efficient, keep
stories/examples only where they change behavior.
**Defect lists:** keep condensed one-liners.

## 1. Diagnosis (818 lines md + ~80-line `cli` header)

Bloat is mostly **repetition, not rules**:

* **3-layer model** said 5x: `AGENTS.md` + `README.md` + `docs/PLAYBOOK.md` +
  `cli` header + each skill intro.
* **Division of labor** (workers never push / reviewer read-only /
  orchestrator never patches / human merges) said 6x: `AGENTS.md`,
  `sdlc-ship`, `sdlc-checkout`, `sdlc-review`, `reviewer.md`, `docs/REVIEW.md`.
* **Quality gate = evidence, not verdict** said 4x: `sdlc-ship`,
  `sdlc-review`, `reviewer.md`, `docs/REVIEW.md`.
* **Mutation check + reuse-first** said 5x: `subagent-instructions.md`,
  `spec.md`, `plan.md`, `sdlc-dispatch`, `reviewer.md`.
* **Templates leak prose into prompts**: `intent/spec/plan.md` contain stage
  essays copied verbatim into every issue, dispatch prompt, and review bundle.
* Keepers: `agent.log` format example, one concrete mutation-check example,
  condensed defect list.

## 2. Fix principle: single source of truth

| Rule lives once in | Others just point to it |
|---|---|
| `AGENTS.md` = router (sequence + labor split) | skills say only their step + `Next ->` |
| `subagent-instructions.md` = worker behavior (reuse, commit, mutate, log, report) | `spec.md`/`dispatch`/`plan.md` cite, don't re-explain |
| `.claude/agents/reviewer.md` = code judgment + condensed defect list | `docs/REVIEW.md` = policy/severity only |
| `docs/PLAYBOOK.md` = playbook mapping | skills/templates cite stage name, no re-mapping |
| `cli` header = usage only | architecture essay moves to `README.md` |

Style: imperative, no "why the playbook says...", no "this exists because...".
One example max per rule, kept only if it prevents a real past failure.

## 3. Per-file edits

* **`AGENTS.md` (62->~35):** keep 3 layers (3 bullets), sequence (7
  one-liners), labor split (4 bullets), repo-self rules. Cut repeated skill
  descriptions.
* **`sdlc-dispatch` (78->~35):** keep dispatch command +
  first/resume/interrupted/remediation/batch as checklists. Cut re-explanation
  of `subagent-instructions.md`, `status`, `review` flows.
* **`sdlc-intent` (52->~30):** 4 steps as numbered checks. Cut parallelism
  essay to 2 lines; cut filing automation prose.
* **`sdlc-ship` (38->~20):** command + green-gate + "don't fix, re-dispatch" +
  handoff. Cut duplicated quality-gate meaning, checkout caveat -> one pointer.
* **`sdlc-review` (63->~30):** 5 steps as commands. Cut verdict philosophy,
  remediation theory -> pointers to `reviewer.md` / `REVIEW.md`.
* **`sdlc-checkout/status/sync` (40/27/24->~20/15/15):** command + when-to-use
  + one warning each. Cut re-stated labor-split and handoff prose.
* **`reviewer.md` (141->~70):** keep read-only allow/forbid table, reuse rules
  (4 bullets), quality-gate read (3 bullets), scope+priority slots, 8 defect
  classes -> 8 one-liners (keep names like "vacuous test: nil-slice loop", drop
  paragraphs), output schema + verdict. Cut sister-project anecdote to one
  clause, cut duplicated policy.
* **`subagent-instructions.md` (62->~30):** 5 headers (reuse, commit, mutate,
  log, report) with 1-2 lines + keep `agent.log` 4-line example + 1 mutation
  example. Cut war-story paragraphs.
* **`templates/intent/spec/plan.md` (36/53/32->~20 each):** headers + single
  hint sentence each. Cut stage essays, audit-trail prose, reuse/mutation
  lectures.
* **`docs/REVIEW.md` (60->~40), `docs/PLAYBOOK.md` (50->~35), `README.md`
  (150->~110), `cli` header (~80->~40):** docs keep depth but lose
  cross-duplicated labor/quality text; `cli` keeps subcommand usage only; also
  sweep `examples/sdlc.conf.example`, `docker/README.md`, `quality/` comments.

## 4. Verification

* `wc -l` before/after (target ~40% reduction, ~1000->~600 lines hot path).
* `grep` each SSOT phrase appears once (e.g. "never pushes", "evidence, not
  the verdict", "passing test is not evidence").
* Confirm no broken `->` / `see` links between skills, templates, docs.
* `bash -n cli`, `cli config` smoke, `quality/grade.sh` stays green.

## 5. Suggested execution order

1. `AGENTS.md` + SSOT map first (sets pointers).
2. 7 skills in one batch.
3. `subagent-instructions.md` + `reviewer.md` (condensed defects).
4. 3 templates.
5. Docs + `README` + `cli` header + examples sweep.

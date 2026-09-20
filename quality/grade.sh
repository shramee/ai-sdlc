#!/usr/bin/env bash
# quality/grade.sh <repo-dir> [branch] [thresholds-file]
#
# Self-hosted, Scrutinizer-style code quality grading: per-function cyclomatic
# complexity + length + parameter count (lizard) and cross-file duplication
# (jscpd), rolled into a single A-F grade with a pass/fail gate. Runs from
# the ship gate (docs/REVIEW.md) and from the sdlc-review skill, which hands
# its output to the reviewer subagent alongside the diff.
#
# With a branch, scores only files that branch touches relative to its
# upstream default branch (duplication still needs whole-repo context — a
# clone pair isn't a property of one file). Without one, scores the working
# tree as checked out.
set -euo pipefail

REPO_DIR="${1:?usage: grade.sh <repo-dir> [branch] [thresholds-file]}"
BRANCH="${2:-}"
THRESHOLDS_FILE="${3:-$(dirname "${BASH_SOURCE[0]}")/thresholds.conf}"

command -v lizard >/dev/null 2>&1 || { echo "!! lizard not found — pip install lizard (it's in docker/Dockerfile for the sandbox; install it on the host too for 'cli ship' to gate on it)" >&2; exit 2; }
command -v jscpd >/dev/null 2>&1 || { echo "!! jscpd not found — npm install -g jscpd (same story: sandbox has it, host needs it too)" >&2; exit 2; }
command -v python3 >/dev/null 2>&1 || { echo "!! python3 not found — needed to parse lizard/jscpd output" >&2; exit 2; }

# Defaults; thresholds.conf (bash, sourced) overrides.
MAX_CCN=10
HARD_MAX_CCN=20
MAX_FUNC_LENGTH=80
MAX_PARAMS=6
MAX_DUPLICATION_PCT=5
MIN_PASSING_SCORE=7.0
DEDUCT_PER_CCN_VIOLATION=0.3
DEDUCT_PER_LENGTH_VIOLATION=0.2
DEDUCT_PER_PARAM_VIOLATION=0.1
LIZARD_EXCLUDE=(-x "*/node_modules/*" -x "*/vendor/*" -x "*/.git/*" -x "*/dist/*" -x "*/build/*")
JSCPD_IGNORE="**/node_modules/**,**/vendor/**,**/.git/**,**/dist/**,**/build/**"

# shellcheck disable=SC1090
[ -f "$THRESHOLDS_FILE" ] && source "$THRESHOLDS_FILE"

cd "$REPO_DIR"

# Scope: changed files for a branch gate, whole tree otherwise. jscpd always
# runs on the whole tree (duplication is cross-file); lizard is scoped when
# we have a branch, since we only want to grade what this diff touched.
SCOPE_FILES=()
if [ -n "$BRANCH" ]; then
    default_branch="$(git remote show origin | sed -n '/HEAD branch/s/.*: //p')"
    while IFS= read -r f; do
        [ -f "$f" ] && SCOPE_FILES+=("$f")
    done < <(git diff --name-only "origin/$default_branch...$BRANCH" 2>/dev/null || true)
fi

LIZARD_TARGET=(.)
[ "${#SCOPE_FILES[@]}" -gt 0 ] && LIZARD_TARGET=("${SCOPE_FILES[@]}")

LIZARD_CSV="$(mktemp -t lizard-XXXX.csv)"
lizard --csv "${LIZARD_EXCLUDE[@]}" "${LIZARD_TARGET[@]}" > "$LIZARD_CSV" 2>/dev/null || true

JSCPD_OUT="$(mktemp -d -t jscpd-XXXX)"
jscpd --silent --reporters json --ignore "$JSCPD_IGNORE" --output "$JSCPD_OUT" . >/dev/null 2>&1 || true
JSCPD_JSON="$JSCPD_OUT/jscpd-report.json"
[ -f "$JSCPD_JSON" ] || echo '{"statistics":{"total":{"percentage":0}}}' > "$JSCPD_JSON"

python3 - "$LIZARD_CSV" "$JSCPD_JSON" "$MAX_CCN" "$HARD_MAX_CCN" "$MAX_FUNC_LENGTH" "$MAX_PARAMS" \
    "$MAX_DUPLICATION_PCT" "$MIN_PASSING_SCORE" "$DEDUCT_PER_CCN_VIOLATION" \
    "$DEDUCT_PER_LENGTH_VIOLATION" "$DEDUCT_PER_PARAM_VIOLATION" <<'PYEOF'
import csv, json, sys

(lizard_csv, jscpd_json, max_ccn, hard_max_ccn, max_len, max_params, max_dup,
 min_score, ded_ccn, ded_len, ded_param) = sys.argv[1:]
max_ccn, hard_max_ccn, max_len, max_params = int(max_ccn), int(hard_max_ccn), int(max_len), int(max_params)
max_dup, min_score = float(max_dup), float(min_score)
ded_ccn, ded_len, ded_param = float(ded_ccn), float(ded_len), float(ded_param)

score = 10.0
findings = []
hard_blockers = []

with open(lizard_csv, newline="") as f:
    for row in csv.reader(f):
        if len(row) < 8:
            continue
        nloc, ccn, token, param, length, location, file_, func = row[:8]
        try:
            ccn, length, param = int(ccn), int(length), int(param)
        except ValueError:
            continue
        where = f"{file_}:{func}"
        if ccn > hard_max_ccn:
            hard_blockers.append(f"{where} — CCN {ccn} (hard limit {hard_max_ccn})")
        if ccn > max_ccn:
            score -= ded_ccn
            findings.append(f"[complexity] {where} — CCN {ccn} > {max_ccn}")
        if length > max_len:
            score -= ded_len
            findings.append(f"[length] {where} — {length} lines > {max_len}")
        if param > max_params:
            score -= ded_param
            findings.append(f"[params] {where} — {param} params > {max_params}")

with open(jscpd_json) as f:
    dup_pct = json.load(f).get("statistics", {}).get("total", {}).get("percentage", 0) or 0

if dup_pct > max_dup:
    score -= (dup_pct - max_dup) * 0.5
    findings.append(f"[duplication] {dup_pct:.1f}% duplicated lines > {max_dup}% threshold")

score = max(0.0, min(10.0, score))
grade = "A" if score >= 9 else "B" if score >= 8 else "C" if score >= 7 else "D" if score >= 6 else "F"

print(f"== quality grade: {grade} ({score:.1f}/10) ==")
print(f"duplication: {dup_pct:.1f}% (threshold {max_dup}%)")
if findings:
    print(f"{len(findings)} finding(s):")
    for fnd in findings:
        print(f"  - {fnd}")
else:
    print("no complexity/length/param/duplication findings")

if hard_blockers:
    print(f"{len(hard_blockers)} HARD BLOCKER(S) (CCN > {hard_max_ccn}, gate fails regardless of score):")
    for b in hard_blockers:
        print(f"  ! {b}")

passed = score >= min_score and not hard_blockers
print(f"gate: {'PASS' if passed else 'FAIL'} (min score {min_score})")
sys.exit(0 if passed else 1)
PYEOF
RC=$?
rm -f "$LIZARD_CSV"
rm -rf "$JSCPD_OUT"
exit "$RC"

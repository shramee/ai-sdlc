#!/usr/bin/env bash
# quality/grade.sh <repo-dir> [branch] [thresholds-file]
#
# Self-hosted, Scrutinizer-style code quality grading: per-function cyclomatic
# complexity + length + parameter count (lizard) and cross-file duplication
# (jscpd), rolled into a single A-F grade with a pass/fail gate. Runs from
# the ship gate (docs/REVIEW.md) and from the sdlc-review skill, which hands
# its output to the reviewer subagent alongside the diff.
#
# CLI contract (unchanged): exit 0 = gate PASS, 1 = gate FAIL (including a
# crashed tool), 2 = missing prerequisite. Output: "== quality grade ==" line,
# "duplication:" line, findings, "gate: PASS|FAIL" line.
#
# WHAT IS MEASURED
#   With a branch, the gate measures what *the branch's diff* introduced or
#   touched, relative to its base (origin's default branch, resolved offline
#   from refs/remotes/origin/HEAD):
#     * complexity/length/params (lizard): functions in touched files whose
#       lines intersect the diff. Pre-existing violations in functions the
#       branch never edited do not count against it. Set LIZARD_DIFF_ONLY=0 to
#       score every function in each touched file instead.
#     * duplication (jscpd): the scan set is every TRACKED source file (so a
#       clone between a touched file and an untouched one is still found), but
#       the percentage is "lines inside a touched file that are part of a clone
#       / total lines of touched files". Clones living entirely in untouched
#       files are ignored. Untracked and gitignored files (fixtures, logs,
#       build output, generated data) are never scanned, and only files with a
#       source extension (SOURCE_EXTS) are considered.
#   Without a branch, the working tree is graded as checked out: every tracked
#   source file counts as touched.
#
# TOOL FAILURES FAIL THE GATE
#   lizard/jscpd exiting non-zero, producing no/unparsable output, or an
#   unresolvable base ref is reported as "gate: FAIL" with a "!!" message. A
#   broken tool is never treated as 0% duplication or an empty diff.
#
# CONFIGURATION (bash, sourced; later sources override earlier ones)
#   1. defaults below
#   2. <thresholds-file> (arg 3; project quality/thresholds.conf or the
#      tool's default) — per project
#   3. <repo>/.sdlc-thresholds.conf — per repo, for projects whose repos have
#      very different baselines. With a branch it is read from the BASE ref
#      (git show <base>:.sdlc-thresholds.conf) so a branch cannot loosen its
#      own gate; without a branch it is read from the working tree. It may set
#      any threshold plus the scan scope:
#        JSCPD_IGNORE_EXTRA="**/testdata/**,**/fixtures/**"   # appended
#        JSCPD_IGNORE="..."                                    # replaces default
#        LIZARD_EXCLUDE+=(-x "*/generated/*")
#        SOURCE_EXTS="go sol circom"                           # replaces default
#        LIZARD_DIFF_ONLY=0
set -euo pipefail

REPO_DIR="${1:?usage: grade.sh <repo-dir> [branch] [thresholds-file]}"
BRANCH="${2:-}"
THRESHOLDS_FILE="${3:-$(dirname "${BASH_SOURCE[0]}")/thresholds.conf}"
REPO_CONF_NAME=".sdlc-thresholds.conf"

command -v lizard >/dev/null 2>&1 || { echo "!! lizard not found — pip install lizard (needed by 'ai-sdlc ship' and 'ai-sdlc quality')" >&2; exit 2; }
command -v jscpd >/dev/null 2>&1 || { echo "!! jscpd not found — npm install -g jscpd (needed by 'ai-sdlc ship' and 'ai-sdlc quality')" >&2; exit 2; }
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
JSCPD_IGNORE_EXTRA=""
LIZARD_DIFF_ONLY=1
SOURCE_EXTS="py js jsx mjs cjs ts tsx go rs sol vy java kt scala c h cc cpp hpp cs rb php swift sh bash vue svelte astro circom nr cairo move"

# shellcheck disable=SC1090
[ -f "$THRESHOLDS_FILE" ] && source "$THRESHOLDS_FILE"

fail() { echo "== quality grade: F (0.0/10) =="; echo "!! $*"; echo "gate: FAIL (tool or setup error — fix it, don't bypass the gate)"; exit 1; }

cd "$REPO_DIR"

# Offline resolution of the base ref (no `git remote show origin` round trip).
default_base_ref() {
    local ref c
    ref="$(git symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null || true)"
    if [ -n "$ref" ] && git rev-parse --verify -q "$ref^{commit}" >/dev/null; then echo "$ref"; return 0; fi
    for c in origin/main origin/master main master; do
        if git rev-parse --verify -q "$c^{commit}" >/dev/null; then echo "$c"; return 0; fi
    done
    return 1
}

BASE=""
if [ -n "$BRANCH" ]; then
    BASE="$(default_base_ref)" || fail "can't resolve a base ref for $BRANCH (no origin/HEAD, origin/main|master, main|master) — run: git remote set-head origin -a"
fi

# Per-repo overrides (see header for why the base ref is the source).
REPO_CONF="$(mktemp "${TMPDIR:-/tmp}/sdlc-repoconf.XXXXXX")"
if [ -n "$BASE" ]; then
    git show "$BASE:$REPO_CONF_NAME" > "$REPO_CONF" 2>/dev/null || : > "$REPO_CONF"
elif [ -f "$REPO_CONF_NAME" ]; then
    cat "$REPO_CONF_NAME" > "$REPO_CONF"
fi
# shellcheck disable=SC1090
source "$REPO_CONF"
rm -f "$REPO_CONF"
[ -n "$JSCPD_IGNORE_EXTRA" ] && JSCPD_IGNORE="$JSCPD_IGNORE,$JSCPD_IGNORE_EXTRA"

# Source-extension filter, applied to tracked files that exist on disk.
is_source() {
    local ext="${1##*.}" e
    [ "$ext" = "$1" ] && return 1
    for e in $SOURCE_EXTS; do [ "$ext" = "$e" ] && return 0; done
    return 1
}

TMP="$(mktemp -d "${TMPDIR:-/tmp}/sdlc-grade.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
ALL_FILES="$TMP/all.txt"      # tracked source files: the jscpd scan set
TOUCHED_FILES="$TMP/touched.txt"  # the subset this branch touches
: > "$ALL_FILES"; : > "$TOUCHED_FILES"

while IFS= read -r -d '' f; do
    [ -f "$f" ] && is_source "$f" && printf '%s\n' "$f" >> "$ALL_FILES"
done < <(git ls-files -z)

if [ -n "$BASE" ]; then
    git diff --name-only --no-renames -z "$BASE...$BRANCH" > "$TMP/names.z" || fail "git diff $BASE...$BRANCH failed"
    while IFS= read -r -d '' f; do
        [ -f "$f" ] && is_source "$f" && printf '%s\n' "$f" >> "$TOUCHED_FILES"
    done < "$TMP/names.z"
    git diff -U0 --no-renames "$BASE...$BRANCH" > "$TMP/diff.patch" || fail "git diff $BASE...$BRANCH failed"
else
    cp "$ALL_FILES" "$TOUCHED_FILES"
    : > "$TMP/diff.patch"
fi

# lizard — touched files only. Nothing touched means nothing to grade.
LIZARD_CSV="$TMP/lizard.csv"
: > "$LIZARD_CSV"
if [ -s "$TOUCHED_FILES" ]; then
    # A tracked file may not be readable text; xargs keeps argv bounded.
    LIZ_ERR="$TMP/lizard.err"
    if ! tr '\n' '\0' < "$TOUCHED_FILES" | xargs -0 lizard --csv "${LIZARD_EXCLUDE[@]}" > "$LIZARD_CSV" 2> "$LIZ_ERR"; then
        fail "lizard crashed (non-zero exit): $(head -c 400 "$LIZ_ERR")"
    fi
fi

# jscpd — scan every tracked source file (clones against untouched files must
# be visible); duplication is attributed to touched files in the python step.
JSCPD_JSON="$TMP/jscpd/jscpd-report.json"
if [ -s "$TOUCHED_FILES" ]; then
    python3 - "$ALL_FILES" "$JSCPD_IGNORE" "$TMP/jscpd" "$TMP/jscpd.json" <<'PYEOF'
import json, os, sys
# jscpd resolves `path` relative to the config file, so hand it absolute paths.
files = [os.path.abspath(l.rstrip("\n")) for l in open(sys.argv[1]) if l.strip()]
ignore = [p for p in sys.argv[2].split(",") if p]
json.dump({"path": files, "ignore": ignore, "gitignore": True, "reporters": ["json"],
           "output": sys.argv[3], "silent": True}, open(sys.argv[4], "w"))
PYEOF
    if ! jscpd --config "$TMP/jscpd.json" > "$TMP/jscpd.out" 2>&1; then
        fail "jscpd crashed (non-zero exit): $(tail -c 400 "$TMP/jscpd.out")"
    fi
    [ -f "$JSCPD_JSON" ] || fail "jscpd produced no report: $(tail -c 400 "$TMP/jscpd.out")"
else
    JSCPD_JSON=""
fi

RC=0
python3 - "$LIZARD_CSV" "$JSCPD_JSON" "$TOUCHED_FILES" "$TMP/diff.patch" "$LIZARD_DIFF_ONLY" \
    "$MAX_CCN" "$HARD_MAX_CCN" "$MAX_FUNC_LENGTH" "$MAX_PARAMS" \
    "$MAX_DUPLICATION_PCT" "$MIN_PASSING_SCORE" "$DEDUCT_PER_CCN_VIOLATION" \
    "$DEDUCT_PER_LENGTH_VIOLATION" "$DEDUCT_PER_PARAM_VIOLATION" <<'PYEOF' || RC=$?
import csv, json, os, re, sys

(lizard_csv, jscpd_json, touched_list, diff_patch, diff_only, max_ccn, hard_max_ccn,
 max_len, max_params, max_dup, min_score, ded_ccn, ded_len, ded_param) = sys.argv[1:]
max_ccn, hard_max_ccn, max_len, max_params = int(max_ccn), int(hard_max_ccn), int(max_len), int(max_params)
max_dup, min_score = float(max_dup), float(min_score)
ded_ccn, ded_len, ded_param = float(ded_ccn), float(ded_len), float(ded_param)
diff_only = diff_only == "1"
norm = os.path.normpath


def bail(msg):
    print("== quality grade: F (0.0/10) ==")
    print(f"!! {msg}")
    print("gate: FAIL (tool or setup error — fix it, don't bypass the gate)")
    sys.exit(1)


touched = [norm(l.rstrip("\n")) for l in open(touched_list) if l.strip()]

# Changed line ranges per file, from `git diff -U0` (empty = whole tree mode).
changed = {}
cur = None
for line in open(diff_patch, errors="replace"):
    if line.startswith("+++ "):
        p = line[4:].rstrip("\n")
        cur = norm(p[2:]) if p.startswith("b/") else None
    elif line.startswith("@@") and cur:
        m = re.match(r"@@ -\S+ \+(\d+)(?:,(\d+))? @@", line)
        if m:
            start, n = int(m.group(1)), int(m.group(2) if m.group(2) is not None else 1)
            if n:
                changed.setdefault(cur, []).append((start, start + n - 1))
use_diff = diff_only and bool(changed)

score = 10.0
findings = []
hard_blockers = []
functions = 0

with open(lizard_csv, newline="") as f:
    for row in csv.reader(f):
        if not row:
            continue
        if len(row) < 11:
            bail(f"lizard produced unparsable output: {row!r}"[:300])
        nloc, ccn, token, param, length, location, file_, func = row[:8]
        try:
            ccn, length, param = int(ccn), int(length), int(param)
            fstart, fend = int(row[9]), int(row[10])
        except ValueError:
            bail(f"lizard produced unparsable output: {row!r}"[:300])
        functions += 1
        if use_diff:
            ranges = changed.get(norm(file_), [])
            if not any(a <= fend and b >= fstart for a, b in ranges):
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

# Duplication: share of touched-file lines that sit inside a clone (either
# side of a pair), so clones against untouched files count, clones among
# untouched files don't.
dup_pct = 0.0
total_lines = 0
dup_lines = 0
if jscpd_json:
    try:
        with open(jscpd_json) as f:
            report = json.load(f)
        clones = report["duplicates"]
    except (OSError, ValueError, KeyError, TypeError) as e:
        bail(f"jscpd report unparsable: {e}")
    tset = set(touched)
    covered = {}
    for c in clones:
        for side in ("firstFile", "secondFile"):
            fi = c[side]
            name = norm(os.path.relpath(fi["name"]))
            if name in tset:
                covered.setdefault(name, set()).update(range(int(fi["start"]), int(fi["end"]) + 1))
    for name in touched:
        try:
            with open(name, errors="replace") as fh:
                n = sum(1 for _ in fh)
        except OSError:
            continue
        total_lines += n
        dup_lines += len([ln for ln in covered.get(name, ()) if ln <= n])
    dup_pct = 100.0 * dup_lines / total_lines if total_lines else 0.0

if dup_pct > max_dup:
    score -= (dup_pct - max_dup) * 0.5
    findings.append(f"[duplication] {dup_pct:.1f}% duplicated lines > {max_dup}% threshold")

score = max(0.0, min(10.0, score))
grade = "A" if score >= 9 else "B" if score >= 8 else "C" if score >= 7 else "D" if score >= 6 else "F"

print(f"== quality grade: {grade} ({score:.1f}/10) ==")
print(f"duplication: {dup_pct:.1f}% (threshold {max_dup}%)")
scope = f"{len(touched)} touched source file(s), {functions} function(s) analysed"
scope += ", complexity scoped to changed lines" if use_diff else ", complexity scoped to whole touched files"
scope += f", duplication = {dup_lines}/{total_lines} touched lines in clones"
print(f"scope: {scope}")
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
exit "$RC"

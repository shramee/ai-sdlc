#!/usr/bin/env bash
# Smoke test for quality/grade.sh: builds a throwaway repo (bare origin + clone)
# and asserts the gate passes a clean small change, fails a large duplicated
# block, ignores untracked/gitignored junk, scopes complexity to the diff,
# honours a base-ref .sdlc-thresholds.conf, and fails (not passes) when a tool
# crashes. Needs git, python3, lizard, jscpd.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GRADE="$HERE/../grade.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/grade-smoke.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

PASS=0; FAILED=0
ok()  { PASS=$((PASS + 1)); echo "ok   - $1"; }
bad() { FAILED=$((FAILED + 1)); echo "FAIL - $1"; [ -n "${2:-}" ] && echo "$2" | sed 's/^/       /'; return 0; }

# expect <name> <pass|fail> [grep-pattern] -- <grade.sh args...>
expect() {
    local name="$1" want="$2" pat="$3"; shift 4
    local out rc=0
    out="$("$GRADE" "$@" 2>&1)" || rc=$?
    if [ "$want" = pass ] && [ "$rc" -ne 0 ]; then bad "$name (expected PASS, rc=$rc)" "$out"; return; fi
    if [ "$want" = fail ] && [ "$rc" -ne 1 ]; then bad "$name (expected FAIL rc=1, got rc=$rc)" "$out"; return; fi
    if [ -n "$pat" ] && ! grep -qE "$pat" <<<"$out"; then bad "$name (output missing /$pat/)" "$out"; return; fi
    ok "$name"
    echo "$out" | grep -E '^(== quality grade|duplication:|gate:|!!)' | sed 's/^/       /'
}

gen_js() { # gen_js <n> <prefix>: n distinct simple functions
    python3 - "$1" "$2" <<'PY'
import sys
n, p = int(sys.argv[1]), sys.argv[2]
for i in range(n):
    print(f"function {p}{i}(a, b) {{ if (a > {i}) {{ return a * b + {i}; }} return b - a - {i}; }}")
PY
}

gen_complex() { # gen_complex <name> <seed>: one function with CCN above HARD_MAX_CCN
    python3 - "$1" "$2" <<'PY'
import sys
name, seed = sys.argv[1], int(sys.argv[2])
print(f"function {name}(x, y) {{")
for i in range(25):
    # distinct literals/operators per seed so jscpd doesn't see clones
    print(f"  if (x {['===', '>', '<', '!=='][(i + seed) % 4]} {i * seed + 7}) {{ y += {i ** (seed % 3 + 1)}; }}")
print("  return y;\n}")
PY
}

export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
git init -q --bare -b main "$TMP/origin.git"
git clone -q "$TMP/origin.git" "$TMP/work" 2>/dev/null
cd "$TMP/work"
git checkout -q -b main
gen_js 60 base > lib.js
gen_complex tangled 1 > legacy.js          # pre-existing violation, on main
echo "console.log('hello');" > small.js
printf 'node_modules/\nignored_data/\n' > .gitignore
git add -A && git commit -q -m base && git push -q -u origin main
git remote set-head origin main

# ---- 1. clean small change passes
git checkout -q -b feature/clean
echo "console.log('world');" >> small.js
git commit -qam "small change" && git push -q origin feature/clean
expect "clean small change passes" pass "gate: PASS" -- "$TMP/work" feature/clean

# ---- 2. large duplicated block fails
git checkout -q -b feature/dup main
cp lib.js lib_copy.js
git add -A && git commit -qm "copy-paste" && git push -q origin feature/dup
expect "large duplicated block fails" fail "\[duplication\]" -- "$TMP/work" feature/dup

# ---- 3. untracked + gitignored junk next to a clean branch is not scanned
git checkout -q feature/clean
mkdir -p ignored_data
cp lib.js ignored_data/a.js; cp lib.js ignored_data/b.js; cp lib.js untracked_copy.js
expect "untracked/gitignored duplicates are ignored" pass "duplication: 0\.0%" -- "$TMP/work" feature/clean
rm -rf ignored_data untracked_copy.js

# ---- 4. touching a file with a pre-existing complex function passes...
git checkout -q -b feature/touch-legacy main
echo "// comment" >> legacy.js
git commit -qam "touch legacy file" && git push -q origin feature/touch-legacy
expect "pre-existing violation outside the diff passes" pass "gate: PASS" -- "$TMP/work" feature/touch-legacy
# ...but a new complex function fails
git checkout -q -b feature/new-complex main
gen_complex another 2 > fresh.js
git add -A && git commit -qm "new complex fn" && git push -q origin feature/new-complex
expect "new hard-limit complexity fails" fail "HARD BLOCKER" -- "$TMP/work" feature/new-complex

# ---- 5. per-repo override from the base ref
git checkout -q -b chore/conf main
echo 'HARD_MAX_CCN=40; MAX_CCN=40' > .sdlc-thresholds.conf
git add -A && git commit -qm "repo thresholds" && git push -q origin chore/conf
git checkout -q main && git merge -q --ff-only chore/conf && git push -q origin main
git checkout -q -b feature/new-complex2 main
gen_complex yetanother 3 > fresh2.js
git add -A && git commit -qm "complex fn under relaxed repo thresholds" && git push -q origin feature/new-complex2
expect "per-repo .sdlc-thresholds.conf (from base) is honoured" pass "gate: PASS" -- "$TMP/work" feature/new-complex2

# ---- 6. tool crash fails the gate rather than passing
mkdir -p "$TMP/bin"
printf '#!/bin/sh\necho boom >&2\nexit 3\n' > "$TMP/bin/jscpd"; chmod +x "$TMP/bin/jscpd"
PATH="$TMP/bin:$PATH" expect "jscpd crash fails the gate" fail "jscpd crashed" -- "$TMP/work" feature/clean
rm "$TMP/bin/jscpd"
printf '#!/bin/sh\necho boom >&2\nexit 3\n' > "$TMP/bin/lizard"; chmod +x "$TMP/bin/lizard"
PATH="$TMP/bin:$PATH" expect "lizard crash fails the gate" fail "lizard crashed" -- "$TMP/work" feature/clean

# ---- 7. unresolvable base fails (no origin/HEAD, no main/master)
git init -q -b trunk "$TMP/nobase" && cd "$TMP/nobase"
echo "x" > a.js && git add -A && git commit -qm init && git checkout -q -b feature/x
echo "y" >> a.js && git commit -qam change
expect "unresolvable base is a failure" fail "can't resolve a base ref" -- "$TMP/nobase" feature/x

echo
echo "$PASS passed, $FAILED failed"
[ "$FAILED" -eq 0 ]

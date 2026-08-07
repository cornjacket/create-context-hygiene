#!/usr/bin/env bash
# self-test.sh — end-to-end self test for the context-hygiene generator.
#
# Generates into disposable repos under sandbox/, exercises every checker and
# the pre-commit hook, verifies regeneration safety, then tears everything down.
#
# Usage:
#   bash self-test.sh            # run and clean up
#   bash self-test.sh --keep     # leave sandbox/ in place for inspection
#
# Exit code is the number of failed assertions (0 = all green), so it is
# CI-ready as-is.
#
# Two git layouts are covered, because the difference between them is exactly
# where root resolution goes wrong: a plain repo where `.git` is a DIRECTORY,
# and a bare-plus-linked-worktree layout (the shape create-ai-builder uses) where
# a worktree's `.git` is a FILE. A check written with `[ -d .git ]` passes the
# first and silently misses the second.

set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GEN="$REPO/generate.sh"
SANDBOX="$REPO/sandbox"
KEEP=false
[[ "${1:-}" == "--keep" ]] && KEEP=true

PASS=0; FAIL=0; FAILED_LABELS=()
ok(){  printf '    \033[32m✓\033[0m %s\n' "$1"; PASS=$((PASS+1)); }
bad(){ printf '    \033[31m✗\033[0m %s\n' "$1"; FAIL=$((FAIL+1)); FAILED_LABELS+=("$1"); }
t(){ if [[ $1 == 0 ]]; then ok "$2"; else bad "$2"; fi; }
section(){ printf '\n\033[1m%s\033[0m\n' "$1"; }

cleanup(){
    if [[ "$KEEP" == true ]]; then
        echo ""; echo "sandbox/ kept at: $SANDBOX"
    else
        rm -rf "$SANDBOX"
    fi
}
trap cleanup EXIT

rm -rf "$SANDBOX"; mkdir -p "$SANDBOX"

# ---------------------------------------------------------------------------
# Fixture content
# ---------------------------------------------------------------------------
# Deliberately shaped: an @-import (a tax a per-file check cannot see), one
# fenced block for the lint to find, and nothing else — so the assertions below
# fail for one reason each.
seed_target(){
    local dst="$1"
    mkdir -p "$dst/docs"
    cat > "$dst/CLAUDE.md" <<'EOF'
# CLAUDE.md — self-test target

Kernel rules live here.

@docs/conventions.md

## Safety

Never force-push to main.

## Building

```sh
make check
```
EOF
    printf '# Conventions\n\nCommits use `<domain>(<scope>)`.\n' > "$dst/docs/conventions.md"
}

# Append a section big enough to blow any sane budget.
bloat(){
    { echo ""; echo "## Bloat"; echo ""
      for _ in $(seq 1 40); do
          echo "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod."
      done; } >> "$1/CLAUDE.md"
}

# $1 = target root, $2 = label prefix — every checker, against one target.
exercise(){
    local T="$1" TAG="$2" H="$1/.context-hygiene" OUT

    [[ -f "$H/check_budget.py" && -f "$H/context_lint.py" ]]
    t $? "$TAG checkers installed"
    [[ -f "$T/.context-budget.toml" ]];  t $? "$TAG budget manifest seeded"
    [[ -f "$T/docs/PLACEMENT.md" ]];     t $? "$TAG placement rubric emitted"

    # No generator-time placeholder may survive into emitted output. The CI
    # template also carries GitHub Actions ${{ ... }} expressions that MUST
    # survive — see the two-namespace note in generate.sh.
    ! grep -rqE '\{\{[A-Z_]+\}\}' "$T/.context-budget.toml" "$T/docs/PLACEMENT.md"
    t $? "$TAG no generator placeholders survived"

    OUT="$(cd "$T" && python3 "$H/check_budget.py" 2>&1)"
    t $? "$TAG budget report passes on the seeded config"
    [[ "$OUT" == *"TOTAL always-on"* ]];  t $? "$TAG report prints a total"

    # The @-import is the hidden tax: nothing in the manifest names it.
    [[ "$OUT" == *"docs/conventions.md"* && "$OUT" == *"@import"* ]]
    t $? "$TAG @-import discovered and folded into the total"
    ! grep -q 'conventions' "$T/.context-budget.toml"
    t $? "$TAG ...and it is counted without being listed in the manifest"

    OUT="$(cd "$T" && python3 "$H/context_lint.py" --json 2>&1)"
    [[ "$OUT" == *'"smell": "code-block"'* ]]
    t $? "$TAG lint flags the fenced block"
    [[ "$OUT" == *'"suggested_bucket"'* ]]
    t $? "$TAG ...and names a placement bucket for it"

    # An oversized section must trip the section ceiling even while the file and
    # the total still pass — that is the whole point of a per-section budget.
    ( cd "$T" && python3 - <<'PY'
import pathlib, re
p = pathlib.Path(".context-budget.toml")
# Low enough to catch a section of this fixture, which is deliberately tiny —
# the point is that the section ceiling bites while the file and the total
# still pass, so a failure here can only mean the per-section level is dead.
p.write_text(re.sub(r"^max_section(\s*)=.*$", r"max_section\1= 5",
                    p.read_text(), flags=re.M))
PY
    )
    OUT="$(cd "$T" && python3 "$H/check_budget.py" 2>&1)"; local rc=$?
    [[ $rc -ne 0 ]];                     t $? "$TAG oversized section fails the run"
    [[ "$OUT" == *"(section,"* ]];       t $? "$TAG ...and the report names the section"
}

echo "context-hygiene generator — self test"
echo "sandbox: $SANDBOX"

############################################################
section "1. Plain repo (.git is a directory)"
A="$SANDBOX/plain"
mkdir -p "$A" && seed_target "$A"
( cd "$A" && git init -q && git config user.email selftest@local \
    && git config user.name selftest )
"$GEN" --target-repo "$A" --install-hooks --with-audit-skill >/dev/null 2>&1
t $? "generate.sh exits 0"
[[ -f "$A/.claude/skills/context-audit/SKILL.md" ]]; t $? "audit skill emitted with --with-audit-skill"
[[ -f "$A/.github/workflows/context-hygiene.yml" ]]; t $? "CI workflow emitted"
grep -q 'secrets.ANTHROPIC_API_KEY' "$A/.github/workflows/context-hygiene.yml"
t $? "CI runtime \${{ }} expressions survived generation"
exercise "$A" "plain:"

############################################################
section "2. The pre-commit hook is a real gate"
( cd "$A" && git checkout -q -- .context-budget.toml 2>/dev/null; \
  "$GEN" --target-repo . --install-hooks --force >/dev/null 2>&1 )
HOOK="$A/$(git -C "$A" rev-parse --git-path hooks)/pre-commit"
[[ -x "$HOOK" ]] || HOOK="$(git -C "$A" rev-parse --git-path hooks)/pre-commit"
[[ -x "$HOOK" ]];                        t $? "pre-commit hook installed and executable"
grep -q -- '--counter heuristic' "$HOOK"
t $? "hook is pinned to an offline counter (no network on commit)"

( cd "$A" && git add -A && git commit -qm "chore: install" ) >/dev/null 2>&1
t $? "a within-budget commit is allowed"

bloat "$A"
( cd "$A" && git add CLAUDE.md && git commit -qm "docs: bloat" ) >/dev/null 2>&1
[[ $? -ne 0 ]];                          t $? "an over-budget commit is BLOCKED"

( cd "$A" && git commit -qm "docs: bloat" --no-verify ) >/dev/null 2>&1
t $? "...and --no-verify still gets through (the hook is a warning, CI is the gate)"

############################################################
section "3. Regeneration is safe (no --force needed to upgrade)"
BEFORE="$(cd "$A" && git status --porcelain)"
"$GEN" --target-repo "$A" --install-hooks --with-audit-skill >/dev/null 2>&1
AFTER="$(cd "$A" && git status --porcelain)"
[[ "$BEFORE" == "$AFTER" ]];             t $? "re-running the generator is a zero-line diff"

# CONTENT is never clobbered: a hand-edited budget survives regeneration.
( cd "$A" && printf '\n# hand-edited\n' >> .context-budget.toml )
"$GEN" --target-repo "$A" >/dev/null 2>&1
grep -q 'hand-edited' "$A/.context-budget.toml"
t $? "a hand-edited .context-budget.toml survives regeneration"

############################################################
section "4. Bare + linked worktree (.git is a FILE)"
W="$SANDBOX/wt"
mkdir -p "$W/seed"
( cd "$W/seed" && git init -q -b main && git config user.email selftest@local \
  && git config user.name selftest && echo seed > seed.txt \
  && git add -A && git commit -qm seed )
git clone -q --bare "$W/seed" "$W/.bare" 2>/dev/null
rm -rf "$W/seed"
git --git-dir="$W/.bare" worktree add -q "$W/main" main 2>/dev/null
t $? "worktree layout created"
[[ -f "$W/main/.git" ]];  t $? ".git in the worktree is a FILE, not a directory"

seed_target "$W/main"
( cd "$W/main" && git config user.email selftest@local && git config user.name selftest )
"$GEN" --target-repo "$W/main" --install-hooks >/dev/null 2>&1
t $? "generate.sh exits 0 in a linked worktree"

# The failure this guards: resolving to the .bare container instead of the
# worktree, which puts the toolkit somewhere nothing ever reads it.
[[ -d "$W/main/.context-hygiene" && ! -d "$W/.bare/.context-hygiene" ]]
t $? "installed into the worktree, not the .bare container"
ROOT="$(cd "$W/main" && python3 -c "
import sys; sys.path.insert(0, '.context-hygiene')
from hygiene_env import resolve_repo_root; print(resolve_repo_root('.'))")"
[[ "$ROOT" == "$W/main" ]];              t $? "checkers resolve the worktree root, not .bare"
exercise "$W/main" "worktree:"

############################################################
section "5. Teardown"
if [[ "$KEEP" == true ]]; then
    ok "sandbox/ kept for inspection (--keep) — teardown not exercised"
else
    rm -rf "${SANDBOX:?}"/*
    [[ -z "$(ls -A "$SANDBOX" 2>/dev/null)" ]]; t $? "sandbox/ left empty"
fi

############################################################
printf '\n\033[1mResult:\033[0m %d passed, %d failed\n' "$PASS" "$FAIL"
if [[ $FAIL -gt 0 ]]; then
    printf '\nFailed:\n'
    for l in "${FAILED_LABELS[@]}"; do printf '  - %s\n' "$l"; done
fi
exit $FAIL

#!/usr/bin/env bash
# tests/run.sh — golden / reproducibility test.
#
# Generates each fixture into a temp target and diffs the result against the
# checked-in expected tree under tests/golden/. Any drift — a changed checker, a
# new file, a reworded template — fails with a readable diff.
#
# Usage:
#   bash tests/run.sh            # verify against the golden fixtures
#   bash tests/run.sh --update   # regenerate them (an intentional refresh)
#
# When you INTENTIONALLY change the generated output, this test failing is the
# design working. Review the diff, then `bash tests/run.sh --update` and commit
# the fixtures alongside the source change so the change is visible in review.
#
# Determinism note: the emitted tree contains no timestamps or random IDs, and
# .context-budget.toml is seeded from the fixture target's own counts — which
# are fixed by the seed content below. Identical inputs therefore produce
# byte-identical output, which is exactly what the fixtures pin.

set -u
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GEN="$REPO/generate.sh"
GOLDEN="$REPO/tests/golden"
UPDATE=false
[[ "${1:-}" == "--update" ]] && UPDATE=true

fixture_flags() {
    case "$1" in
        core)      echo "--counter heuristic" ;;
        all)       echo "--counter heuristic --with-audit-skill --install-hooks" ;;
        no-lint)   echo "--counter heuristic --no-lint" ;;
        *) echo "UNKNOWN"; return 1 ;;
    esac
}
FIXTURES=(core all no-lint)

# Seed a deterministic target: a small kernel with one procedural section and an
# @-import, which is enough to exercise budgets, sections, imports, and lint.
seed_target() {
    local dst="$1"
    mkdir -p "$dst/docs"
    cat > "$dst/CLAUDE.md" <<'EOF'
# CLAUDE.md — fixture

Kernel rules live here.

@docs/conventions.md

## Task Management

Follow these steps to create a task:

1. Run the new-task script with a name.
2. Fill in the metadata table.
3. Move it to the right folder.
4. Tell the owner it exists.
5. Never close it without confirmation.

## Safety

Never force-push to main.
EOF
    printf '# Conventions\n\nCommit messages use `<domain>(<scope>)`.\n' \
        > "$dst/docs/conventions.md"
    printf '# MEMORY\n\n- [thing](thing.md) — hook\n' > "$dst/MEMORY.md"
}

generate_into() {
    local name="$1" dst="$2"
    seed_target "$dst"
    ( cd "$dst" && git init -q && git config user.email golden@local \
        && git config user.name golden )
    # shellcheck disable=SC2046
    "$GEN" --target-repo "$dst" $(fixture_flags "$name") >/dev/null 2>&1
    # The hook lives inside .git, which we strip — copy it out so it is pinned.
    if [[ -f "$dst/.git/hooks/pre-commit" ]]; then
        cp "$dst/.git/hooks/pre-commit" "$dst/pre-commit.hook"
    fi
    rm -rf "$dst/.git" "$dst/.context-hygiene/__pycache__"
}

if [[ "$UPDATE" == true ]]; then
    echo "Refreshing golden fixtures:"
    for name in "${FIXTURES[@]}"; do
        tmp="$(mktemp -d)"; generate_into "$name" "$tmp"
        rm -rf "${GOLDEN:?}/$name"; mkdir -p "$GOLDEN/$name"
        cp -R "$tmp"/. "$GOLDEN/$name/"; rm -rf "$tmp"
        echo "  updated $name ($(find "$GOLDEN/$name" -type f | wc -l | tr -d ' ') files)"
    done
    echo "Review 'git diff tests/golden/' and commit if intended."
    exit 0
fi

FAIL=0
for name in "${FIXTURES[@]}"; do
    if [[ ! -d "$GOLDEN/$name" ]]; then
        echo "MISSING fixture: tests/golden/$name — run: bash tests/run.sh --update" >&2
        FAIL=$((FAIL+1)); continue
    fi
    tmp="$(mktemp -d)"; generate_into "$name" "$tmp"
    if diff -r "$GOLDEN/$name" "$tmp" > "/tmp/golden-diff.$$" 2>&1; then
        echo "✓ $name — matches golden ($(find "$GOLDEN/$name" -type f | wc -l | tr -d ' ') files)"
    else
        echo "✗ $name — DRIFT from golden:"
        sed 's/^/    /' "/tmp/golden-diff.$$"
        echo "    If this change is intended: bash tests/run.sh --update && commit tests/golden/"
        FAIL=$((FAIL+1))
    fi
    rm -rf "$tmp" "/tmp/golden-diff.$$"
done

echo ""
if [[ $FAIL -eq 0 ]]; then
    echo "GOLDEN OK — all fixtures reproduce byte-for-byte"
else
    echo "$FAIL fixture(s) drifted"
fi
exit $FAIL

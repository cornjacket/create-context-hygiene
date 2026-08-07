#!/usr/bin/env bash
# generate.sh — install the context-hygiene toolkit into a target repo.
#
# Usage:
#   generate.sh --target-repo <path> [options]
#
# Options:
#   --target-repo <path>     Repo to install into (required)
#   --counter <name>         heuristic | tiktoken | anthropic (default: heuristic)
#   --hygiene-dir <rel>      Mount path for the checkers (default: .context-hygiene)
#   --with-lint              Emit context-lint (DEFAULT ON)
#   --no-lint                Do not emit context-lint
#   --with-audit-skill       Emit the on-demand LLM audit skill
#   --install-hooks          Wire up the pre-commit hook and a CI workflow
#   --force                  Also re-seed content (.context-budget.toml) and
#                            overwrite files this generator does not own
#   -h, --help               Show this help
#
# COLLISION POLICY — regeneration is safe by default:
#   * MACHINERY (the checkers, PLACEMENT.md, the hook, the CI workflow, the
#     audit skill) is ALWAYS overwritten. It is generated output; that is the
#     point, and it is why re-running upgrades an install instead of forking it.
#   * CONTENT (.context-budget.toml — your budgets) is created ONLY IF MISSING
#     and is never overwritten. Your thresholds are never touched.
#   * FOREIGN FILES the generator did not write (an existing pre-commit hook, an
#     unrelated docs/PLACEMENT.md) are left alone and reported, not clobbered.
#   So re-running the same command upgrades the machinery and leaves your
#   settings alone. --force additionally re-seeds the budget file.
#
# TWO PLACEHOLDER NAMESPACES — do not conflate them:
#   generator-time : {{HYGIENE_DIR}} {{COUNTER}} {{HOOK_COUNTER}} {{CI_DEPS}}
#                    {{MODEL}} {{TOTAL_CEILING}} {{MAX_SECTION}}
#                    {{ALWAYS_ON_ENTRIES}}  -> substituted here, must not survive.
#   runtime        : GitHub Actions expressions such as ${{ secrets.ANTHROPIC_API_KEY }}
#                    -> live in the CI template and MUST survive generation.
#   The two are distinguishable by name, and every substitution below is by
#   explicit token. Never add a blanket `{{...}}` rewrite: it would eat the
#   Actions expressions and the workflow would silently lose its API key.

set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/src" && pwd)"

# ---------------------------------------------------------------------------
# Arguments
# ---------------------------------------------------------------------------
TARGET=""
COUNTER="heuristic"
HYGIENE_DIR=".context-hygiene"
WITH_LINT=true
WITH_AUDIT_SKILL=false
INSTALL_HOOKS=false
FORCE=false

usage() { sed -n '2,38p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

while [[ $# -gt 0 ]]; do
    case "$1" in
        --target-repo)      TARGET="$2"; shift 2 ;;
        --counter)          COUNTER="$2"; shift 2 ;;
        --hygiene-dir)      HYGIENE_DIR="$2"; shift 2 ;;
        --with-lint)        WITH_LINT=true; shift ;;
        --no-lint)          WITH_LINT=false; shift ;;
        --with-audit-skill) WITH_AUDIT_SKILL=true; shift ;;
        --install-hooks)    INSTALL_HOOKS=true; shift ;;
        --force)            FORCE=true; shift ;;
        -h|--help)          usage; exit 0 ;;
        *) echo "Unknown flag: $1" >&2; echo "Try --help" >&2; exit 1 ;;
    esac
done

if [[ -z "$TARGET" ]]; then
    echo "Error: --target-repo is required." >&2
    echo "Try --help" >&2
    exit 1
fi
if [[ ! -d "$TARGET" ]]; then
    echo "Error: target repo not found: $TARGET" >&2
    exit 1
fi

case "$COUNTER" in
    heuristic|tiktoken|anthropic) ;;
    *) echo "Error: --counter must be heuristic, tiktoken, or anthropic (got: $COUNTER)" >&2
       exit 1 ;;
esac

HYGIENE_DIR="${HYGIENE_DIR#/}"; HYGIENE_DIR="${HYGIENE_DIR%/}"
if [[ -z "$HYGIENE_DIR" ]]; then
    echo "Error: --hygiene-dir must not be empty." >&2
    exit 1
fi

# --- Resolve the target's root ----------------------------------------------
# Primary: git toplevel, which for a LINKED WORKTREE returns the worktree root
# (e.g. .../ai-builder/main), not the .bare container. Fallback: walk up for a
# repo marker. `.git` may be a FILE (a worktree's `gitdir:` pointer) or a
# DIRECTORY — `-e` matches both; a `-d` test would silently miss every worktree.
TARGET="$(cd "$TARGET" && pwd)"
IS_GIT=true
if ROOT="$(git -C "$TARGET" rev-parse --show-toplevel 2>/dev/null)" && [[ -n "$ROOT" ]]; then
    TARGET="$ROOT"
else
    IS_GIT=false
    dir="$TARGET"
    while [[ -n "$dir" && "$dir" != "/" ]]; do
        if [[ -e "$dir/.git" || -e "$dir/.context-budget.toml" ]]; then
            TARGET="$dir"; break
        fi
        dir="$(dirname "$dir")"
    done
fi

if [[ "$IS_GIT" != true ]]; then
    echo "Note: $TARGET is not a git repo. The checkers fall back to a walk-up"
    echo "      root search, which works, but hooks and CI need 'git init'."
fi

MOUNT="$TARGET/$HYGIENE_DIR"
PY="$(command -v python3 || command -v python)" || {
    echo "Error: python3 is required (the checkers are Python; see docs/hygiene-design.md §7)." >&2
    exit 1
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
created=(); updated=(); skipped=()

# render <src> <dst> — copy with GENERATOR-TIME placeholders substituted.
render() {
    sed -e "s|{{HYGIENE_DIR}}|$HYGIENE_DIR|g" \
        -e "s|{{COUNTER}}|$COUNTER|g" \
        -e "s|{{HOOK_COUNTER}}|$HOOK_COUNTER|g" \
        -e "s|{{CI_DEPS}}|$CI_DEPS|g" \
        "$1" > "$2"
}

# The hook must stay offline and instant, so it never uses the API counter even
# when that is what CI is pinned to.
HOOK_COUNTER="$COUNTER"
[[ "$COUNTER" == "anthropic" ]] && HOOK_COUNTER="heuristic"

case "$COUNTER" in
    tiktoken)  CI_DEPS='          python -m pip install tiktoken' ;;
    anthropic) CI_DEPS='          python -m pip install anthropic' ;;
    *)         CI_DEPS='          echo "heuristic counter: no dependencies beyond the standard library"' ;;
esac

# ours <file> — was this file written by this generator?
ours() { [[ -f "$1" ]] && grep -qF "create-context-hygiene" "$1"; }

echo "Installing context-hygiene"
echo "  target  : $TARGET"
echo "  mount   : $HYGIENE_DIR/"
echo "  counter : $COUNTER"
echo ""

# ---------------------------------------------------------------------------
# 1. MACHINERY — the checkers (always overwritten)
# ---------------------------------------------------------------------------
mkdir -p "$MOUNT"
cp "$SRC_DIR/checkers/hygiene_env.py"  "$MOUNT/"
cp "$SRC_DIR/checkers/count_tokens.py" "$MOUNT/"
cp "$SRC_DIR/checkers/check_budget.py" "$MOUNT/"
if [[ "$WITH_LINT" == true ]]; then
    cp "$SRC_DIR/checkers/context_lint.py" "$MOUNT/"
    updated+=("$HYGIENE_DIR/  (count_tokens, check_budget, context_lint)")
else
    rm -f "$MOUNT/context_lint.py"
    updated+=("$HYGIENE_DIR/  (count_tokens, check_budget — lint not installed)")
fi
chmod +x "$MOUNT"/*.py

# The checkers import each other, so Python caches bytecode beside them. Without
# this the first run after install leaves .pyc files staged into the target's
# next commit.
printf '__pycache__/\n*.pyc\n' > "$MOUNT/.gitignore"

# ---------------------------------------------------------------------------
# 2. MACHINERY — the placement rubric
# ---------------------------------------------------------------------------
# A reference doc, so it goes where a human will find it — not inside the hidden
# machinery directory. The hook and the audit skill both point at this path.
mkdir -p "$TARGET/docs"
PLACEMENT="$TARGET/docs/PLACEMENT.md"
if [[ -f "$PLACEMENT" ]] && ! ours "$PLACEMENT" && [[ "$FORCE" != true ]]; then
    skipped+=("docs/PLACEMENT.md  (exists and is not ours — preserved; use --force to overwrite)")
else
    cp "$SRC_DIR/docs/PLACEMENT.md" "$PLACEMENT"
    updated+=("docs/PLACEMENT.md  (placement rubric)")
fi

# ---------------------------------------------------------------------------
# 3. CONTENT — the budget manifest, seeded from the target's current counts
# ---------------------------------------------------------------------------
# Budgets derived from what the repo already loads start realistic, which is the
# difference between a check that gets adopted and one that gets switched off on
# its first run. --init preserves an existing file unless --force.
INIT_ARGS=(--root "$TARGET" --init --counter "$COUNTER"
           --template "$SRC_DIR/config/.context-budget.toml.in")
[[ "$FORCE" == true ]] && INIT_ARGS+=(--force)
"$PY" "$MOUNT/check_budget.py" "${INIT_ARGS[@]}"
echo ""

# ---------------------------------------------------------------------------
# 4. Optional — the LLM audit skill
# ---------------------------------------------------------------------------
if [[ "$WITH_AUDIT_SKILL" == true ]]; then
    SKILL_OUT="$TARGET/.claude/skills/context-audit"
    mkdir -p "$SKILL_OUT"
    cp "$SRC_DIR/skill/context-audit/SKILL.md" "$SKILL_OUT/SKILL.md"
    updated+=(".claude/skills/context-audit/SKILL.md  (periodic LLM audit)")
fi

# ---------------------------------------------------------------------------
# 5. Optional — enforcement surfaces
# ---------------------------------------------------------------------------
if [[ "$INSTALL_HOOKS" == true ]]; then
    if [[ "$IS_GIT" != true ]]; then
        skipped+=("hooks + CI  (target is not a git repo — run 'git init' and re-run)")
    else
        # A worktree's hooks live in the shared common dir, so ask git rather
        # than assuming $TARGET/.git/hooks.
        HOOKS_DIR="$(git -C "$TARGET" rev-parse --git-path hooks)"
        [[ "$HOOKS_DIR" = /* ]] || HOOKS_DIR="$TARGET/$HOOKS_DIR"
        mkdir -p "$HOOKS_DIR"
        HOOK="$HOOKS_DIR/pre-commit"
        if [[ -f "$HOOK" ]] && ! ours "$HOOK" && [[ "$FORCE" != true ]]; then
            skipped+=("$(basename "$HOOKS_DIR")/pre-commit  (a different pre-commit hook exists — preserved; call our checks from it, or use --force)")
        else
            render "$SRC_DIR/hooks/pre-commit.in" "$HOOK"
            chmod +x "$HOOK"
            updated+=("pre-commit hook  (offline counter: $HOOK_COUNTER)")
        fi

        mkdir -p "$TARGET/.github/workflows"
        CI="$TARGET/.github/workflows/context-hygiene.yml"
        if [[ -f "$CI" ]] && ! ours "$CI" && [[ "$FORCE" != true ]]; then
            skipped+=(".github/workflows/context-hygiene.yml  (exists and is not ours — preserved; use --force)")
        else
            render "$SRC_DIR/hooks/context-hygiene.yml.in" "$CI"
            updated+=(".github/workflows/context-hygiene.yml  (counter: $COUNTER)")
        fi

        if [[ "$COUNTER" == "anthropic" ]]; then
            skipped+=("CI needs an ANTHROPIC_API_KEY secret — the anthropic counter fails loudly without one")
        fi
    fi
fi

# ---------------------------------------------------------------------------
# 6. Summary
# ---------------------------------------------------------------------------
echo "Written:";   for i in "${updated[@]:-}"; do [[ -n "$i" ]] && echo "  ~ $i"; done
if [[ ${#created[@]} -gt 0 ]]; then
    echo "Created:"; for i in "${created[@]:-}"; do [[ -n "$i" ]] && echo "  + $i"; done
fi
if [[ ${#skipped[@]} -gt 0 ]]; then
    echo "Notes:";   for i in "${skipped[@]:-}"; do [[ -n "$i" ]] && echo "  = $i"; done
fi

echo ""
echo "Layers: lint=$WITH_LINT audit-skill=$WITH_AUDIT_SKILL hooks=$INSTALL_HOOKS"
echo ""
echo "Next:"
echo "  python3 $HYGIENE_DIR/check_budget.py            # the report"
[[ "$WITH_LINT" == true ]] && \
echo "  python3 $HYGIENE_DIR/context_lint.py            # what belongs elsewhere"
echo "  \$EDITOR .context-budget.toml                    # ratchet the budgets down"
echo "  docs/PLACEMENT.md                              # where things go"
echo ""
echo "--- current state ---"
"$PY" "$MOUNT/check_budget.py" --root "$TARGET" || true

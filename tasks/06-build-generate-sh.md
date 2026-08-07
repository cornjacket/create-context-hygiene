# Task 06 — Build `generate.sh` + enforcement wiring

**Goal:** the emitter that installs the toolkit into a target repo and wires it
into pre-commit + CI. Design §7, §2.4.

## Contract

```sh
generate.sh \
    --target-repo <path>                        # required
    --counter <heuristic|tiktoken|anthropic>    # default heuristic
    [--with-lint]                               # default on
    [--with-audit-skill]
    [--install-hooks]                           # pre-commit + CI
    [--force]
```

## Steps

- [x] Parse flags; validate/root-resolve target (git-workspace + worktree).
- [x] Copy `src/checkers/` into the target (e.g. `.context-hygiene/`).
- [x] Render `.context-budget.toml` from the `.in` template; run `check_budget
      --init` against the target so budgets seed from its current counts.
- [x] Copy `PLACEMENT.md`; copy the audit skill only if `--with-audit-skill`.
- [x] With `--install-hooks`: install `pre-commit` (offline counter: budget +
      lint on staged always-on files) and a CI workflow (may use `anthropic`
      counter, authoritative, non-skippable).
- [x] Print a post-install summary + the first `check_budget` report.

## Done when

`generate.sh --target-repo <scratch> --install-hooks` yields a working toolkit:
the hook blocks an over-budget commit; CI runs the same checks.

**Status:** done and verified end-to-end in a scratch repo — a clean commit
passes with a one-line summary, and appending a fat section to CLAUDE.md blocks
the commit with the numbers and the section that caused it. Re-running the
generator over a live install is a **zero-line diff**, so upgrading never needs
`--force`.

Two decisions worth carrying into task 13:

- The hook forces an **offline** counter even when the target is pinned to
  `anthropic`, so committing never needs a network round-trip or a key. CI uses
  the configured counter.
- The seeded config ships `lint.warn_only = true`. On install day every finding
  is pre-existing, and a check that blocks the first commit gets switched off
  rather than acted on. Size gates from day one; placement reports until the
  backlog is cleared. Task 13 should decide whether that flip is ever forced.

Ref: `docs/hygiene-design.md` §7, §2.4.

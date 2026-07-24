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

- [ ] Parse flags; validate/root-resolve target (git-workspace + worktree).
- [ ] Copy `src/checkers/` into the target (e.g. `.context-hygiene/`).
- [ ] Render `.context-budget.toml` from the `.in` template; run `check_budget
      --init` against the target so budgets seed from its current counts.
- [ ] Copy `PLACEMENT.md`; copy the audit skill only if `--with-audit-skill`.
- [ ] With `--install-hooks`: install `pre-commit` (offline counter: budget +
      lint on staged always-on files) and a CI workflow (may use `anthropic`
      counter, authoritative, non-skippable).
- [ ] Print a post-install summary + the first `check_budget` report.

## Done when

`generate.sh --target-repo <scratch> --install-hooks` yields a working toolkit:
the hook blocks an over-budget commit; CI runs the same checks.

Ref: `docs/hygiene-design.md` §7, §2.4.

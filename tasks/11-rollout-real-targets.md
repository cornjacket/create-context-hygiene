# Task 11 — Roll out to real targets (later)

**Goal:** install the hygiene toolkit into the real repos, once validated against
fixtures.

**Do not start until tasks 07–09 pass.**

## Targets & order

- [ ] **ai-builder** — the motivating case (bloated CLAUDE.md). Install checkers +
      hooks; run budget/lint; use the report to drive the CLAUDE.md → kernel/skill
      split (pairs with `create-project-system` task 03b, which extracts the task
      skill). Test under both git layouts (ai-builder is a worktree).
- [ ] **second-brain** — already uses a pre-commit size hook; reconcile: replace
      or complement it with the token-based budget checker. Confirm before
      changing existing hooks.
- [ ] **captains-log** — install checkers + hooks.

## Per target

- [ ] Confirm which always-on files go in the manifest (CLAUDE.md + `@`-imports +
      memory index).
- [ ] Seed budgets from current counts, then tighten.
- [ ] Record the generation command for re-runs/upgrades.

## Done when

Each target has the toolkit installed, budgets enforced in CI, and its generation
command recorded.

Ref: `docs/hygiene-design.md`; composes with `create-project-system`.

# Task 03 — Budget checker (per-file, per-section, total manifest)

**Goal:** enforce token budgets at three levels and report the real always-on
tax. Design §2.2–§2.4.

## Steps

- [ ] `src/checkers/check_budget.py` reads `.context-budget.toml` and, per
      `always_on` entry, counts tokens (via task 02's counter).
- [ ] **Per-section:** split each file into a section tree by `^#{1,6} ` headings
      (simple line splitter, no full AST); count tokens per section; enforce
      `max_section`; report `section path → tokens → % of budget`.
- [ ] **Per-file:** enforce each entry's `budget`.
- [ ] **Total always-on:** sum all entries; enforce `total_ceiling`.
- [ ] **Auto-discover `@`-imports:** scan CLAUDE.md for `@path` references and
      fold those files into the total (hidden tax a per-file check misses).
- [ ] **Warn at `warn_pct`, fail at `fail_pct`**; exit non-zero on fail.
- [ ] Output: human-readable table + `--json` for CI.
- [ ] Seed helper: `--init` writes a starter `.context-budget.toml` with budgets
      derived from the target's *current* counts (so budgets start realistic).

## Done when

Running against a repo prints a per-file/per-section/total report, flags
over-budget sections with their %s, and exits non-zero past the fail threshold.

Ref: `docs/hygiene-design.md` §2.2–§2.4.

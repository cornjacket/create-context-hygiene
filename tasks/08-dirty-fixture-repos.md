# Task 08 — Dirty fixture repos (clean & organize targets)

**Goal:** build deliberately **bloated** test repos the generator installs into,
to prove the checkers flag the right things and, later (task 10), that the
assisted reorg cleans them. These are the "sandboxed test repos the generator
cleans and organizes." Design §8.

## Steps

- [ ] Create `tests/fixtures/` with 2–3 dirty targets, e.g.:
      - [ ] `fat-claude-md/` — a CLAUDE.md that mirrors ai-builder's shape
            (~300 lines of always-on procedure, oversized `## Task Management`
            section, embedded script blocks, big tables).
      - [ ] `at-import-tax/` — a lean-looking CLAUDE.md that `@`-imports several
            heavy docs (hidden always-on tax).
      - [ ] `clean/` — a control that should pass with zero findings.
- [ ] Record **expected results** per fixture: total tokens, over-budget
      sections, lint findings + suggested buckets.
- [ ] A runner installs the toolkit into each fixture and diffs actual vs
      expected reports.

## Note on realism

Prefer anonymized/synthetic content over copying private repos wholesale; the
`fat-claude-md` fixture should *resemble* ai-builder's structure, not vendor it.

## Done when

Each fixture's checker output matches its recorded expectation; `clean/` passes,
the dirty ones fail with the predicted findings.

Ref: `docs/hygiene-design.md` §8; feeds task 09 (golden) and task 10 (reorg).

# Task 05 — Placement rubric + optional LLM audit

**Goal:** productize the *decision* (what goes always-on vs skill vs reference)
and add the judgment-half audit heuristics can't do. Design §4–§5.

## Part A — `PLACEMENT.md` rubric (mechanical anchor)

- [x] Write `src/docs/PLACEMENT.md` — three buckets, each with its test:
      - **Always-on kernel:** "if only loaded on demand, too late?" → yes.
      - **On-demand skill:** "only needed while doing task X?" → yes.
      - **Reference:** "consulted, not obeyed?" → yes.
- [x] Encode the smell→bucket mapping the lint (task 04) consumes.

## Part B — LLM audit skill (optional, `--with-audit-skill`)

- [x] `src/skill/context-audit/SKILL.md` — reads the always-on set and reports:
      sections that are procedural (→ skill), duplicate an existing skill, or are
      stale / never-cited.
- [x] **Recommends, never auto-edits** — output is a review list, human approves.
- [x] Meant to run periodically, not per-commit.

## Done when

`PLACEMENT.md` states the rule the lint enforces, and the audit skill produces a
recommendation list against a sample repo without modifying any file.

**Status:** `PLACEMENT.md` ships and carries the smell→bucket table the lint
consumes, so the rubric and the code agree by construction. The audit skill is
written and emitted under `--with-audit-skill`; it has **not** been exercised by
an actual agent run against a sample repo — its "recommends, never edits"
contract is stated, not yet demonstrated. Worth doing as part of task 10, where
the assisted reorganization needs the same judgement.

Ref: `docs/hygiene-design.md` §4, §5; `claude-api` skill.

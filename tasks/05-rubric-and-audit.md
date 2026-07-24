# Task 05 — Placement rubric + optional LLM audit

**Goal:** productize the *decision* (what goes always-on vs skill vs reference)
and add the judgment-half audit heuristics can't do. Design §4–§5.

## Part A — `PLACEMENT.md` rubric (mechanical anchor)

- [ ] Write `src/docs/PLACEMENT.md` — three buckets, each with its test:
      - **Always-on kernel:** "if only loaded on demand, too late?" → yes.
      - **On-demand skill:** "only needed while doing task X?" → yes.
      - **Reference:** "consulted, not obeyed?" → yes.
- [ ] Encode the smell→bucket mapping the lint (task 04) consumes.

## Part B — LLM audit skill (optional, `--with-audit-skill`)

- [ ] `src/skill/context-audit/SKILL.md` — reads the always-on set and reports:
      sections that are procedural (→ skill), duplicate an existing skill, or are
      stale / never-cited.
- [ ] **Recommends, never auto-edits** — output is a review list, human approves.
- [ ] Meant to run periodically, not per-commit.

## Done when

`PLACEMENT.md` states the rule the lint enforces, and the audit skill produces a
recommendation list against a sample repo without modifying any file.

Ref: `docs/hygiene-design.md` §4, §5; `claude-api` skill.

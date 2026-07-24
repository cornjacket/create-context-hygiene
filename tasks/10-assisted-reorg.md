# Task 10 — LLM-assisted reorganization (later)

**Goal:** go beyond detection — propose a concrete refactor of a bloated
`CLAUDE.md` into `kernel + skill(s) + reference`, as a reviewable diff. Design §6.

**Do not start until detection (tasks 03–05) and fixtures (task 08) are solid.**

## Steps

- [ ] A command/skill that, given an always-on file + its lint/budget report,
      proposes:
      - [ ] the **kernel** (always-fire rules only, within budget),
      - [ ] extracted **skill(s)** for the procedural blocks,
      - [ ] a **reference** doc for lookup tables,
      - [ ] the pointers that replace the moved content.
- [ ] Emit as a **diff / proposed file set for human review** — never
      auto-applied.
- [ ] Validate against the `fat-claude-md` fixture: post-reorg budget check
      passes and no procedural smells remain in the kernel.
- [ ] Guardrail: the reorg must not drop any always-fire rule — diff the rule set
      before/after.

## Done when

Running against `fat-claude-md` produces a proposed split whose kernel passes
budget + lint, with the always-fire rule set provably preserved.

Ref: `docs/hygiene-design.md` §6.

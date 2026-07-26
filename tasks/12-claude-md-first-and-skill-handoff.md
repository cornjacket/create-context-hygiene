# Task 12 — CLAUDE.md as the first target + skill handoff

**Relocated from create-project-system** (where it seeded as "context hygiene for
CLAUDE.md specifically"), because this is create-context-hygiene's domain. It is
**not** a new generic capability — tasks
[`03`](03-budget-checker.md) (budgets), [`04`](04-context-lint.md)
(procedural-smell lint), [`05`](05-rubric-and-audit.md) (placement rubric), and
[`10`](10-assisted-reorg.md) (CLAUDE.md → kernel/skill/reference split) already
build the machinery. This task adds the two things those don't cover.

## Why this exists (the two additive points)

1. **CLAUDE.md is the priority real-world target.** It's always-on context — every
   line is paid on every turn — so it's where the budget (03) + smell lint (04) +
   rubric (05) pay off first. Make CLAUDE.md the headline worked example for the
   tooling, not just one file among many in the rollout (11).

2. **Handoff to the task-system skill.** When the rubric (05) / reorg (10) decide
   task-usage procedure should *leave* CLAUDE.md, it doesn't just vanish — it lands
   in create-project-system's **`task-system` skill** (see that repo's task 16:
   "make the skill the primary usage vehicle"). The two generators compose at a
   target repo: context-hygiene decides *what leaves CLAUDE.md*; the task-system
   skill is *where task directives go*. Kernel stays; procedure → skill; reference
   → USING.md.

## Scope

- [ ] Point tasks 03/04/05 at CLAUDE.md as the first-class example; ensure the
      budget manifest and smell lint produce a useful report for a real CLAUDE.md
      (worked example: create-ai-builder's oversized one).
- [ ] Define the **placement targets** the rubric emits for CLAUDE.md content:
      *kernel* (stay), *skill* (on-demand procedure), *reference* (USING.md / docs).
- [ ] Document the create-project-system handoff: procedure flagged for removal
      from CLAUDE.md maps to the emitted `task-system` skill, not a new home.
- [ ] Coordinate with create-project-system task 16 so the split has a landing zone.

## Done when

The hygiene tooling (03/04/05/10) treats CLAUDE.md as its headline target and
emits kernel/skill/reference placement, and the "→ skill" destination is wired to
create-project-system's task-system skill.

# PLAN — Build the Context-Hygiene Generator

**Goal:** build `create-context-hygiene`, a generator that installs a
context-hygiene toolkit into any target repo — keeping agent-facing instruction
files (`CLAUDE.md`, `@`-imports, skills, memory index) **small** (token budgets)
and **well-placed** (placement rubric + procedural-smell lint + LLM audit), and
able to **clean and organize** repos whose instructions have ballooned.

**Design reference:** [`docs/hygiene-design.md`](docs/hygiene-design.md) — the
"how" for token budgeting, per-section/total-manifest budgets, `context-lint`,
the placement rubric, the LLM audit, and the generator contract.

**Peer, not parent:** orthogonal to `create-project-system` over a shared generator
substrate (copied, not shared-lib — see design §7). The two compose at a target
but neither depends on the other *at runtime*.

**Cross-repo build ordering:** there IS a one-time *build* dependency —
task 01 copies the generator substrate (`generate.sh`, root resolution, golden
harness, `sandbox/` self-test) **from `create-project-system`**. So build
`create-project-system`'s substrate first (its tasks 01, 04, 04b), then start here.
This is a copy-once dependency, not a runtime one; promote to a shared lib only if
a third generator appears.

**Core stance:** the currency is **tokens loaded per turn**, not lines. Every
check measures tokens via a pluggable counter (heuristic default, `tiktoken`
optional, `anthropic` exact) — design §2.

---

## Repo layout (target end state)

```
create-context-hygiene/
    PLAN.md                 ← this file
    generate.sh             ← the emitter (task 06)
    src/
        checkers/           ← count-tokens, check-budget, context-lint (tasks 02–04)
        config/.context-budget.toml.in
        docs/PLACEMENT.md   ← placement rubric (task 05)
        skill/context-audit/SKILL.md   ← optional LLM audit (task 05)
        hooks/pre-commit.in + CI template (task 06)
    sandbox/                ← disposable self-test target (git-ignored, task 07)
    tasks/                  ← build work-items (this plan)
    docs/                   ← design docs
```

---

## Tasks (in order)

1. [ ] [`01-scaffold-src.md`](tasks/01-scaffold-src.md) — `src/` layout + copy the generator substrate from `create-project-system`.
2. [ ] [`02-token-counter.md`](tasks/02-token-counter.md) — pluggable token counter (heuristic / tiktoken / anthropic).
3. [ ] [`03-budget-checker.md`](tasks/03-budget-checker.md) — per-file, per-section, and total-manifest budgets + `.context-budget.toml`.
4. [ ] [`04-context-lint.md`](tasks/04-context-lint.md) — procedural-smell detector.
5. [ ] [`05-rubric-and-audit.md`](tasks/05-rubric-and-audit.md) — `PLACEMENT.md` rubric + optional LLM audit skill.
6. [ ] [`06-build-generate-sh.md`](tasks/06-build-generate-sh.md) — `generate.sh` + pre-commit/CI wiring.
7. [ ] [`07-self-test-sandbox.md`](tasks/07-self-test-sandbox.md) — self-test into a disposable in-repo `sandbox/`.
8. [ ] [`08-dirty-fixture-repos.md`](tasks/08-dirty-fixture-repos.md) — sandboxed bloated test repos the generator cleans & organizes.
9. [ ] [`09-golden-test.md`](tasks/09-golden-test.md) — reproducibility test.
10. [ ] [`10-assisted-reorg.md`](tasks/10-assisted-reorg.md) — LLM-assisted CLAUDE.md → kernel/skill/reference split (later).
11. [ ] [`11-rollout-real-targets.md`](tasks/11-rollout-real-targets.md) — install into ai-builder, second-brain, captains-log (later).
12. [ ] [`12-claude-md-first-and-skill-handoff.md`](tasks/12-claude-md-first-and-skill-handoff.md) — CLAUDE.md as the priority target + handoff to create-project-system's task-system skill. Builds on 03/04/05/10.

Mark a task `[x]` here when its task file's checklist is fully done.

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
    requirements.txt        ← optional counter deps; the default path needs none
    src/
        checkers/           ← hygiene_env, count_tokens, check_budget, context_lint
        config/.context-budget.toml.in
        docs/PLACEMENT.md   ← placement rubric (task 05)
        skill/context-audit/SKILL.md   ← optional LLM audit (task 05)
        hooks/pre-commit.in + context-hygiene.yml.in (task 06)
    tests/run.sh + tests/golden/   ← reproducibility test (harness from task 01)
    sandbox/                ← disposable self-test target (git-ignored, task 07)
    tasks/                  ← build work-items (this plan)
    docs/                   ← design docs
```

**What a target gets:** `.context-hygiene/` (the checkers, vendored so a fresh
clone works with no install step), a seeded `.context-budget.toml`, and
`docs/PLACEMENT.md`. Optionally `.claude/skills/context-audit/`, a `pre-commit`
hook, and `.github/workflows/context-hygiene.yml`.

---

## Tasks (in order)

1. [x] [`01-scaffold-src.md`](tasks/01-scaffold-src.md) — `src/` layout + copy the generator substrate from `create-project-system`.
2. [x] [`02-token-counter.md`](tasks/02-token-counter.md) — pluggable token counter (heuristic / tiktoken / anthropic). *One step open: the calibration run needs an API key — see the task file.* **Calibration deferred until the pilot (14) reports.**
3. [x] [`03-budget-checker.md`](tasks/03-budget-checker.md) — per-file, per-section, and total-manifest budgets + `.context-budget.toml`.
4. [x] [`04-context-lint.md`](tasks/04-context-lint.md) — procedural-smell detector.
5. [x] [`05-rubric-and-audit.md`](tasks/05-rubric-and-audit.md) — `PLACEMENT.md` rubric + optional LLM audit skill.
6. [x] [`06-build-generate-sh.md`](tasks/06-build-generate-sh.md) — `generate.sh` + pre-commit/CI wiring.
7. [x] [`07-self-test-sandbox.md`](tasks/07-self-test-sandbox.md) — self-test into a disposable in-repo `sandbox/`. *41 assertions, both git layouts.*
8. [ ] **Deferred until the pilot (14) reports.** [`08-dirty-fixture-repos.md`](tasks/08-dirty-fixture-repos.md) — sandboxed bloated test repos the generator cleans & organizes.
9. [ ] **Deferred until the pilot (14) reports.** [`09-golden-test.md`](tasks/09-golden-test.md) — reproducibility test.
10. [ ] **Deferred until the pilot (14) reports.** [`10-assisted-reorg.md`](tasks/10-assisted-reorg.md) — LLM-assisted CLAUDE.md → kernel/skill/reference split (later).
11. [ ] **Deferred until the pilot (14) reports.** [`11-rollout-real-targets.md`](tasks/11-rollout-real-targets.md) — install into ai-builder, second-brain, captains-log (later).
12. [ ] **Deferred until the pilot (14) reports.** [`12-claude-md-first-and-skill-handoff.md`](tasks/12-claude-md-first-and-skill-handoff.md) — CLAUDE.md as the priority target + handoff to create-project-system's task-system skill. Builds on 03/04/05/10.
13. [ ] **Deferred until the pilot (14) reports.** [`13-ci-is-the-authority.md`](tasks/13-ci-is-the-authority.md) — CI is the gate, so it cannot be opt-in: flip `--install-hooks` to default-on with an opt-out, define what the workflow actually runs and how it fails, and declare the check in whatever single manifest `create-project-system` `28` and the `mail` effort settle on. The pre-commit hook is bypassable with `--no-verify`, so it can only ever be the warning. Builds on 03/04/06.
14. [ ] [`14-pilot-install.md`](tasks/14-pilot-install.md) — install the toolkit into one real repo and act on what it reports. **Next.** Target: the `dev-workspace` wrapper.

Mark a task `[x]` here when its task file's checklist is fully done.

## Where this stands

Tasks 01–07 are built. The toolkit installs, measures, lints, and gates. The
self-test (07) proves it in a disposable sandbox. No real repo carries it yet.

The first real reading, from `create-ai-builder`'s `CLAUDE.md`: **6,576 tokens
loaded every turn**, 542 lines, with a single `### Summary` section at 1,531 of
them. That is the motivating case in design §6 with a number attached, and it is
the target for task 11.

## Sequence from here

**Decision (user, 2026-11-17): pilot install before more hardening.** The
numbered list above is the *build* order. It is not the order to work in.

1. ~~**07 — self-test.**~~ Done.
2. **14 — pilot install.** Next. Install the toolkit into one real repo and act
   on what it reports. Target (user, 2026-11-17): the `dev-workspace` wrapper,
   whose `CLAUDE.md` every leader turn pays for.
3. **Deferred until the pilot reports:** task 02's calibration run and tasks
   08–13. Their content is unchanged. After the pilot, review each one against
   the pilot results, then start, change, or drop it.

Notes that still hold for the deferred tasks:

- **09 is roughly half done.** `tests/run.sh` already covers the emitted-tree
  fixtures, drift detection, the pinned `heuristic` counter, and the refresh
  procedure. What remains is golden **report** fixtures (`--json`), which need
  task 08's dirty repos to exist. 09 is a step of 08, not a task beside it.
- **13 has a lead time.** The `discovery.json` merge rule is now settled at the
  workspace (task `229ccb-0000` in `dev-workspace`); see task 13. 13 also has
  two decisions made under it during task 06 (the hook is pinned to an offline
  counter; `lint.warn_only` ships true). It should ratify or overturn them
  rather than rediscover them.

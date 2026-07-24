# create-context-hygiene

A **generator** that installs a context-hygiene toolkit into any target repo. It
keeps agent-facing instruction files (`CLAUDE.md`, its `@`-imports, skills, the
memory index) **small** (token budgets) and **well-placed** (a placement rubric +
procedural-smell lint + an optional LLM audit), and can help **clean and
organize** a repo whose instructions have already ballooned.

The currency is **tokens loaded per turn**, not lines — every check measures
tokens via a pluggable counter (heuristic default, `tiktoken` optional,
`anthropic` exact).

## What it emits

Into `<target-repo>/.context-hygiene/`: the checkers (`count_tokens`,
`check_budget`, `context_lint`), a seeded `.context-budget.toml` manifest, a
`PLACEMENT.md` rubric, optional audit skill, and pre-commit + CI wiring.

```sh
generate.sh --target-repo <path> [--counter heuristic|tiktoken|anthropic] \
    [--with-lint] [--with-audit-skill] [--install-hooks]
```

## Status

Design + plan stage. See:
- [`PLAN.md`](PLAN.md) — the build plan and ordered task list.
- [`docs/hygiene-design.md`](docs/hygiene-design.md) — the "how" for token
  budgeting, per-section/total-manifest budgets, the lint, the rubric, the audit,
  and the generator contract.
- [`tasks/`](tasks/) — the individual build work-items.

## Related

- [`create-task-system`](../create-task-system) — an orthogonal peer generator
  (installs a Markdown task subsystem). This repo copies its generator substrate;
  the two compose at a target — the hygienist measures the kind of instruction
  content the task system emits.

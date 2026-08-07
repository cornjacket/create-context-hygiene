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

```sh
generate.sh --target-repo <path> [--counter heuristic|tiktoken|anthropic] \
    [--with-lint | --no-lint] [--with-audit-skill] [--install-hooks] [--force]
```

| Path in the target | What it is |
|---|---|
| `.context-hygiene/` | the checkers — `count_tokens`, `check_budget`, `context_lint` |
| `.context-budget.toml` | the always-on manifest, **seeded from the target's own counts** so the budgets start realistic |
| `docs/PLACEMENT.md` | the three-bucket rubric the lint enforces |
| `.claude/skills/context-audit/` | the periodic LLM audit (`--with-audit-skill`) |
| `pre-commit` + `.github/workflows/` | enforcement (`--install-hooks`) |

The checkers are **vendored, not depended on**: a fresh clone runs them with no
install step, on the standard library alone. `tiktoken` and `anthropic` are
optional and only buy a more accurate count.

Machinery is always overwritten and your `.context-budget.toml` never is, so
re-running the generator over a live install is a zero-line diff — upgrading
does not need `--force`.

## Where enforcement sits

The pre-commit hook uses an offline counter and runs in milliseconds, so it
costs nothing and needs no key — but `git commit --no-verify` is one flag, which
makes it the fast warning rather than the gate. CI runs the same checks with the
counter the target chose, and is the thing that actually holds the line.

Size gates from day one; placement starts as a report (`lint.warn_only = true`).
On install day every placement finding is pre-existing, and a check that blocks
the first commit gets switched off rather than acted on.

## What it declares — `discovery.json`

An install also writes its key into **`discovery.json`** at the target repo root:
one file, one fixed name, listing what this repo offers to the outside. A
containing workspace reads it to learn which of its repos are covered, instead of
looking inside each one for a `.context-hygiene/` directory.

This generator owns **one key** and never touches the rest of the file:

```json
{
  "context-hygiene": {
    "version": 1,
    "checkers": ".context-hygiene",
    "budgets": ".context-budget.toml",
    "ci": true
  }
}
```

`ci` is the one a workspace actually cares about: it separates *"checked on every
push"* from *"installed but nothing enforces it"*, which look identical from the
outside otherwise.

Other generators write their own keys into the same file — `create-project-system`
owns `tasks` and `inbox`. The rules: **a generator owns its key and never
rewrites another's**, and the version is **per key**, since different generators
write at different times. See [`tasks/13`](tasks/13-ci-is-the-authority.md).

## Status

The toolkit works end to end: it installs, measures, lints, and gates
(`tasks/01`–`06`). Not yet built: the disposable self-test (`07`), the bloated
fixture repos (`08`), the assisted `CLAUDE.md` split (`10`), and rollout to real
targets (`11`).

First real reading — `create-ai-builder`'s `CLAUDE.md` is **6,576 tokens loaded
on every turn**, one section of which is 1,531. That is the case this repo was
built for.

See:
- [`PLAN.md`](PLAN.md) — the build plan and ordered task list.
- [`docs/hygiene-design.md`](docs/hygiene-design.md) — the "how" for token
  budgeting, per-section/total-manifest budgets, the lint, the rubric, the audit,
  and the generator contract.
- [`tasks/`](tasks/) — the individual build work-items.

## Related

- [`create-project-system`](../create-project-system) — an orthogonal peer generator
  (installs a Markdown task subsystem). This repo copies its generator substrate;
  the two compose at a target — the hygienist measures the kind of instruction
  content the task system emits.

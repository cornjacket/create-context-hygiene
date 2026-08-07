# PLACEMENT — where a piece of agent-facing instruction belongs

Installed by create-context-hygiene. This is a **reference doc**: consulted when
you are deciding where something goes, and by its own rule it must not be
auto-loaded. Point at it from your kernel; do not paste it in.

Two questions get conflated when instruction files grow, and they have different
answers. **Size is mechanical** — token budgets, enforced on every commit.
**Placement is judgement** — this rubric, plus the lint that mechanizes the
easy 80% of it. Solve them separately.

---

## The three buckets

Every piece of instruction goes in exactly one. Each bucket has one test, and
the test is the whole rubric — if you are arguing about the answer, the content
is probably doing two jobs and should be split.

### 1. Always-on kernel — `CLAUDE.md` and its `@`-imports

> **"If this only loaded on demand, would it be too late?"** → yes = kernel.

Invariants, triggers, and safety rules. A rule that fires only *after* you would
have thought to load it is worthless, so it has to be resident.

The kernel is the expensive bucket: everything in it is paid for on every turn,
including the turns that had nothing to do with it. It must stay **tiny** — and
the cost of a kernel rule is not its own length but the length it justifies,
because each addition makes the next one look proportionate.

Belongs here: "never force-push to main"; "commits follow `<domain>(<scope>)`";
"check for an existing task before starting work"; "consult the placement rubric
before adding to this file". Note the last one — a *pointer* is a kernel rule,
and it is how the other two buckets get reached at all.

### 2. On-demand skill — `.claude/skills/<name>/SKILL.md`

> **"Is this only needed while doing task X?"** → yes = skill.

Procedures, workflows, command sequences, the how-to for a subsystem. Only the
one-line description sits in context until the skill is invoked, so a skill is
close to free until it is needed — the whole point of progressive disclosure.

Belongs here: the steps to create and move a task; the release procedure; how to
set up a worktree; anything you would write as a numbered list.

The kernel keeps the **trigger** ("before starting non-trivial work, check for a
task"); the skill keeps the **procedure** (how to create one). Splitting on that
line is the single highest-value move available to a bloated kernel.

### 3. Reference — a separate doc, reached by pointer

> **"Is this consulted, not obeyed?"** → yes = reference.

Lookup data, schemas, field tables, option matrices, design rationale. Nobody
follows a table; they read the one row they need.

Belongs here: the metadata field table; configuration keys; the design doc; this
file.

---

## What the lint flags, and where it sends it

`context_lint.py` detects **shape**, never meaning — these are the smells that
are mechanically visible, mapped to the bucket each one implies. A finding is a
prompt to apply the tests above, not a verdict.

| Smell | Signal | Bucket |
|---|---|---|
| `code-block` | a fenced block in an always-on file | skill \| reference |
| `step-sequence` | ordered list at or past the item threshold | skill |
| `reference-table` | table past the row threshold | reference |
| `command-dump` | a run of shell invocations | skill |
| `oversized-section` | section over `max_section` tokens | split \| move |

Thresholds live in `.context-budget.toml` under `[lint]`.

**Two smells are not two problems.** A section that trips the code-block, step
and command rules at once is one procedure that wants to be one skill.

**A flagged block can still be right.** A three-line fenced example that pins a
commit format is doing kernel work. The lint cannot tell that from a tutorial;
you can. Move it, or leave it and know why.

---

## Moving something out

1. Cut the content into its new home — a skill directory or a reference doc.
2. Leave a **pointer with a trigger** in the kernel, not a summary. "Full
   procedure: the `task-system` skill" beats three condensed bullets, which cost
   tokens every turn and go stale against the real thing.
3. Re-run `check_budget.py`. The number should drop; if it did not, the content
   was duplicated rather than moved.

The failure mode to avoid is the summary that becomes a second source of truth.
One home per fact — the kernel says *where*, not *what*.

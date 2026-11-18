# Task 14 — Pilot install into one real repo

**Goal:** install the toolkit into one real repo, and act on what it reports.
This task comes before any more hardening work.

## Why

Tasks 01–07 built the toolkit and proved it in a disposable sandbox. No real
repo carries it yet. More hardening (tasks 08–13) without a real install
guesses at which problems matter. A pilot shows the real problems first.

**Decision (user, 2026-11-17):** pilot install before more hardening. These
items are deferred until the pilot reports:

- Task 02's calibration run.
- Tasks 08–13.

The deferred tasks keep their content. After the pilot, review each one against
what the pilot found, and then start, change, or drop it.

## Pilot target

**Decision (user, 2026-11-17):** the pilot target is the git-workspace wrapper,
`/Users/david/src/github.com/cornjacket/dev-workspace`.

Reason: its `CLAUDE.md` is long and grows with each leader rule. Every leader
turn pays for it.

## What the target looks like (read 2026-11-17, read only)

- **Allowlist `.gitignore`.** The root rule is `/*`; only listed paths are
  tracked. Today it lists `.workspace/`, `CLAUDE.md`, `.gitignore`,
  `README.md`, `Makefile`, `.claude/`, `.github/`, `summary.md`, and
  `daily-plan-summary.md`. `create-git-workspace`'s `update.sh` owns and
  overwrites this file.
- **`CLAUDE.md` is 195 lines, about 2,639 tokens** (`count_tokens.py`,
  heuristic counter). It has three ownership zones:

  | Lines | Zone | Owner |
  |---|---|---|
  | 1–6, 72–195 | Header comment, then "Leader operating rules" | User |
  | 7–55 | `git-workspace:begin` … `git-workspace:end` | `create-git-workspace` (`update.sh` overwrites) |
  | 57–71 | `task-system:begin` … `task-system:end` | `create-project-system`'s snippet, vendored and written by `create-git-workspace` |

  Line numbers drift as the file changes. Locate zones by marker, not by number.
- **No `@`-imports** in `CLAUDE.md` today.
- **Child repos** (`create-*`, `captains-log`, `second-brain-*`, and others)
  sit inside the wrapper's tree. `.gitignore` keeps them out of its index.
- **An existing `pre-commit` hook** in `.git/hooks/`. `create-git-workspace`'s
  `install-hooks.sh` owns it. It runs `.workspace/scripts/guard.sh`, which
  stops a commit that would add a child repo to the wrapper's index.
- **Existing workflows** in `.github/workflows/`: `auto-merge-status.yml` and
  `claude.yml`.

## How the toolkit meets each constraint

### 1. The allowlist `.gitignore`

A full install writes these paths. Without new `!` lines, git ignores all but
the last two:

| Path `generate.sh` writes | Tracked today? |
|---|---|
| `.context-hygiene/` (checkers) | No |
| `.context-budget.toml` | No |
| `docs/PLACEMENT.md` | No |
| `.claude/skills/context-audit/` (`--with-audit-skill`) | Yes, `!/.claude/` |
| `.github/workflows/context-hygiene.yml` (`--install-hooks`) | Yes, `!/.github/` |

The untracked files would still work on this machine. But CI checks out the
repo without them, and a fresh clone has no checkers. So the install is not
real until the `!` lines exist. The fix goes in `create-git-workspace`'s
`.gitignore` template, not a hand edit in `dev-workspace`. A hand edit is lost
on the next `update.sh`.

The existing `__pycache__/` rule already covers the checkers' bytecode.

### 2. Managed blocks in `CLAUDE.md`

The checkers do not know about managed blocks. They report findings by section
heading and line number. So in the pilot, sort each finding by hand:

1. Find the line of the finding.
2. Find which marker pair, if any, contains that line.
3. Route the finding:
   - Inside `git-workspace:*` → `create-git-workspace`.
   - Inside `task-system:*` → `create-project-system` (the snippet source).
     `create-git-workspace` vendors it, so it also needs a vendor refresh.
   - Outside both → the user. Act on it in `dev-workspace`.

Per-file and total budgets cover the whole file. A total over budget can come
from any zone. Report the token count of each zone with the total, so the
owner of the biggest zone is clear.

Record "the checkers do not attribute findings to managed blocks" as a toolkit
problem from this pilot.

### 3. Child repos must not be counted

The checkers do not walk the directory tree. They read only:

- the paths listed in `.context-budget.toml` under `[[always_on]]`, and
- the files those paths pull in with `@path`, resolved from the file's folder
  or the root.

`check_budget.py --init` seeds the manifest only from fixed root paths
(`CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, `MEMORY.md`, `.claude/CLAUDE.md`). So
child repos are not counted unless one of these happens:

- someone adds a child path to `[[always_on]]`, or
- the wrapper's `CLAUDE.md` gets an `@`-import into a child repo.

Neither is true today. The pilot checks it: no path in the report may start
with a child repo name.

Root resolution: the checkers use `git rev-parse --show-toplevel`. Run from
inside a child repo, that returns the child, not the wrapper. Always pass
`--root /Users/david/src/github.com/cornjacket/dev-workspace` in the pilot.

### 4. A read-only first pass

**The toolkit does not support a read-only pass in place.** `check_budget.py`
and `context_lint.py` read their manifest only from
`<root>/.context-budget.toml`, and there is no `--config` flag. With no
manifest, both stop with exit code 2. `--init` writes the manifest into the
target.

Two read-only routes work without a code change:

- `count_tokens.py <file>` counts any file and needs no manifest. Used above
  for the 2,639 figure.
- **Scratch copy.** Copy `CLAUDE.md` into a temp directory and run the
  checkers there. The target has no `@`-imports today, so the copy is complete.

Record "no read-only mode" as a toolkit problem from this pilot. A
`--config <path>` flag would make the pass possible in place.

## Pilot plan

### Phase A — read-only pass (no writes in `dev-workspace`)

1. Make a scratch directory outside `dev-workspace`, for example
   `$(mktemp -d)`.
2. Copy `dev-workspace/CLAUDE.md` into it.
3. Seed a manifest in the scratch directory:
   `python3 -I src/checkers/check_budget.py --root <scratch> --init`.
4. Run the budget check:
   `python3 -I src/checkers/check_budget.py --root <scratch> --all-sections`.
   Save the `--json` output too.
5. Run the lint:
   `python3 -I src/checkers/context_lint.py --root <scratch> --warn-only`.
   Save the `--json` output too.
6. Sort every finding into a zone (constraint 2). Count the tokens in each zone.
7. Record in this file: the total, the seeded budgets, each zone's tokens, and
   each finding with its owner.
8. Confirm `git -C dev-workspace status --short` is unchanged.
9. Show the results to the user before Phase B.

### Phase B — change in `create-git-workspace` (prerequisite for an install)

Work in `create-git-workspace`, by a child session for that repo, not by this
task:

1. Add `!` lines for `.context-hygiene/`, `.context-budget.toml`, and
   `docs/PLACEMENT.md` (or the paths the user chooses, see decisions) to the
   `.gitignore` template.
2. Decide how its `pre-commit` hook and this toolkit's hook coexist (see
   decisions).
3. Run its `update.sh` against `dev-workspace` and commit there.

### Phase C — install into `dev-workspace`

Only after Phase B lands and the user approves the flags:

1. Run `generate.sh --target-repo /Users/david/src/github.com/cornjacket/dev-workspace`
   with the agreed flags. Record the command here.
2. Check that `git status` shows the new files as untracked-but-addable, not
   ignored.
3. Check the report lists no path inside a child repo.
4. Commit the install in `dev-workspace`.
5. Act on the user-zone findings in `dev-workspace`. Send managed-zone
   findings to their owning repos.
6. Record each toolkit problem the pilot shows: false positives, wrong
   budgets, install friction, unclear messages.
7. Review tasks 02 and 08–13 against these results. Update `PLAN.md` with the
   new sequence.

## Decisions the user must make before the install (Phase C)

1. **Hooks.** `dev-workspace` already has a `pre-commit` hook owned by
   `create-git-workspace`. `generate.sh --install-hooks` will skip it and
   report it as foreign. `--force` would overwrite it and remove the child-repo
   guard. Choose one:
   - no `--install-hooks` in the pilot (CI workflow only if wanted, by hand);
   - `create-git-workspace` chains the two hooks;
   - this toolkit learns to chain onto an existing hook.
2. **CI.** Install `.github/workflows/context-hygiene.yml` or not. It would sit
   beside `auto-merge-status.yml` and `claude.yml`. Choose the counter for CI
   (`heuristic` needs no secret; `anthropic` needs `ANTHROPIC_API_KEY` in the
   repo's secrets).
3. **Paths the `.gitignore` must allow.** Keep the defaults
   (`.context-hygiene/`, `.context-budget.toml`, `docs/PLACEMENT.md`), or move
   them. For example, `--hygiene-dir .workspace/context-hygiene` lands the
   checkers under the already-tracked `.workspace/`. That removes one `!`
   line, but `.workspace/` is `create-git-workspace`'s control plane.
4. **Audit skill.** Install `--with-audit-skill` or not.
5. **Budgets for managed zones.** The seeded total covers all three zones. The
   user owns only one. Decide if the pilot budgets the whole file (and routes
   the managed-zone overage to its owners) or waits for per-block budgets.

## Done when

The toolkit is installed in `dev-workspace`. Its findings are acted on or
explained. The deferred tasks have a sequence based on the pilot results.

Ref: `PLAN.md` "Sequence from here"; `generate.sh`; `docs/hygiene-design.md` §7.

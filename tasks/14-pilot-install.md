# Task 14 — Pilot install into one real repo

**Goal:** install the toolkit into one real repo, and act on what it reports.
This task comes before any more hardening work.

## Status (2026-11-17)

**Open. Nothing active.**

- **Phase A (read-only pass): done.** See "Phase A results" and "Phase A
  outcome".
- **Phase B and Phase C (the install): parked** by the user until
  `create-git-workspace` has room after its dispatch effort. Phase C needs
  Phase B, and Phase B is work in `create-git-workspace`. The six install
  questions under "Decisions the user must make" stay open.

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

**Status:** done 2026-11-17, user-approved. Results below, in "Phase A results".

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

**Status:** parked (user, 2026-11-17), with Phase C.

Work in `create-git-workspace`, by a child session for that repo, not by this
task:

1. Add `!` lines for `.context-hygiene/`, `.context-budget.toml`, and
   `docs/PLACEMENT.md` (or the paths the user chooses, see decisions) to the
   `.gitignore` template.
2. Decide how its `pre-commit` hook and this toolkit's hook coexist (see
   decisions).
3. Run its `update.sh` against `dev-workspace` and commit there.

### Phase C — install into `dev-workspace`

**Status:** parked (user, 2026-11-17) until `create-git-workspace` has room
after its dispatch effort. The six questions below stay open.

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

## Phase A results (2026-11-17)

**Summary:** the file is 2,639 tokens. The user's leader rules are 63% of it.
All five lint findings are in the leader rules. The two managed blocks have
no findings.

**Run.** Scratch copy of `dev-workspace/CLAUDE.md` in a `mktemp -d`
directory. The copy matched the original byte for byte (`cmp`). Counter:
`heuristic` (about ±15%). `check_budget.py --init`, then `check_budget.py
--all-sections` and `context_lint.py --warn-only`, both also with `--json`.
`git -C dev-workspace status --short` was empty before and after.

### Budget results

The seeded manifest is `budget = 3300`, `max_section = 900`,
`total_ceiling = 3500`. Every check passes: file 80% of its budget, total 75%
of the ceiling, largest section 76%. **These passes mean nothing.** `--init`
seeds budgets from today's counts plus 25% headroom, so today always passes.
A real budget needs a target number from the user (see decisions).

Against the toolkit defaults (`total_ceiling = 6000`, `max_section = 800`),
the file is 44% of the total. The `Workspace machinery` section (680 tokens)
is 85% of the section limit, which is a **warn**.

### Tokens per ownership zone

| Zone | Lines | Tokens | Share |
|---|---|---|---|
| User header | 1–6 | 68 | 3% |
| `git-workspace` managed block | 7–55 | 705 | 27% |
| `task-system` managed block | 57–71 | 207 | 8% |
| User leader rules | 72–195 | 1,659 | 63% |

Zone counts come from slicing the file at the markers. The checker's own
section counts do not line up with zones: its `# CLAUDE.md — dev-workspace`
section (84 tokens, lines 1–8) includes the `git-workspace:begin` marker.

### Findings by owner

**User — header and leader rules (1,727 tokens)**

| Section | Line | Tokens | Finding | Act on it? |
|---|---|---|---|---|
| `### 1. The leader does not change child repos` | 89 | 341 | `code-block` → skill or reference | **Yes.** The `claudeMdExcludes` JSON is one-time setup. Lines 98–99 (how to start the leader) are setup too, though not flagged. Move both to a reference doc and leave a one-line pointer. |
| `### 2. A child session does the work` | 107 | 370 | `code-block` → skill or reference | **Maybe.** The leader needs this command every time it starts a child. Move it only with rules 2–4 together (see below). |
| `### 3. Every brief stands alone` | 130 | 163 | `step-sequence` → skill | **Maybe.** It is a format for a brief, not a procedure. Same group as rule 2. |
| `### 4. The child reports in a fixed block` | 143 | 134 | `code-block` → skill or reference | **Maybe.** It is a template the leader pastes into each brief. Same group as rule 2. |
| `### 9. Migration intake (one time)` | 187 | 192 | `step-sequence` → skill | **Yes.** It says "one time". Move it to a skill or reference doc now, or delete it once the migration is done. |

Rules 2–4 together are 667 tokens and are needed only when the leader writes a
brief. A `leader-dispatch` skill would hold them. The cost: the leader must
load the skill on most turns. Decide this after the two clear moves.

The whole leader-rules section loads for **every** session rooted at
`dev-workspace`, not only the leader. Its heading says "interim — until
`create-git-workspace` `proposals`/`dispatch` ship". So the longer-term home
for most of it is `create-git-workspace`, not this file.

**`git-workspace` managed block (705 tokens) → `create-git-workspace`**

No lint findings. Nothing worth acting on now. The block's own comment says it
is a kernel and points procedure to the `workspace-status` skill. Its one
section is 85% of the default section limit; record that as something for
`create-git-workspace` to watch, not to fix.

**`task-system` managed block (207 tokens) → `create-project-system`**

No lint findings. Nothing to act on.

### Problems in the toolkit that Phase A showed

- **No read-only mode** (already recorded). The scratch-copy route worked. It
  is complete only because `CLAUDE.md` has no `@`-imports.
- **No managed-block attribution** (already recorded). Zone counts needed a
  separate script. Section boundaries do not line up with the markers.
- **Seeded budgets cannot judge size.** On a first run, `--init` makes every
  file pass. The pilot needs a target number that comes from somewhere else.
- **`code-block` cannot tell a template or contract from how-to.** Line 143 is
  a report format that the leader must paste in full. The rule flags it the
  same way as a setup snippet.
- **Long section paths in lint output.** Each finding repeats the full
  heading chain, including the 90-character leader-rules heading.

## Phase A outcome — user decisions (2026-11-17)

| Finding | Decision | Result |
|---|---|---|
| Rule 1 setup (lines 84–99) | Move it | Done in `dev-workspace` commit `ce03001`. The setup now lives in `.workspace/leader-setup.md`; rule 1 keeps a one-line pointer. |
| Rule 9, migration intake | Delete it | Deleted in `dev-workspace` when the current migration intake finishes. Not done yet. |
| Rules 2–4 (brief, command, report block) | Keep them | They stay in `CLAUDE.md`. No `leader-dispatch` skill. |
| Managed blocks | No action | No findings. |

## Decisions the user must make before the install (Phase C)

**Status:** open. Parked with Phase C (user, 2026-11-17).

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
6. **Target budget.** Phase A showed seeded budgets pass by construction.
   Pick a target total for `CLAUDE.md` (for example, the 1,727 user tokens
   minus the two clear moves, about 1,300), or keep the seeded numbers as a
   ratchet that only goes down.

## Done when

The toolkit is installed in `dev-workspace`. Its findings are acted on or
explained. The deferred tasks have a sequence based on the pilot results.

Ref: `PLAN.md` "Sequence from here"; `generate.sh`; `docs/hygiene-design.md` §7.

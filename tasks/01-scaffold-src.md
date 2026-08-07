# Task 01 — Scaffold `src/` + copy the generator substrate

**Goal:** stand up the shippable layout and reuse the emit-into-target machinery
from `create-project-system` (copied, not shared-lib — design §7).

## Steps

- [x] Create `src/` with: `checkers/`, `config/`, `docs/`, `skill/`, `hooks/`.
- [x] Copy the substrate from `../create-project-system` and strip task-specific
      logic: flag parsing, `--target-repo` handling, config rendering from a
      `.in` template, `git rev-parse --show-toplevel` root resolution (with the
      worktree-aware fallback), the golden-test harness, the in-repo `sandbox/`
      self-test scaffold.
- [x] Add `src/config/.context-budget.toml.in` (schema per design §2.3).
- [x] Add `.gitignore` for `sandbox/`.
- [x] Decide the checker language: **Python** (tokenizers, markdown parsing, JSON
      output are all easier than in bash). Record the choice; add
      `requirements.txt` (optional `tiktoken`).

## Done when

`src/` exists with the substrate copied and the config template in place; a
no-op `generate.sh` can resolve target root under both git-workspace and
git-worktree layouts.

**Status:** done. Root resolution verified against all three layouts — a plain
repo, a linked worktree (where `.git` is a FILE, which an `-d` test would miss),
and a non-git directory. The golden harness is in `tests/run.sh` with fixtures
committed. The `sandbox/` self-test is scaffolded only as far as the `.gitignore`
entry — writing the self-test itself is task 07.

Ref: `docs/hygiene-design.md` §7.

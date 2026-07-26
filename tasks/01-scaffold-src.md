# Task 01 — Scaffold `src/` + copy the generator substrate

**Goal:** stand up the shippable layout and reuse the emit-into-target machinery
from `create-project-system` (copied, not shared-lib — design §7).

## Steps

- [ ] Create `src/` with: `checkers/`, `config/`, `docs/`, `skill/`, `hooks/`.
- [ ] Copy the substrate from `../create-project-system` and strip task-specific
      logic: flag parsing, `--target-repo` handling, config rendering from a
      `.in` template, `git rev-parse --show-toplevel` root resolution (with the
      worktree-aware fallback), the golden-test harness, the in-repo `sandbox/`
      self-test scaffold.
- [ ] Add `src/config/.context-budget.toml.in` (schema per design §2.3).
- [ ] Add `.gitignore` for `sandbox/`.
- [ ] Decide the checker language: **Python** (tokenizers, markdown parsing, JSON
      output are all easier than in bash). Record the choice; add
      `requirements.txt` (optional `tiktoken`).

## Done when

`src/` exists with the substrate copied and the config template in place; a
no-op `generate.sh` can resolve target root under both git-workspace and
git-worktree layouts.

Ref: `docs/hygiene-design.md` §7.

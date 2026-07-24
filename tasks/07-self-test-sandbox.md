# Task 07 — Self-test in a disposable in-repo sandbox

**Goal:** fast inner-loop check — generate into a throwaway target inside this
repo, run the checkers, tear down. Design §8.

**Location:** `create-context-hygiene/sandbox/` — git-ignored, regenerated per run.

## Steps

- [ ] `self-test.sh` that, in a clean temp dir under `sandbox/`:
      - [ ] `git init` the target; write a small CLAUDE.md.
      - [ ] Run `generate.sh --target-repo sandbox/<tmp> --install-hooks`.
      - [ ] Assert: budget report prints; a deliberately oversized section trips
            the fail threshold; lint flags an injected code block; `@`-import
            token is counted in the total.
      - [ ] Verify the pre-commit hook blocks an over-budget commit.
      - [ ] Tear down; leave `sandbox/` empty.
- [ ] Cover both git layouts (workspace + `.bare`/linked-`main` worktree).
- [ ] One command: `bash self-test.sh`, non-zero on any failure (CI-ready).

## Done when

`bash self-test.sh` generates, exercises every checker, verifies the hook, and
tears down cleanly under both git layouts.

Ref: `docs/hygiene-design.md` §8.

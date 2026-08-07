# Task 07 — Self-test in a disposable in-repo sandbox

**Goal:** fast inner-loop check — generate into a throwaway target inside this
repo, run the checkers, tear down. Design §8.

**Location:** `create-context-hygiene/sandbox/` — git-ignored, regenerated per run.

## Steps

- [x] `self-test.sh` that, in a clean temp dir under `sandbox/`:
      - [x] `git init` the target; write a small CLAUDE.md.
      - [x] Run `generate.sh --target-repo sandbox/<tmp> --install-hooks`.
      - [x] Assert: budget report prints; a deliberately oversized section trips
            the fail threshold; lint flags an injected code block; `@`-import
            token is counted in the total.
      - [x] Verify the pre-commit hook blocks an over-budget commit.
      - [x] Tear down; leave `sandbox/` empty.
- [x] Cover both git layouts (workspace + `.bare`/linked-`main` worktree).
- [x] One command: `bash self-test.sh`, non-zero on any failure (CI-ready).

## Done when

`bash self-test.sh` generates, exercises every checker, verifies the hook, and
tears down cleanly under both git layouts.

**Status:** done — **41 assertions, all green**, exit code = failure count. It
caught two things worth keeping:

- The section ceiling assertion was passing vacuously at first, because the
  threshold it set was still above every section of a deliberately tiny fixture.
  A per-section check that never bites looks identical to one that works.
- `--keep` was keeping an empty directory: the teardown step ran before the
  trap, so the flag's entire purpose (inspecting the wreckage) did not work.

Assertions worth noting beyond the checklist, because they pin decisions rather
than behaviour:

- `--no-verify` **succeeds**, asserted deliberately. The hook is the warning and
  CI is the gate; if that ever stops being true the assertion should fail and
  force the conversation (task 13).
- The hook is pinned to an offline counter, so committing never needs a network
  round-trip even when the target is configured for the API counter.
- The `@`-import is counted in the total **while absent from the manifest** —
  the hidden tax a per-file check misses.
- In the worktree layout, the toolkit lands in the worktree and not in the
  `.bare` container, and `resolve_repo_root` agrees.

Ref: `docs/hygiene-design.md` §8.

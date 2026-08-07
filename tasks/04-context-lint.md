# Task 04 — `context-lint` (procedural-smell detector)

**Goal:** flag content that is *shaped like* a how-to or reference and shouldn't
live in an always-on file — mechanical, no LLM. Design §3–§4.

## Steps

- [x] `src/checkers/context_lint.py` scans each always-on doc and emits findings
      `{file, section, line, smell, suggested_bucket}`.
- [x] Rules (thresholds configurable in `.context-budget.toml`):
      - [x] fenced code block present → `skill|reference`
      - [x] ordered list ≥ N items → `skill`
      - [x] table > N rows → `reference`
      - [x] section tokens > threshold → `split|move`
      - [x] ≥ N lines starting `$`/shell → `skill`
- [x] Map each smell to a placement bucket (task 05's rubric) so findings say
      *where* to move content.
- [x] Output: human-readable + `--json`; exit non-zero if findings (configurable
      to warn-only).

## Done when

Run against ai-builder's CLAUDE.md (as a fixture) it flags the task-management /
worktree procedure blocks and names the target bucket for each.

**Status:** done — run against a copy of `create-ai-builder/main/CLAUDE.md`
(542 lines, **6,576 always-on tokens**). It flags 7 `code-block` findings,
including the worktree workflow (lines 8, 43) and the task-management blocks
(285, 400, 423), each with its bucket. With `max_section` ratcheted from the
seeded 2,000 down to 500 it adds 4 `oversized-section` findings — `### Summary`
alone is 1,531 tokens.

Two rules stayed silent on that file, correctly: its longest ordered list is 4
items (threshold 5) and it has 6 table lines total. ai-builder's bloat is code
blocks and section size, not step lists — which is a useful reminder that a
quiet rule is not a broken one.

Ref: `docs/hygiene-design.md` §3, §4.

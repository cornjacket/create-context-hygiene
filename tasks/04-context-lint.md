# Task 04 — `context-lint` (procedural-smell detector)

**Goal:** flag content that is *shaped like* a how-to or reference and shouldn't
live in an always-on file — mechanical, no LLM. Design §3–§4.

## Steps

- [ ] `src/checkers/context_lint.py` scans each always-on doc and emits findings
      `{file, section, line, smell, suggested_bucket}`.
- [ ] Rules (thresholds configurable in `.context-budget.toml`):
      - [ ] fenced code block present → `skill|reference`
      - [ ] ordered list ≥ N items → `skill`
      - [ ] table > N rows → `reference`
      - [ ] section tokens > threshold → `split|move`
      - [ ] ≥ N lines starting `$`/shell → `skill`
- [ ] Map each smell to a placement bucket (task 05's rubric) so findings say
      *where* to move content.
- [ ] Output: human-readable + `--json`; exit non-zero if findings (configurable
      to warn-only).

## Done when

Run against ai-builder's CLAUDE.md (as a fixture) it flags the task-management /
worktree procedure blocks and names the target bucket for each.

Ref: `docs/hygiene-design.md` §3, §4.

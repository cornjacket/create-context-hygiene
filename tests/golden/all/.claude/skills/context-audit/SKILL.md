---
name: context-audit
description: Audit this repo's always-on agent instructions (CLAUDE.md, its @-imports, the memory index) for content that is procedural, duplicated by an existing skill, or stale — and report what to move where. Use when asked to review, audit, clean up, or shrink CLAUDE.md / agent instructions, when a token budget check is failing and the fix is judgement rather than arithmetic, or on a periodic hygiene pass. Recommends only; never edits.
---

# Context audit

Installed by create-context-hygiene. This is the **judgement half** of context
hygiene. The mechanical half already runs on every commit — do not redo it.

| | Mechanism | Cadence |
|---|---|---|
| Size | `check_budget.py` — token budgets | every commit / CI |
| Shape | `context_lint.py` — procedural smells | every commit / CI |
| **Meaning** | **this skill** | **periodically, on request** |

You are here for what a regex cannot see: whether a section is procedural,
whether it duplicates a skill that already exists, and whether it is still true.

**You recommend. You never edit.** Output is a review list a human approves. If
asked to apply the moves afterwards, that is a separate, explicit instruction.

## Procedure

1. **Read the manifest** — `.context-budget.toml` names the always-on set.
   Read every file it lists, plus every `@path` those files import.

2. **Run the mechanical checkers first** and read their output:

   ```sh
   python3 .context-hygiene/check_budget.py --all-sections
   python3 .context-hygiene/context_lint.py --json
   ```

   Their findings are inputs, not your findings. Never restate a lint finding as
   your own; add the judgement it lacks — is this block load-bearing, or is it a
   tutorial that drifted in?

3. **Inventory what already exists on demand.** List `.claude/skills/*/SKILL.md`
   and read each description. You cannot spot a duplicate without this, and
   duplication is the most valuable thing you will find: a kernel section that
   restates a skill is pure tax, and the copy is usually the stale one.

4. **Judge every section** against `docs/PLACEMENT.md` — kernel, skill, or
   reference. For each one that is misplaced, record the concrete destination.
   For each one that stays, be able to say which invariant it protects.

5. **Test for staleness.** A rule is suspect when it names a path, script, flag,
   or command that no longer exists — check, do not assume. Also flag rules
   whose subject matter no longer appears anywhere in the repo, and mitigations
   for problems that were fixed (`git log -S` on a distinctive phrase dates a
   rule and often finds the commit that made it obsolete).

6. **Report** in the shape below, ordered by tokens reclaimed.

## Report shape

For each finding:

- **Location** — `file:line`, section path
- **Tokens** — what the section costs every turn
- **Verdict** — `move-to-skill` / `move-to-reference` / `split` / `delete` /
  `keep`
- **Destination** — the specific skill or doc, named. "Move to a skill" without
  naming which one is not actionable.
- **Why** — one or two sentences, tied to a placement test or to evidence of
  staleness
- **Confidence** — high / medium / low

Close with the total tokens the accepted moves would reclaim, and what the
kernel would still be missing if all of them were applied.

## What not to flag

An audit that only says "delete" is worse than none — the highest-value content
in a kernel is the part only this repo's authors know.

- **Keep every pointer.** A one-line "full procedure: the X skill" is what makes
  the skill reachable at all. Deleting pointers to save tokens breaks the
  mechanism the rest of this depends on.
- **Keep the reasons.** A rule with its "because" attached survives contact with
  a situation its author did not foresee; the same rule stripped to an
  imperative does not.
- **Keep genuine invariants** however short the file gets — safety rules,
  irreversible-action guards, conventions that are read across a portfolio.
- **Short is not the goal.** Never justify a move by length alone. Ask where the
  content belongs; the token count only ranks the work.
- **A clean audit is a valid result.** Say so and stop rather than manufacturing
  findings.

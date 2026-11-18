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

## Steps

- [x] Get the pilot target from the user: `dev-workspace`.
- [ ] Run `generate.sh --target-repo <target>` with the flags the user agrees
      to. Record the command and the flags in this file.
- [ ] Record the first `check_budget` report and the lint findings.
- [ ] Act on the findings in the target, or record why a finding is not acted on.
- [ ] Record each problem the pilot shows in the toolkit itself: false
      positives, wrong budgets, install friction, unclear messages.
- [ ] Review tasks 02 and 08–13 against these results. Update `PLAN.md` with
      the new sequence.

## Done when

The toolkit is installed in one real repo. Its findings are acted on or
explained. The deferred tasks have a sequence based on the pilot results.

Ref: `PLAN.md` "Sequence from here"; `generate.sh`; `docs/hygiene-design.md` §7.

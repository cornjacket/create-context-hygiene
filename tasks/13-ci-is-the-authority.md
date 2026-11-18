# Task 13 — CI is the authority, so it cannot be opt-in

**Type: decide, then build.** Task `06` already installs a CI workflow, but behind
`--install-hooks`, which is off by default. This task is about the policy that
flag encodes, and about what the workflow actually contains — `06` names it in
one line and stops.

## Why

The design already calls CI *"authoritative, non-skippable"* (`06`, step 5). The
default contradicts that. A check that has to be switched on is the same failure
as a check that has to be remembered — it is present exactly where someone was
already paying attention, and absent everywhere else.

The stance this repo is built on says it plainly:

> Warn before you fail, and enforce in **CI**, not only a pre-commit hook — the
> hook is bypassable, so it's the fast local guard, not the authority.

`git commit --no-verify` is one flag. So the pre-commit hook can only ever be a
warning. If CI is also optional, nothing in the toolkit is a gate, and the whole
thing degrades to a linter you run when you already suspect a problem.

## What to decide

- **Default CI on, or keep it behind a flag.** Lean: **on**, with an opt-out
  (`--no-ci`) rather than an opt-in. A target that genuinely cannot run CI should
  have to say so, so the absence is a decision rather than an oversight.
- **What happens when the target has no CI provider.** Installing a workflow file
  into a repo with no runner produces nothing and looks like success. Lean:
  detect and **say so in the post-install summary**, rather than writing a file
  that will never execute.
- **Whether the pre-commit hook stays default-on too.** It is cheap and catches
  the problem a second earlier, but it is also the part that trains people to
  pass `--no-verify`. Lean: keep it, and make its message say it is a warning and
  that CI is the gate — so bypassing it does not feel like bypassing the check.

## The workflow itself

`06` says "a CI workflow" and leaves the content undefined. It needs to specify:

- **Trigger** — push and pull request. Restricting to paths that look like
  instruction files is tempting and wrong: a budget covers a *total*, so a change
  anywhere in the always-on set can break it, including adding a new skill.
- **What it runs** — the budget check and the lint, using the exact counter the
  target chose. If the CI counter can differ from the local one, a commit can
  pass locally and fail remotely with no explanation; either pin them or make the
  difference explicit in the failure message.
- **How it fails** — print the numbers. Which file, its count, its limit, and how
  much over. A red X with no figure sends the reader to run the tool by hand,
  which is what CI was supposed to replace.
- **A warn band before the fail band** — the design already asks for "warn before
  you fail". Decide whether the warning is annotation-only or a soft-fail, and
  make sure a warning cannot be mistaken for a pass.

## Advertise the check — the `context-hygiene` key in `discovery.json`

A repo carrying this toolkit says so in **`discovery.json`** at its root, so a
containing workspace can ask which of its repos are covered instead of looking
inside each one for a `.context-hygiene/` directory.

This generator owns exactly one key:

```json
{
  "context-hygiene": {
    "version": 1,
    "checkers": ".context-hygiene",
    "budgets": ".context-budget.toml",
    "ci": true
  }
}
```

`ci` is the field that matters to a workspace: *"checked on every push"* and
*"installed but nothing enforces it"* are indistinguishable from outside without
it, and after this task the second state should be rare enough to be worth
naming when it happens.

**The file is shared, and that is the whole point.** `create-project-system`
task `28` writes `tasks` and `inbox` into the same file. One capability file per
generator would leave a consumer probing for `inbox.json`, then
`context-hygiene.json`, then the next — the same probing all of this exists to
end, moved up one level.

Two rules follow, and both must hold or the generators corrupt each other:

- **Own your key, never the file.** Read the existing `discovery.json`, set only
  `context-hygiene`, write it back. Writing the file wholesale erases whatever
  ran before, and nothing notices until a consumer asks for a missing key.
- **Version per key.** One file-level version cannot stay true when two
  generators write at different times on different release schedules.

**Agree the filename and the merge rule with `create-project-system` task `28`
before either writes code.** Two generators disagreeing about the name of a file
they both write is a silent, mutual overwrite.

**The merge rule is now settled at the workspace** (task `229ccb-0000` in
`dev-workspace`). A generator that writes `discovery.json` must:

1. Read the existing file.
2. Change only the key it owns (`context-hygiene` here).
3. Keep every other key as it is.
4. Stop with an error if the file is malformed. Do not overwrite it.

Assert it: install this toolkit over a repo that already carries a foreign key,
and check the foreign key survives.

## Done when

- A plain `generate.sh --target-repo <scratch>` produces a repo whose CI fails on
  an over-budget instruction file, with the numbers in the output, without any
  extra flag.
- A target with no CI provider is told so at install time.
- The `context-hygiene` key is written into `discovery.json`, and a consumer can
  tell "checked on push" from "installed, unenforced" from "not installed" —
  without looking for a directory.
- Installing over a repo that already carries `tasks`/`inbox` keys leaves them
  intact.

Ref: `docs/hygiene-design.md` §2.4, §7. Builds on `03`, `04`, `06`.

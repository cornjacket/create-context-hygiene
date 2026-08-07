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

## Advertise the check

A repo carrying this toolkit should be able to say so in machine-readable form,
so a containing workspace can ask which of its repos are covered instead of
probing each one for a directory.

This is the same problem `create-project-system` task `28` solves for the task
system's mount, and `create-git-workspace`'s `mail` effort solves for an inbox.
**Do not invent a third file.** Whatever single manifest those two settle on,
write a `context-hygiene` key into it: the checker's path, the limits file, and
whether CI is wired. Coordinate before building — three generators each inventing
their own declaration is exactly the probing this was meant to end.

## Done when

- A plain `generate.sh --target-repo <scratch>` produces a repo whose CI fails on
  an over-budget instruction file, with the numbers in the output, without any
  extra flag.
- A target with no CI provider is told so at install time.
- The manifest key is written, and a consumer can tell "checked" from
  "not installed" without looking for a directory.

Ref: `docs/hygiene-design.md` §2.4, §7. Builds on `03`, `04`, `06`.

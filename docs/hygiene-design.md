# Design — Context-Hygiene Generator

**Goal:** `create-context-hygiene` is a **generator** (peer of `create-project-system`)
that installs a context-hygiene toolkit into any target repo. The toolkit keeps
agent-facing instruction files (`CLAUDE.md`, imported docs, skills, memory index)
**small** (size) and **well-placed** (relevance), and can help **clean and
organize** a repo whose instructions have already ballooned.

**Relationship to `create-project-system`:** orthogonal peers over the same
generator substrate. The task system is one *producer* of agent-facing context;
the hygienist is the broader concern that *measures and polices* it. They compose
at the target — install both and the hygienist keeps the task system's own skill
+ CLAUDE.md kernel honest — but neither depends on the other.

---

## 1. Two concerns, kept separate

| Concern | Nature | Mechanism | Cadence |
|---|---|---|---|
| **Size** | mechanical | token budgets (per-file, per-section, total-always-on) | every commit / CI |
| **Relevance / placement** | judgment | placement rubric + procedural-smell lint + LLM audit | lint every commit; audit periodically |

Line count is the wrong unit for both — the currency is **tokens loaded per
turn**. Everything below measures tokens.

---

## 2. Token budgeting — the "how"

### 2.1 Pluggable counter, tiered default

Exact Claude token counts need the Anthropic `count_tokens` API (network + auth) —
wrong fit for a fast, offline pre-commit hook. So the counter is an **abstraction**
with three tiers:

| Tier | Backend | Use | Accuracy | Deps |
|---|---|---|---|---|
| `heuristic` (default) | `chars / 4` (with a code-block adjustment) | pre-commit, zero-setup | ±~15% | none |
| `tiktoken` | local BPE (`o200k_base`) | pre-commit when installed | ±~10% vs Claude | `tiktoken` |
| `anthropic` | `messages.count_tokens` API | CI / on-demand exact reading | exact | `ANTHROPIC_API_KEY` |

Select via `--counter` or a config key. **Set budgets with headroom** (e.g.
target 70% of the true ceiling) so approximation error never causes flapping. The
API tier is opt-in for an authoritative number when it matters; the offline tiers
gate the inner loop. (See `claude-api` skill for `count_tokens`.)

### 2.2 Per-section budgets

A file can pass its total while one section balloons (ai-builder's 215-line
`## Task Management`). So:

- Split the file into a **section tree** by ATX headings (`^#{1,6} `). A simple
  line splitter suffices — no full markdown AST needed.
- Count tokens per section (own body; report cumulative-with-children too).
- Enforce a **max tokens per section**; report `section path → tokens → % of budget`.
- Over-budget → finding + suggestion (split, or move to skill/reference per §4).

### 2.3 Total always-on budget (the context manifest)

The real cost is the **sum of everything auto-loaded every turn**, not one file.
A manifest enumerates them:

```toml
# .context-budget.toml (in the target repo)
[budget]
counter        = "heuristic"     # heuristic | tiktoken | anthropic
warn_pct       = 80
fail_pct       = 100
total_ceiling  = 6000            # tokens, summed across always-on set

[[always_on]]
path   = "CLAUDE.md"
budget = 3000
max_section = 800

[[always_on]]
path   = "MEMORY.md"             # memory index, if used
budget = 1500
```

- The checker resolves each entry, counts tokens, enforces **per-file**,
  **per-section**, and **global** ceilings.
- **Auto-discover `@`-imports:** Claude Code auto-loads files CLAUDE.md pulls in
  via `@path`. Scan CLAUDE.md for `@`-references and fold them into the
  always-on total (a hidden tax that a per-file check misses).
- **Warn at `warn_pct`, fail at `fail_pct`** — runway before a hard stop.

### 2.4 Enforcement surfaces

- **pre-commit** (offline counter): budget + lint on the always-on files;
  bypassable (`--no-verify`), so it's the fast local guard, not the authority.
  **Known limitation:** the hook checks the **working tree**, not the staged
  content. After a partial `git add -p`, it can pass or fail on content that is
  not in the commit. CI checks the committed content, so CI still holds the
  line. Materializing the index into a temp directory (`git checkout-index`)
  was considered and rejected: too complex for the value.
- **CI** (may use `anthropic` counter): same checks, authoritative, cannot be
  skipped. This is what actually holds the line.

---

## 3. `context-lint` — procedural-smell detector (the "how")

~80% of bloat is detectable **without an LLM**. Rules over each always-on doc,
each producing a finding with location + suggested destination:

| Smell | Signal | Suggested move |
|---|---|---|
| How-to prose | fenced code block present | → skill or reference |
| Step sequence | ordered list ≥ N items | → skill |
| Reference data | table > N rows | → reference doc |
| Oversized unit | section tokens > threshold | → split / move |
| Command dump | ≥ N lines starting `$`/shell | → skill |

Output: human-readable + JSON (for CI). Thresholds configurable. This is the
mechanical half of relevance — it flags *shape*, not meaning.

---

## 4. Placement rubric (the decision, productized)

Ship `PLACEMENT.md` — the rule the lint enforces. Three buckets, each with a test:

- **Always-on (CLAUDE.md kernel):** *"if this only loaded on demand, would it be
  too late?"* → yes = kernel (invariants, triggers, safety). Must be tiny.
- **On-demand (skill):** *"only needed while doing task X?"* → skill.
- **Reference (separate md, by pointer):** *"consulted, not obeyed?"* → reference.

The lint maps each smell to a bucket so findings say *where* to move content, not
just *that* it's bloated.

---

## 5. LLM relevance audit (the judgment half)

A skill/command that reads the always-on set and reports what heuristics can't
judge: sections that are procedural (belong in a skill), duplicate an existing
skill, or are stale/never-cited. **Recommends, never auto-edits** — human
approves. Runs periodically, not per-commit. (Uses Claude; see `claude-api`.)

---

## 6. Clean & organize (assisted reorganization) — staged

"Clean and organize" is more than checking. Staged so the mechanical, high-value
part ships first:

1. **Detect** (mechanical): budget + lint + audit produce a report of what's
   over-budget and mis-placed. Ship first.
2. **Assisted split** (later): an LLM-driven command that proposes a concrete
   refactor of a bloated `CLAUDE.md` into `kernel + skill(s) + reference`, as a
   diff for human review. The motivating case is ai-builder (~300 always-on lines
   → on-demand). Never auto-applied without review.

---

## 7. Generator architecture

Shares the substrate with `create-project-system` — **copied, not shared-lib** (two
consumers don't justify a shared dependency yet; promote later if a third module
appears).

```
create-context-hygiene/
    generate.sh              # emit toolkit into a target repo
    src/
        checkers/            # count-tokens, check-budget, context-lint
        config/.context-budget.toml.in
        docs/PLACEMENT.md
        skill/context-audit/SKILL.md      # optional LLM audit
        hooks/pre-commit.in  # + CI workflow template
    sandbox/                 # disposable in-repo self-test target (git-ignored)
    tasks/                   # build work-items
    docs/                    # this design
```

### 7.1 The checkers are Python; the emitter is bash

Decided in task 01, recorded here because it is the kind of choice that gets
re-litigated. The emitter stays **bash** — it copies files and substitutes
tokens, which is all `create-project-system`'s substrate does, and matching it
keeps the two generators readable as one family. The checkers are **Python 3**,
standard library only:

- Tokenizing, markdown section parsing, and JSON output are all substantially
  easier than in bash, and the token counter has to swap backends behind one
  interface.
- The optional accurate counters are Python packages (`tiktoken`, `anthropic`),
  so the alternative would be shelling out to Python anyway.
- `tomllib` is stdlib on 3.11+; older interpreters fall back to a small parser
  for the narrow schema this generator writes, so a target needs **no
  dependencies at all** to run the default path.

Zero-dependency matters more than it looks: the pre-commit hook must work on a
fresh clone with no install step, or it is not a guard.

### 7.2 Template rendering is in Python, on purpose

`check_budget.py --init` reads `src/config/.context-budget.toml.in` and
substitutes its placeholders itself. `generate.sh` does not render that file.
An earlier design rendered it in `generate.sh` and then re-seeded it from the
target's counts. That gave two substitution sites for one file. Keep one.

**`generate.sh` contract (proposed):**

```sh
generate.sh \
    --target-repo <path>            # required
    --counter <heuristic|tiktoken|anthropic>   # default heuristic
    [--with-lint]                   # emit context-lint (default on)
    [--with-audit-skill]            # emit the LLM audit skill
    [--install-hooks]               # wire pre-commit + CI
    [--force]
```

Emits the checkers, a starter `.context-budget.toml` (seeded from the target's
current CLAUDE.md so budgets start realistic), `PLACEMENT.md`, and optionally the
hooks + audit skill.

---

## 8. Testing

- **In-repo `sandbox/` self-test** — generate into a disposable target, run the
  checkers, tear down. Fast inner loop.
- **Dirty fixture repos** — deliberately bloated targets (mirror ai-builder's fat
  CLAUDE.md) the generator installs into; assert the checkers flag the right
  sections and the budget totals match expectation. These are the "sandboxed test
  repos the generator cleans and organizes."
- **Golden test** — fixed inputs → fixed report/diff; catches drift.

---

## References — design provenance

Two second-brain notes shaped this design:

- `resources/agent-instruction-placement.md` — the size-versus-placement split
  (§1), the three placement buckets (§4), and the rule that CI, not the hook,
  is the gate (§2.4).
- `resources/cookiecutter-pattern.md` — the machinery-versus-content split in
  `generate.sh`'s collision policy, zero-diff regeneration as the property to
  test directly (§8), "vendor the copy when an agent or human reads it" (the
  vendored checkers), and the two-placeholder-namespace trap (`generate.sh`
  header).

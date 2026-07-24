# Task 02 — Pluggable token counter

**Goal:** measure **tokens**, not lines — with a counter abstraction so the fast
offline path and the exact path share one interface. Design §2.1.

## Steps

- [ ] `src/checkers/count_tokens.py` exposing `count(text, counter=...) -> int`.
- [ ] Implement three backends:
      - [ ] `heuristic` (default) — `chars/4` with a code-block adjustment
            (fenced blocks tokenize denser). Zero deps.
      - [ ] `tiktoken` — `o200k_base` if the package is importable; else fall
            back to `heuristic` with a warning.
      - [ ] `anthropic` — `messages.count_tokens` via the SDK; requires
            `ANTHROPIC_API_KEY`. For CI / on-demand exact reads.
- [ ] Selectable via arg + `.context-budget.toml` `counter` key.
- [ ] CLI: `count_tokens.py <file> [--counter X]` prints the token count.
- [ ] Calibrate: on a sample doc, record heuristic-vs-anthropic error so budgets
      can be set with headroom (design says target ~70% of true ceiling).

## Done when

`count_tokens.py CLAUDE.md` returns a sane count on all three backends (anthropic
gated on a key), and the heuristic is within a documented error band.

Ref: `docs/hygiene-design.md` §2.1; `claude-api` skill for `count_tokens`.

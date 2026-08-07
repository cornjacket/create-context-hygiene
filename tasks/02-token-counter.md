# Task 02 — Pluggable token counter

**Goal:** measure **tokens**, not lines — with a counter abstraction so the fast
offline path and the exact path share one interface. Design §2.1.

## Steps

- [x] `src/checkers/count_tokens.py` exposing `count(text, counter=...) -> int`.
- [x] Implement three backends:
      - [x] `heuristic` (default) — `chars/4` with a code-block adjustment
            (fenced blocks tokenize denser). Zero deps.
      - [x] `tiktoken` — `o200k_base` if the package is importable; else fall
            back to `heuristic` with a warning.
      - [x] `anthropic` — `messages.count_tokens` via the SDK; requires
            `ANTHROPIC_API_KEY`. For CI / on-demand exact reads.
- [x] Selectable via arg + `.context-budget.toml` `counter` key.
- [x] CLI: `count_tokens.py <file> [--counter X]` prints the token count.
- [ ] Calibrate: on a sample doc, record heuristic-vs-anthropic error so budgets
      can be set with headroom (design says target ~70% of true ceiling).
      **The mechanism is built (`count_tokens.py --calibrate` runs every
      available backend and reports the error band); the measurement is not
      taken.** It needs `ANTHROPIC_API_KEY` (and, for the middle tier,
      `pip install tiktoken`) on a machine that has them. Until it is run, the
      ±15% figure in the design is an estimate, and the seeded budgets carry
      25% headroom on that basis.

## Done when

`count_tokens.py CLAUDE.md` returns a sane count on all three backends (anthropic
gated on a key), and the heuristic is within a documented error band.

**Status:** the first half holds — heuristic and tiktoken verified, `anthropic`
implemented against `messages.count_tokens` (it subtracts the measured message
envelope so its number is comparable to the text-only tokenizers). The error
band is still undocumented; see the unchecked step above.

Ref: `docs/hygiene-design.md` §2.1; `claude-api` skill for `count_tokens`.

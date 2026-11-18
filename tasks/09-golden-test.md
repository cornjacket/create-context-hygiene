# Task 09 — Golden / reproducibility test

**Goal:** lock generator output and checker reports so regressions surface as a
diff. Design §8.

## Steps

- [ ] Generate the toolkit into a scratch dir with a fixed flag set; capture the
      emitted tree as a checked-in fixture (`tests/golden/`).
- [ ] Capture the checker **reports** (`--json`) for each dirty fixture (task 08)
      as golden report fixtures.
- [ ] A test regenerates + re-runs and diffs against both; fails on drift.
- [ ] Determinism: pin the counter to `heuristic` for golden runs (no network,
      no tokenizer-version drift); no timestamps in emitted files or reports.
- [ ] Document how to intentionally refresh fixtures.

## Note — the emitted-tree fixtures were committed early, on purpose

Task 07 committed the golden fixtures under `tests/golden/`, not this task. A
harness with no fixtures fails with `MISSING fixture`, and that reads as a
broken test. So the fixtures shipped with the harness.

The cost: each fixture tree (`all`, `core`, `no-lint`) holds a copy of the
checker sources. Every checker edit therefore needs a fixture refresh:

```sh
bash tests/run.sh --update
```

## Done when

`bash tests/run.sh` diffs clean for the emitted tree and every fixture report
under the pinned counter.

Ref: `docs/hygiene-design.md` §8.

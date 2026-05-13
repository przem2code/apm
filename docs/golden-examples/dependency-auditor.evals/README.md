# `dependency-auditor` test suite

This directory holds **two distinct test layers**. Both are valuable; they catch different failures.

| Layer | What it tests | Output | Runs in CI? |
|---|---|---|---|
| **Behavior evals** ([`evals.json`](./evals.json), [`triggers.json`](./triggers.json)) | The skill's actual LLM behavior. Each case runs twice: with the skill loaded and without it, so the value delta is measurable. | `dependency-auditor-workspace/iteration-N/<case>/{with_skill,without_skill}/{outputs,timing.json,grading.json}` | No — manual / harness-driven. |
| **Rubric regression test** ([`run.js`](./run.js)) | The deterministic `classify()` substrate the skill depends on. Locks the rubric against live npm audit output + a synthetic fixture covering branches the live registry doesn't exercise today. | Pure-Node script, exits `0` on green, `1` on drift. | Yes — fast (seconds), hermetic apart from the npm registry. |

The behavior evals are what [agentskills.io calls "evals"](https://agentskills.io/skill-creation/evaluating-skills). The rubric regression test is a unit test for the classifier function. Both were scaffolded via the [Genesis](https://github.com/DevExpGbb/genesis) skill — Genesis's step-6 EVALS PLAN produces `evals.json` + `triggers.json`; the rubric regression script is independent contributor tooling.

---

## Layer 1 — Behavior evals (the real evals)

`evals.json` defines 3 content evals + the iteration workflow. `triggers.json` defines ~20 trigger queries (60/40 train/val) for the dispatch description.

### How to run

The agentskills.io spec describes the structure but does NOT prescribe a runner — execution is harness-driven. The current canonical recipe:

1. **Per case in `evals.json`**, spawn TWO subagent runs (or two clean sessions if your harness has no subagent isolation):
   - **with_skill**: skill is loaded into the subagent's context.
   - **without_skill**: same prompt, no skill — establishes the baseline.
2. Capture each run's outputs into `dependency-auditor-workspace/iteration-N/<case-id>/{with_skill|without_skill}/outputs/`. Capture `timing.json` (`total_tokens`, `duration_ms`) alongside.
3. Grade per the case's `assertions[]`. Script-graded assertions (`contains_all_of`, `no_file_writes`, `no_invented_classifications`, `skill_activated`, `ran_npm_audit`, `skill_declines`, `no_npm_audit_run`, `no_invented_cve_ids`) are mechanical. `llm_judge` assertions get a fresh LLM call with the rubric. Write `grading.json`.
4. Aggregate to `dependency-auditor-workspace/iteration-N/benchmark.json`.
5. **Ship gate**: all 3 cases PASS with_skill AND show measurable delta vs without_skill. If `with_skill ≈ without_skill`, the skill is not adding value.

For trigger evals: run via the harness's dispatcher (NOT the skill body). Validation split is the gate.

### Iteration discipline (per agentskills.io)

- **Add assertions AFTER the first run.** Iteration 1 is exploratory; iteration 2 hardens with assertions.
- **Iterate the skill body, not the assertions, when assertions fail.** If you're tweaking assertions to pass, you've inverted the test.

---

## Layer 2 — Rubric regression test

Why this exists: trainees building the dependency-auditor Skill on Track 3 previously had no shippable way to validate their classification logic — the only oracle was "did you eyeball the markdown?" That's not defensible in a regulated shop (Senior persona finding, V3 panel) and it's asymmetric with Track 4.

This script asserts two things:

1. **Live npm registry behavior** matches the documented rubric. Runs `npm audit --json` against `zava-storefront/security-fixtures/`, applies the rubric verbatim, and diffs against `expected/classifications.txt`.
2. **All four classification branches** are exercised. The live fixture only exercises `safe-bump` + `breaking-bump` because today's npm registry returns object-shaped `fixAvailable` for all three baked-in deps. The synthetic fixture in `fixtures/manual-review-fixture.json` covers the other two: `fix-via-force` (boolean `true`) and `manual-review` (`false`).

### How to run

From the workshop repo root:

```bash
node docs/golden-examples/dependency-auditor.evals/run.js
```

Exits `0` on match, `1` on mismatch with a diff. No npm/yarn deps — pure Node.

It's also wired into `apm run validate-track-3` (see `apm.yml`).

### When this fails

**[1/2] live audit failed:** The npm advisory database has likely evolved since the fixture was pinned. Three deliberate paths:

- **Patched version drifted** (e.g. lodash 4.18.1 → 4.18.2): update the third column in `expected/classifications.txt`.
- **Severity reclassified** (e.g. high → critical): update the second column.
- **Branch type changed** (e.g. object → boolean true): the SKILL rubric is now under-specified for this advisory. Update both the SKILL prose and this expected file in the same PR.

Always update the SKILL rubric prose and this file together — they are a single source of truth split across two files.

**[2/2] synthetic failed:** Someone changed `classify()` in `run.js` without updating `expected/synthetic.txt`. Re-derive expected from the rubric.

### Maintenance contract

`run.js`'s `classify()` function MUST stay byte-for-byte aligned with lines 39-43 of `docs/golden-examples/dependency-auditor.SKILL.md`. The skill is the spec; this is the executable check.

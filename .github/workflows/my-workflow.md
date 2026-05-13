---
on:
  pull_request:
    types: [labeled]
  workflow_dispatch:
  roles: [admin, maintainer, write]

# Trigger this workflow by labelling a PR with `run-my-skill`. The
# workflow will check out the PR, run your skill, and post a summary.
if: |
  (github.event_name == 'pull_request' && github.event.label.name == 'run-my-skill')
  || github.event_name == 'workflow_dispatch'

permissions:
  contents: read
  pull-requests: read
  issues: read

network: defaults

# `gh aw` requires a single engine id at compile time. We use `copilot` here as
# the demo runner because it's available to every harness user with `gh auth`.
# To switch engines (e.g. claude, codex), change this id and re-run `gh aw compile`.
engine:
  id: copilot

# Imports the standard APM shared bootstrap (apm install + skill discovery).
imports:
  - shared/apm.md

safe-outputs:
  add-comment:
    max: 1

timeout-minutes: 15
---

# Run My Skill

You are running the **`my-skill`** Agent Skill (defined in
`.apm/skills/my-skill/SKILL.md`) against this repository's
`zava-storefront/` directory.

## Steps

1. Locate `zava-storefront/` at the repo root. If missing, post a comment
   explaining and stop.
2. Invoke the `my-skill` skill against `zava-storefront/`. Follow its
   `SKILL.md` instructions exactly.
3. Summarize what the skill did in **3–5 bullet points**:
   - Files read
   - Files written or modified (path + line counts)
   - Any tests run + results
   - Any follow-up actions a human reviewer should verify
4. Post the summary as a single PR comment via `add-comment`.

## Constraints

- Do **not** modify files outside `zava-storefront/`.
- Do **not** attempt to merge or label the PR.
- Keep the summary comment under 300 words.

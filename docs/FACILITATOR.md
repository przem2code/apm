# Facilitator Preflight Checklist

Run this **the day before** you deliver the workshop, in a fresh clone of the trainee template. ~10 min if everything's healthy. If anything fails, the workshop is at risk — fix before you stand up in front of the room.

## 1 · Liveness checks (handbook URLs)

The tracks deep-link to live handbook chapters. If the venue blocks GitHub Pages (rare but happens at banks), you need to know **before** the session — every track has local-summary fallbacks already, but you'll want to call it out at kickoff.

```bash
for url in \
  "https://danielmeppiel.github.io/agentic-sdlc-handbook/handbook/ch12-the-prose-specification.html" \
  "https://danielmeppiel.github.io/agentic-sdlc-handbook/handbook/ch04-the-reference-architecture.html" \
  "https://danielmeppiel.github.io/agentic-sdlc-handbook/handbook/ch18-architectural-patterns-rosetta-stone.html"; do
  printf "%-100s " "$url"
  curl -fsSL -o /dev/null -w "%{http_code}\n" "$url"
done
```

All three should return `200`. If anything else: announce at kickoff that the local fallbacks (in each track doc) are authoritative for the day.

## 2 · Clean-machine smoke test

In a **brand-new clone** of the template (not your dev clone — fresh):

```bash
gh repo clone DevExpGbb/zava-skills-workshop-template /tmp/wf-preflight
cd /tmp/wf-preflight

# Setup chain — the same one trainees run:
apm install
git clone --branch workshop-v1 --depth 1 https://github.com/DevExpGbb/zava-storefront.git zava-storefront
npm install --prefix zava-storefront
npm test --prefix zava-storefront                 # → 7/7 green
node .apm/skills/framework-modernizer/evals/run.js   # → 8/8 match

# Validation surface:
apm run validate                             # → gh skill publish --dry-run
```

If `apm run validate` fails because `gh skill` isn't installed: `gh extension install github/gh-skill`. Re-run.

## 3 · Preinstall guard fires

Confirm the safety net works (this is what protects trainees from accidentally polluting `zava-storefront/` with vulnerable deps from `security-fixtures/`):

```bash
cd /tmp/wf-preflight
# Try to add lodash to the real app — should be rejected:
( cd zava-storefront && npm pkg set dependencies.lodash="4.17.4" && npm install ) 2>&1 | tail -5
# Expected: "❌ Refusing to install ... lodash@4.17.4 is a known-vulnerable fixture-only dep"
# Roll back:
( cd zava-storefront && npm pkg delete dependencies.lodash )
```

## 3a · Track 3 audit fixture is wired

Track 3 depends on `zava-storefront/security-fixtures/` actually surfacing vulnerable deps. If something has been bumped or the fixture was tampered with, the whole track silently teaches the wrong rubric:

```bash
cd /tmp/wf-preflight/zava-storefront/security-fixtures
npm install --no-audit --no-fund >/dev/null 2>&1
npm audit --json 2>/dev/null | jq -r \
  '.metadata.vulnerabilities | "high=\(.high) critical=\(.critical) total=\(.total)"'
# Expected: high=1 critical=2 total=3   (1 high axios, critical lodash + minimist)
# If counts diverge: someone bumped the fixture deps. Restore from git or skip Track 3.

# Spot-check that fixAvailable is well-formed (object OR boolean true OR false):
npm audit --json 2>/dev/null | jq -r \
  '.vulnerabilities | to_entries[] | "\(.key)\t\(.value.fixAvailable | type)"'
# Expected: 3 lines, each with type "object" or "boolean".
```

## 4 · Workflow labels (per track you plan to run)

`gh aw`'s labeled-PR trigger silently no-ops if the label doesn't exist (see the [trigger reference](https://github.github.com/gh-aw/reference/triggers/) for the full event matrix). Pre-create labels in the **trainee org** if you can:

```bash
gh label create run-test-improver --color B0E0FF --description "Test-improver skill trigger" --repo <org/repo> || true
gh label create run-docs-generator --color C8FFB0 --description "Docs-generator skill trigger" --repo <org/repo> || true
gh label create run-dependency-auditor --color FFB0B0 --description "Dependency-auditor skill trigger" --repo <org/repo> || true
```

If the workshop is fully self-service and trainees create their own repos from the template, mention this as a Track 5 ("Automate") prerequisite — the track doc has the command.

## 5 · Harness coverage

Make sure **at least one trainee** is on each major harness so you can field questions across the matrix. The minimum-viable check per harness:

| Harness | `/genesis` verify |
|---|---|
| Copilot CLI | `/genesis` autocompletes; ask "what skills are loaded?" |
| Claude Code | Type `/genesis` — slash command surfaces |
| Codex | `/genesis` autocompletes |
| Cursor | Skills panel shows `genesis` |
| OpenCode | Skills panel shows `genesis` |

If `/genesis` doesn't surface: the trainee's `apm install` step probably didn't complete (network blip / proxy). Re-run.

## 6 · Reproducibility expectations to set at kickoff

State these out loud during Section 0 so nobody is surprised mid-track:

1. **Same `SKILL.md`, different transcripts.** Models drift across harnesses; the *artifact* is reproducible, not the chat.
2. **`gh skill` is preview.** If something behaves oddly with `apm run validate`, it's the surface, not their skill.
3. **CI queue weather.** Section 5 (Automate) timing varies by GitHub Actions load — budget 5–15 min, not "1 minute".
4. **Track 4 is a reference deep-dive**, not a from-scratch build. They will read a real, eval-backed skill and contribute one catalog entry — by design.

## 7 · Escalation contacts

- Workshop content issues: file an issue on `DevExpGbb/zava-skills-workshop-template`.
- Genesis / `apm` install issues: `microsoft/apm` issues.
- `gh aw` issues: `githubnext/gh-aw` issues.
- `gh skill` preview surface: GitHub support / `cli/cli` issues.

If a trainee gets fully stuck on setup, hand them the **completed reference skills** under `docs/golden-examples/` — they can read those and still get value from §4–§6 even if their own skill didn't compile.

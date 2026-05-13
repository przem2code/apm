---
name: dependency-auditor
description: |
  Run `npm audit --json` against zava-storefront/security-fixtures/, parse the result,
  rank advisories by severity, classify each as safe-bump vs breaking-bump, and
  emit a markdown remediation report. Never modify package.json.
license: MIT
allowed-tools: Read, Bash(npm:*), Bash(jq:*)
---

# dependency-auditor

## When to use this skill

Invoke when:

- The user asks for a security audit of `zava-storefront/security-fixtures/`
- A PR modifies `zava-storefront/security-fixtures/package.json` or `zava-storefront/package.json`

Do not invoke for: source code changes, lockfile-only changes, or repos without a `package.json`.

## Steps

1. Run `npm install --prefix zava-storefront/security-fixtures --no-audit --no-fund` to ensure dependencies are present.
2. Run `npm audit --prefix zava-storefront/security-fixtures --json` and capture stdout.
3. Parse the JSON. The relevant shape (npm 10+) is:
   ```
   {
     "auditReportVersion": 2,
     "vulnerabilities": {
       "<package>": {
         "severity": "low | moderate | high | critical",
         "range": "<vulnerable semver range>",
         "fixAvailable": false | true | { "name": "<pkg>", "version": "<x.y.z>", "isSemVerMajor": true|false }
       }
     }
   }
   ```
4. For each entry under `vulnerabilities`, classify:
   - **safe-bump** — `fixAvailable` is an object AND `fixAvailable.isSemVerMajor === false`
   - **breaking-bump** — `fixAvailable` is an object AND `fixAvailable.isSemVerMajor === true`
   - **fix-via-force** — `fixAvailable === true` (boolean): a fix exists but `npm audit` did not return a version because the bump is top-level / requires `npm audit fix --force`. Treat as breaking until inspected.
   - **manual-review** — `fixAvailable === false` (or missing)
5. Produce the report below. Top-5 critical/high findings only in the headline table; full list in a collapsible details block.

## Output schema (strict)

```
## Audit summary (security-fixtures)
- 🔴 critical: N · 🟠 high: N · 🟡 moderate: N · 🟢 low: N

## Top findings
| severity | package | vulnerable range | fix version | bump-kind |
|---|---|---|---|---|
| critical | minimist | <=0.2.3 | 1.2.8  | breaking-bump |
| critical | lodash   | <=4.17.20 | 4.18.1 | safe-bump |
| high     | axios    | <=0.21.0 | 0.21.4 | safe-bump |

## Manual review
- <package>: fixAvailable === false — no automated remediation; investigate upstream

## Recommended next step
- Apply safe-bumps with `npm install --prefix zava-storefront/security-fixtures <pkg>@<version>` (always use `--prefix` — never run from the wrong cwd or you risk polluting the real app's `package.json`).
- Open separate PRs for breaking-bumps; pair each with regression tests.
```

## Constraints

- Never modify any `package.json` — this skill outputs recommendations, not patches
- Never run `npm audit fix` or `--force`
- Never invent CVE IDs, advisory URLs, or patched versions. If `fixAvailable === true` (boolean), `fix version` is unknown — leave it blank or write `(--force required)`, never guess.
- `npm audit` exits 1 when vulnerabilities are present. Use `npm audit --json || true`, then read `metadata.vulnerabilities.total` to detect the empty case.
- The report must be valid markdown that pastes cleanly into a PR comment

## Example invocation

> Use the dependency-auditor skill on `zava-storefront/security-fixtures/`.

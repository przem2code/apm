# 🧰 Zava Skills Workshop Template

> **From "I have an idea for a skill" to "my skill ships on every PR" in one repo.** Design with [Genesis](https://github.com/DevExpGbb/genesis), build locally, validate against the open spec, package with `apm`, automate with `gh aw`.

[![Use this template](https://img.shields.io/badge/Use%20this-template-brightgreen?logo=github)](../../generate)
[![apm](https://img.shields.io/badge/apm-required-blue)](https://github.com/microsoft/apm)
[![gh-aw](https://img.shields.io/badge/gh--aw-required-blue)](https://github.com/githubnext/gh-aw)
[![Duration](https://img.shields.io/badge/Duration-90--120%20min-orange)]()

> **Scope:** this workshop targets **GitHub** (incl. GitHub Enterprise Cloud) + **GitHub Copilot Business/Enterprise**. The CI automation track uses `gh aw` workflows with `engine: copilot`. It is an **experiment / hands-on learning kit**, not a production-grade enterprise rollout — for that, you'd add an engine-abstraction layer, GitHub App auth (vs. PATs), SLSA attestation, prompt audit logging, and isolate the deliberate `poisoned-tracing-skill` fixture into a sandbox subaccount. None of those are in scope here.

---

## 🤔 The problem this template solves

You've used an AI coding assistant. You've felt the ceiling:

- The same task gives **different output every time**
- Your team's conventions get **silently ignored**
- Skills you build live in *your* IDE — they don't ship, they don't compose, they don't run on someone else's PR
- There's no architecture: every skill is a one-off file, and the second one duplicates the first

**Skills are the way out.** But "build a skill" without scaffolding becomes another monolithic markdown file. This workshop makes you build one *with* scaffolding — design first, narrow scope, packaged for distribution, automated in CI.

---

## 🎯 What you'll build

By the end of this workshop, you'll have:

1. A **designed skill** — produced *with* [Genesis](https://github.com/DevExpGbb/genesis), not improvised
2. That skill **running locally** in your IDE against the canonical [`DevExpGbb/zava-storefront`](https://github.com/DevExpGbb/zava-storefront) — a real Next.js 14 + Postgres commerce repo (cloned alongside this workshop, not vendored)
3. The same skill **packaged + released** as a versioned tarball (`v0.1.0`)
4. The same skill **executing in CI** on PRs via [`gh aw`](https://github.com/githubnext/gh-aw)
5. A **consumer repo** pinning your skill via `apm` and getting the value automatically

> 📚 **Theory:** [Genesis](https://github.com/DevExpGbb/genesis) compresses the design discipline behind the patterns you'll use here. For the underlying architecture, see *The Agentic SDLC Handbook* — [Ch.4 The Reference Architecture](https://danielmeppiel.github.io/agentic-sdlc-handbook/handbook/ch04-the-reference-architecture.html), [Ch.12 The PROSE Specification](https://danielmeppiel.github.io/agentic-sdlc-handbook/handbook/ch12-the-prose-specification.html), and [Ch.18 Architectural Patterns Rosetta Stone](https://danielmeppiel.github.io/agentic-sdlc-handbook/handbook/ch18-architectural-patterns-rosetta-stone.html).

---

## ⏱️ Session flow

| Section | Focus | Duration | Format |
|---|---|---|---|
| **0 · Setup** | Use template, install deps, verify CLIs **and your harness** | 15 min | Individual |
| **1 · Pick your track** | One of four | 5 min | Choose |
| **2 · Design with Genesis** | Spec your skill *before* you write it (with an ASCII architecture diagram) | 10 min | Hands-on |
| **3 · Build locally** | Have your harness *generate* `SKILL.md` from the Genesis design (don't hand-type), drive it on `zava-storefront/` | 25 min | Hands-on |
| **4 · Validate + publish** | `gh skill publish --dry-run` → tag → release | 15 min | Hands-on |
| **5 · Automate in CI** | `gh aw compile` → label a PR → watch it run | 15 min | Hands-on |
| **6 · Consume from another repo** | Pin your skill in a partner repo via `apm` | 10 min | Demo |
| **Wrap-up** | What you shipped + how to extend tomorrow | 5 min | Discussion |

> ⏱️ **Honest budget:** Tracks 1–3 fit a 90-min hands-on slot for a developer with the prerequisites already installed. **Track 4 is a 30-min reference deep-dive**, not a build-from-scratch. First-timer setup variance (harness, `apm` install path, `gh skill` preview) realistically adds 10–15 min — see Section 0 below.

---

## ⚙️ Section 0 · Setup (15 min)

### Prerequisites

- [`apm`](https://github.com/microsoft/apm) — install path depends on your OS:
  - **macOS:** `brew install microsoft/apm/apm`
  - **Linux / WSL:** `curl -fsSL https://raw.githubusercontent.com/microsoft/apm/main/install.sh | bash`
  - **Windows (PowerShell):** see the [APM install docs](https://microsoft.github.io/apm/install) — the bash installer also works under WSL.
- [`gh`](https://cli.github.com) ≥ v2.90 — the `gh skill` subcommand we use is **preview**. If `gh skill --help` errors, run `gh extension install github/gh-skill` (auto-installed by the `release.yml` fallback path, but you want it locally for §4).
- [`gh aw`](https://github.com/githubnext/gh-aw) — `gh extension install github/gh-aw`. See the [security architecture](https://github.github.com/gh-aw/introduction/architecture/) if you want to understand the sandboxing + safe-outputs model before letting it run on your PRs.
- An **agent harness**: Copilot CLI / Claude Code / Codex / Cursor / OpenCode
- **Node.js ≥ 20** (for `zava-storefront/`)

### 1. Use this template

Click the green **"Use this template"** button at the top of this repo → **"Create a new repository"**. Pick your own org + name. Clone it locally.

### 2. Install dependencies

```bash
# from the root of the repo you generated in §1 (freshly cloned)

apm install                             # workshop kits + Genesis design assistant (pinned to v0.1.0)

# Clone the canonical target app at the pinned workshop baseline (tsc-clean, tests 7/7 green).
# It's gitignored — your generated workshop repo stays clean.
git clone --branch workshop-v1 --depth 1 https://github.com/DevExpGbb/zava-storefront.git zava-storefront
npm install --prefix zava-storefront    # Next.js + Postgres commerce slice (the workshop target)
```

`apm install` pulls in:

- The four **workshop kits** (`secure-baseline`, `code-kit`, `ideate-kit`, `review-kit`) — instructions, personas, hooks
- **Genesis** v0.1.0 — your design assistant for new skills (`/genesis` in your harness)

### 3. Verify CLIs and harness

```bash
# CLI smoke test (no network):
apm deps list                      # should list the 5 deps above
# Expected (abridged):
#   secure-baseline  v0.1.x  (DevExpGbb/secure-baseline)
#   code-kit         v0.1.x  (DevExpGbb/code-kit)
#   ideate-kit       v0.1.x  (DevExpGbb/ideate-kit)
#   review-kit       v0.1.x  (DevExpGbb/review-kit)
#   genesis          v0.1.0  (DevExpGbb/genesis)
ls .agents/skills/genesis          # should exist (proves apm install completed)

# Auth + repo permissions (you'll need write access for tags/releases/labels):
gh auth status                     # should show "Logged in to github.com as <you>"
gh repo view                       # should resolve to your generated repo

# Harness smoke test — verify /genesis is loaded:
#   • Copilot CLI / Claude Code / Codex: type `/genesis` in chat. Autocomplete should
#     suggest the persona, or it should respond when you ask "what skills are loaded?".
#   • Cursor / OpenCode: open the skills panel and confirm `genesis` is listed.
# If /genesis doesn't surface, re-run `apm install` and check .agents/skills/genesis exists.

# Test surface:
npm test --prefix zava-storefront       # 7 vitest specs should pass green

# Validation surface (only if `gh skill` is installed locally):
apm run validate                   # → gh skill publish --dry-run .apm
```

> ⚠️ **`gh skill` is in preview.** If `apm run validate` fails because the subcommand isn't installed, the CI release workflow has a fallback path — but for the local workshop, install it once: `gh extension install github/gh-skill`.

If the smoke tests pass and `/genesis` surfaces in your harness, you're ready.

### Reproducibility caveats (read once)

This workshop pins what it can and is honest about what it can't:

- **Pinned:** `apm`, the four workshop kits (`v5.0.1`), Genesis (`v0.1.0`), Node deps in `zava-storefront/` and `security-fixtures/`.
- **Not pinned (and you should know):**
  - **Model + harness drift.** The same `SKILL.md` does not produce byte-equivalent outputs across Copilot CLI / Claude Code / Cursor / Codex / OpenCode — tool-call grammar and refusal behaviors differ. The *artifact* (your `SKILL.md`) is reproducible; the model's transcript is not.
  - **`gh skill` preview surface.** API may change between workshops; the lockfile validates against `agent-skills.io` spec at the time of running.
  - **GitHub Actions queue weather** affects §5 timing — a "5-min CI run" can become 15 if the runner pool is hot.

The "your skill, my code" claim in §6 holds for the artifact + `allowed-tools` enforcement + lifecycle. It does **not** claim identical model output across harnesses.

---

## 🛤️ Section 1 · Pick your track (5 min)

Each track teaches the same loop on different content. Pick **ONE** based on what you'll do in your day job.

| Track | What your skill will do | Best for |
|---|---|---|
| 🧪 [**1 · `test-improver`**](docs/tracks/01-test-improver.md) | Find untested branches in `zava-storefront/lib/cart.ts` (and friends), generate vitest cases, iterate `npm test` until green | Devs who want to raise coverage in legacy code |
| 📖 [**2 · `docs-generator`**](docs/tracks/02-docs-generator.md) | Read `zava-storefront/lib/*.ts`, emit JSDoc + a README usage section without inventing behavior | Devs documenting brownfield modules |
| 🛡️ [**3 · `dependency-auditor`**](docs/tracks/03-dependency-auditor.md) | Run `npm audit` against `zava-storefront/security-fixtures/`, classify SAFE vs BREAKING upgrades, emit a remediation plan as PR comment | Security-minded devs working in dep-heavy repos |
| 🔄 [**4 · `framework-modernizer`**](docs/tracks/04-framework-modernizer.md) | Read a finished, eval-backed reference skill (Express 4 → 5) — author one new BC-NNN catalog entry for *your* migration. **Reference deep-dive (30 min), not a from-scratch build.** | Devs facing a major-version upgrade who want the pattern, not the artifact |

> 💡 Stuck choosing? Pick **`test-improver`** — it has the cleanest validation loop (`npm test` is the oracle).

Each track guide takes you through Sections 2–6 with track-specific content. Open your chosen track and follow it.

---

## 📂 What's in this repo

| Path | Purpose |
|---|---|
| `apm.yml` · `apm.lock.yaml` | Workshop kits + Genesis pinned. `apm install` reads this. |
| `.apm/skills/framework-modernizer/` | Track 4's worked example — eval-backed Express 4 → 5 reference skill |
| `zava-storefront/` *(cloned, gitignored)* | The canonical [DevExpGbb/zava-storefront](https://github.com/DevExpGbb/zava-storefront) — Next.js 14 + Postgres commerce repo. Cloned in §0.2. Tracks 1–3 target it. |
| `zava-storefront/security-fixtures/` | Standalone, intentionally-vulnerable npm package inside the storefront repo — Track 3's audit target. Not imported by the app. |
| `docs/tracks/` | Per-track exercise guides (Sections 2–6 expanded) |
| `docs/golden-examples/` | Reference `SKILL.md` per track — peek **after** you've drafted yours |
| `.github/workflows/release.yml` | Tag → validate → pack → GitHub Release on `v*.*.*` |
| `.github/workflows/my-workflow.md` | `gh aw` template — your skill running on labeled PRs |
| `.github/workflows/shared/apm.md` | Standard APM bootstrap shared module |

---

## 🌐 Section 6 · The platform claim

After Section 5, the same skill that runs in your IDE *also* runs as a `gh aw` workflow.

The final step proves the platform claim: **your skill, my code**. In any consumer repo, drop into their `apm.yml`:

```yaml
dependencies:
  apm:
    - <your-org>/<your-repo>#v0.1.0
```

Run `apm install` in their repo. Your skill is now theirs — same SKILL.md, same constraints, same lifecycle. Composable, versioned, reviewable.

That's the difference between an ad hoc prompt and a packaged Agent Skill: **distribution, lifecycle, and semantic versioning** — the same things you expect from any package manager.

---

## 🎓 What you took home

- **Design before code.** Genesis isn't a luxury — it's the architecture pass that prevents the monolith.
- **Skills ship like packages.** Tag → release → consumers pin. Same lifecycle as npm or pip.
- **Inner == outer loop.** Whatever runs in your IDE runs the same way in CI. No translation layer.

---

## 🔗 Going further

- *The Agentic SDLC Handbook* — full theory behind this workshop. Start with [Ch.4 The Reference Architecture](https://danielmeppiel.github.io/agentic-sdlc-handbook/handbook/ch04-the-reference-architecture.html), then [Ch.12 The PROSE Specification](https://danielmeppiel.github.io/agentic-sdlc-handbook/handbook/ch12-the-prose-specification.html) and [Ch.18 Architectural Patterns Rosetta Stone](https://danielmeppiel.github.io/agentic-sdlc-handbook/handbook/ch18-architectural-patterns-rosetta-stone.html).
- [`microsoft/apm`](https://github.com/microsoft/apm) and the [APM docs](https://microsoft.github.io/apm/) — the package manager you used to install kits and ship your skill.
- [`microsoft/apm-action`](https://github.com/microsoft/apm-action) — the GitHub Action for wiring `apm install` into any workflow (the building block under `shared/apm.md`).
- [`DevExpGbb/genesis`](https://github.com/DevExpGbb/genesis) — use `/genesis` in your harness on real problems, not just workshop ones.
- Open issues / send PRs on [zava-workshop-kit](https://github.com/DevExpGbb/zava-workshop-kit) — that's the deployer-facing entry point for running this workshop in your own org.

---

## 📝 Workshop reference

This template is **Artifact #5** of the Zava agentic SDLC workshop. Org administrators provisioning the workshop should start at [`DevExpGbb/zava-workshop-kit`](https://github.com/DevExpGbb/zava-workshop-kit).

#!/usr/bin/env node
/* eslint-disable */
/**
 * Eval runner for the dependency-auditor golden Skill.
 *
 * Two assertions, mirroring Track 4's pattern:
 *
 *   1. Run `npm audit --json` against zava-storefront/security-fixtures/
 *      and apply the SKILL's documented rubric (lines 39-43 of the golden).
 *      Diff classifications + fix versions against expected/classifications.txt.
 *
 *   2. Apply the rubric to a synthetic JSON that exercises the two branches
 *      not present in the live registry today (`fix-via-force` boolean and
 *      `manual-review` false), and diff against expected/synthetic.txt.
 *
 * Exit 0 on full match, 1 on any mismatch. Pure Node, no deps.
 *
 * Run from any cwd:  node docs/golden-examples/dependency-auditor.evals/run.js
 */

const fs = require('node:fs');
const path = require('node:path');
const { spawnSync } = require('node:child_process');

const EVALS_DIR = __dirname;
const REPO_ROOT = path.resolve(EVALS_DIR, '../../..');
const FIXTURES_DIR = path.join(REPO_ROOT, 'zava-storefront/security-fixtures');
const SYNTHETIC = path.join(EVALS_DIR, 'fixtures/manual-review-fixture.json');
const EXPECTED_LIVE = path.join(EVALS_DIR, 'expected/classifications.txt');
const EXPECTED_SYNTHETIC = path.join(EVALS_DIR, 'expected/synthetic.txt');

/**
 * Apply the rubric documented in docs/golden-examples/dependency-auditor.SKILL.md
 * lines 39-43. Keep this function in lock-step with the SKILL prose; if the
 * rubric ever changes, both files move together.
 */
function classify(fixAvailable) {
  if (fixAvailable === false || fixAvailable === undefined || fixAvailable === null) {
    return { kind: 'manual-review', fixVersion: '' };
  }
  if (fixAvailable === true) {
    return { kind: 'fix-via-force', fixVersion: '' };
  }
  if (typeof fixAvailable === 'object') {
    const kind = fixAvailable.isSemVerMajor ? 'breaking-bump' : 'safe-bump';
    return { kind, fixVersion: fixAvailable.version || '' };
  }
  return { kind: 'manual-review', fixVersion: '' };
}

function serialize(rows) {
  return rows
    .slice()
    .sort((a, b) => a.pkg.localeCompare(b.pkg))
    .map((r) => `${r.pkg}\t${r.severity}\t${r.kind}\t${r.fixVersion}`)
    .join('\n');
}

function loadExpected(file) {
  return fs
    .readFileSync(file, 'utf8')
    .split(/\r?\n/)
    .filter((l) => l && !l.startsWith('#'))
    .sort()
    .join('\n');
}

function classifyAuditJson(audit) {
  const out = [];
  const vulns = (audit && audit.vulnerabilities) || {};
  for (const [pkg, entry] of Object.entries(vulns)) {
    const { kind, fixVersion } = classify(entry.fixAvailable);
    out.push({ pkg, severity: entry.severity, kind, fixVersion });
  }
  return out;
}

function diff(label, actual, expected) {
  if (actual === expected) {
    const count = actual.split('\n').filter(Boolean).length;
    console.log(`  ✅ ${label} PASSED (${count} rows match expected)`);
    return true;
  }
  console.log(`  ❌ ${label} FAILED`);
  console.log('    --- expected ---');
  expected.split('\n').forEach((l) => console.log(`    ${l}`));
  console.log('    --- actual ---');
  actual.split('\n').forEach((l) => console.log(`    ${l}`));
  return false;
}

console.log('dependency-auditor rubric regression test');

// 1. Live audit against the security-fixtures tree.
console.log('\n[1/2] Live npm audit on zava-storefront/security-fixtures/');
if (!fs.existsSync(FIXTURES_DIR)) {
  console.log(`  ❌ fixtures dir missing: ${FIXTURES_DIR}`);
  console.log(`     Did you clone zava-storefront alongside the workshop? See README §0.`);
  process.exit(1);
}
// Ensure deps installed silently (idempotent if already present).
spawnSync('npm', ['install', '--no-audit', '--no-fund', '--silent'], {
  cwd: FIXTURES_DIR,
  stdio: 'ignore',
});
// `npm audit` exits 1 when vulns present — that's the happy path here.
const auditRes = spawnSync('npm', ['audit', '--json'], {
  cwd: FIXTURES_DIR,
  encoding: 'utf8',
});
let liveAudit;
try {
  liveAudit = JSON.parse(auditRes.stdout);
} catch (e) {
  console.log(`  ❌ npm audit did not emit JSON. stderr:\n${auditRes.stderr}`);
  process.exit(1);
}
const liveActual = serialize(classifyAuditJson(liveAudit));
const liveExpected = loadExpected(EXPECTED_LIVE);
const livePass = diff('live audit', liveActual, liveExpected);

// 2. Synthetic fixture for fix-via-force + manual-review branches.
console.log('\n[2/2] Synthetic audit (fix-via-force + manual-review branches)');
const synthetic = JSON.parse(fs.readFileSync(SYNTHETIC, 'utf8'));
const syntheticActual = serialize(classifyAuditJson(synthetic));
const syntheticExpected = loadExpected(EXPECTED_SYNTHETIC);
const syntheticPass = diff('synthetic', syntheticActual, syntheticExpected);

if (livePass && syntheticPass) {
  console.log('\n✅ dependency-auditor rubric regression PASSED');
  process.exit(0);
}
console.log('\n❌ dependency-auditor rubric regression FAILED');
console.log('\nIf [1/2] failed, the npm registry may have changed advisory shape since this');
console.log('test was written. Either update expected/classifications.txt to match the new');
console.log('reality, or pin the fixture deps and document the drift.');
process.exit(1);

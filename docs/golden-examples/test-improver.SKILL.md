---
name: test-improver
description: |
  Find untested branches in a single TypeScript source file under zava-storefront/lib/,
  generate the missing vitest cases, and iterate `npm test --prefix zava-storefront` until green.
license: MIT
allowed-tools: Read, Grep, Glob, Bash(npm:*), Edit
---

# test-improver

## When to use this skill

Invoke when:

- A source file under `zava-storefront/lib/*.ts` has exported functions
- The matching `zava-storefront/tests/<basename>.test.ts` lacks coverage for `throw` paths, conditional branches, or boundary cases
- The user asks to "improve test coverage on `zava-storefront/lib/<file>.ts`"

Do not invoke for: JavaScript sources, files outside `zava-storefront/lib/`, application route handlers under `zava-storefront/app/`, or non-test changes.

## Steps

1. **Read** the target source file under `zava-storefront/lib/` and identify exported functions, conditional branches, and `throw` statements.
2. **Compare** against the matching `tests/<basename>.test.ts`. List branches/error paths whose code paths are not asserted in any `it(...)` block.
3. **Author** new vitest `describe`/`it` blocks for the missing branches in the existing test file. Use `vitest`, not `node:test` or `jest`. Cover one missing branch per `it` block.
4. **Run** `npm test --prefix zava-storefront`. If failures, refine and retry. Stop after 5 iterations or when all branches are green.
5. **Emit** one summary comment listing each function name and the branches now covered.

## Outputs

- Extended `zava-storefront/tests/<basename>.test.ts` with new `describe`/`it` blocks
- One summary comment of the form: `Covered: addItem (quantity overflow), applyDiscount (VIP25 below threshold, FREESHIP, unknown code), computeTax (DE, US-CA, US-OR, default).`

## Constraints

- Never modify files in `zava-storefront/lib/` — this skill is read-only against the source under test
- Never modify route handlers under `zava-storefront/app/`
- Never change `zava-storefront/package.json` or test config
- Stop after 5 iterations even if branches remain — escalate via the summary comment

## Example invocation

> Use the test-improver skill on `zava-storefront/lib/cart.ts`.

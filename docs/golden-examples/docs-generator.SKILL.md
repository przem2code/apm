---
name: docs-generator
description: |
  Read a single TypeScript file under zava-storefront/lib/, insert JSDoc above every undocumented
  exported function based ONLY on what the source shows, and append a "## Usage" section to
  zava-storefront/README.md with one minimal example per exported function. Types, schemas, and
  zod exports are out of scope.
license: MIT
allowed-tools: Read, Grep, Glob, Edit
---

# docs-generator

## When to use this skill

Invoke when:

- A source file under `zava-storefront/lib/*.ts` has exported functions without JSDoc above them
- The user asks to "document `zava-storefront/lib/<file>.ts`"

Do not invoke for: JavaScript sources, files already fully documented, or files outside `zava-storefront/lib/`.

## Steps

1. **Read** every **exported function declaration** in the target file (skip `export type`, `export const <Schema> = z.object(...)`, and re-exports). Note: parameter names + types, return type, any `throw` statements.
2. **Insert** JSDoc directly above each exported function with `@param`, `@returns`, and `@throws` clauses **only for behaviors the source code makes explicit**. Do not invent error conditions, return shapes, or side effects. Do not document types, schemas, or zod exports.
3. **Verify** no edits land outside the target file or `zava-storefront/README.md`.
4. **Append** a `## Usage` section to `zava-storefront/README.md` (create the README if missing) with one minimal example per exported function. Examples must be valid TypeScript that imports from the documented file.
5. **Emit** a one-line summary listing the documented exported functions.

## Outputs

- Edited `zava-storefront/lib/<file>.ts` with JSDoc inserted above each affected export
- Extended `zava-storefront/README.md` with a `## Usage` section
- Summary line: `Documented: addItem, removeItem, applyDiscount, computeTax, totalize`

## Constraints

- Never describe behavior that is not in the source code
- Never edit `zava-storefront/tests/`, `zava-storefront/app/`, `zava-storefront/package.json`, or any other `lib/` file
- Never reformat or otherwise modify the body of any function — JSDoc only
- If a behavior cannot be inferred from the code, omit the `@throws` / `@returns` line entirely

## Example invocation

> Use the docs-generator skill on `zava-storefront/lib/cart.ts`.

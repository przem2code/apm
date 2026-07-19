#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
validator="$repo_root/scripts/validate-skill-frontmatter.sh"
fixture_root=$(mktemp -d)
trap 'rm -rf "$fixture_root"' EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assert_contains() {
  local output=$1
  local expected=$2

  [[ $output == *"$expected"* ]] ||
    fail "expected output to contain: $expected"
}

"$validator" "$repo_root" ||
  fail 'the repository should have valid skill frontmatter'

mkdir -p \
  "$fixture_root/.apm/skills/valid-directory" \
  "$fixture_root/.apm/skills/literal-block" \
  "$fixture_root/.apm/skills/missing-fence" \
  "$fixture_root/.apm/skills/bom-before-fence" \
  "$fixture_root/.apm/skills/missing-description" \
  "$fixture_root/.apm/skills/empty-description" \
  "$fixture_root/.apm/skills/empty-block-description" \
  "$fixture_root/.apm/skills/empty-name" \
  "$fixture_root/.apm/skills/wrong-directory-name" \
  "$fixture_root/.apm/skills/unclosed-frontmatter" \
  "$fixture_root/docs/golden-examples" \
  "$fixture_root/.claude/worktrees/ignored/.apm/skills/broken" \
  "$fixture_root/.codex/worktrees/ignored/docs/golden-examples"

cat > "$fixture_root/.apm/skills/valid-directory/SKILL.md" <<'EOF'
---
name: valid-directory
description: >-
  A valid directory-form skill.
---
EOF

cat > "$fixture_root/docs/golden-examples/valid-flat.SKILL.md" <<'EOF'
---
name: valid-flat
description: |
  A valid flat-form skill.
---
EOF

cat > "$fixture_root/.apm/skills/literal-block/SKILL.md" <<'EOF'
---
name: literal-block
description: block
---
EOF

cat > "$fixture_root/.apm/skills/missing-fence/SKILL.md" <<'EOF'
name: missing-fence
description: This file has no opening fence.
EOF

printf '\357\273\277---\nname: bom-before-fence\ndescription: invalid\n---\n' \
  > "$fixture_root/.apm/skills/bom-before-fence/SKILL.md"

cat > "$fixture_root/.apm/skills/missing-description/SKILL.md" <<'EOF'
---
name: missing-description
---
EOF

cat > "$fixture_root/.apm/skills/empty-block-description/SKILL.md" <<'EOF'
---
name: empty-block-description
description: >-

---
EOF

cat > "$fixture_root/.apm/skills/empty-description/SKILL.md" <<'EOF'
---
name: empty-description
description:
---
EOF

cat > "$fixture_root/.apm/skills/empty-name/SKILL.md" <<'EOF'
---
name: ""
description: The name is empty.
---
EOF

cat > "$fixture_root/.apm/skills/wrong-directory-name/SKILL.md" <<'EOF'
---
name: different-name
description: The declared name disagrees with its directory.
---
EOF

cat > "$fixture_root/docs/golden-examples/wrong-flat-name.SKILL.md" <<'EOF'
---
name: also-different
description: The declared name disagrees with its filename.
---
EOF

cat > "$fixture_root/.apm/skills/unclosed-frontmatter/SKILL.md" <<'EOF'
---
name: unclosed-frontmatter
description: This frontmatter never closes.
EOF

cat > "$fixture_root/.claude/worktrees/ignored/.apm/skills/broken/SKILL.md" <<'EOF'
This invalid file must be ignored.
EOF

cat > "$fixture_root/.codex/worktrees/ignored/docs/golden-examples/broken.SKILL.md" <<'EOF'
This invalid file must also be ignored.
EOF

set +e
output=$("$validator" "$fixture_root" 2>&1)
status=$?
set -e

[[ $status -eq 1 ]] ||
  fail "expected invalid fixture tree to exit 1, got $status"

assert_contains "$output" \
  '.apm/skills/missing-fence/SKILL.md:1: file must start'
assert_contains "$output" \
  '.apm/skills/bom-before-fence/SKILL.md:1: file must start'
assert_contains "$output" \
  '.apm/skills/missing-description/SKILL.md:1: frontmatter is missing a description key'
assert_contains "$output" \
  '.apm/skills/empty-description/SKILL.md:3: description must have a non-empty value'
assert_contains "$output" \
  '.apm/skills/empty-block-description/SKILL.md:3: description must have a non-empty value'
assert_contains "$output" \
  '.apm/skills/empty-name/SKILL.md:2: name must have a non-empty value'
assert_contains "$output" \
  ".apm/skills/wrong-directory-name/SKILL.md:2: name 'different-name' does not match path name 'wrong-directory-name'"
assert_contains "$output" \
  "docs/golden-examples/wrong-flat-name.SKILL.md:2: name 'also-different' does not match path name 'wrong-flat-name'"
assert_contains "$output" \
  '.apm/skills/unclosed-frontmatter/SKILL.md:1: frontmatter block is not closed'

[[ $output != *'.claude/worktrees/'* ]] ||
  fail 'Claude worktree files must not be scanned'
[[ $output != *'.codex/worktrees/'* ]] ||
  fail 'Codex worktree files must not be scanned'

printf 'PASS: skill frontmatter validator\n'

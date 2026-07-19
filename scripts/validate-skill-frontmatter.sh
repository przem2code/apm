#!/usr/bin/env bash

set -u

usage() {
  printf 'usage: %s [repo-root]\n' "${0##*/}" >&2
}

if (( $# > 1 )); then
  usage
  exit 2
fi

repo_root=${1:-.}
repo_root=${repo_root%/}
if [[ -z $repo_root ]]; then
  repo_root=/
fi

if [[ ! -d $repo_root ]]; then
  printf '%s: repository root is not a directory\n' "$repo_root" >&2
  exit 2
fi

violations=0
relative_path=

report_violation() {
  local line_number=$1
  local message=$2

  printf '%s:%s: %s\n' "$relative_path" "$line_number" "$message"
  violations=1
}

trim_whitespace() {
  local value=$1

  value=${value#"${value%%[![:space:]]*}"}
  value=${value%"${value##*[![:space:]]}"}
  printf '%s' "$value"
}

scalar_value() {
  local value

  value=$(trim_whitespace "$1")
  if [[ $value == \#* ]]; then
    value=
  elif [[ $value =~ ^(.*[^[:space:]])[[:space:]]+\#.*$ ]]; then
    value=${BASH_REMATCH[1]}
    value=$(trim_whitespace "$value")
  fi

  if [[ $value == '""' || $value == "''" ]]; then
    value=
  elif [[ $value == \"*\" && ${#value} -ge 2 ]]; then
    value=${value:1:${#value}-2}
  elif [[ $value == \'*\' && ${#value} -ge 2 ]]; then
    value=${value:1:${#value}-2}
  fi

  printf '%s' "$value"
}

validate_file() {
  local file=$1
  local line=
  local line_number=0
  local closed=0
  local name_seen=0
  local name_line=1
  local name_value=
  local description_seen=0
  local description_line=1
  local description_value=
  local description_block=0
  local description_is_block=0
  local description_block_has_content=0
  local raw_value=
  local expected_name=
  local filename=

  relative_path=${file#"$repo_root"/}

  while IFS= read -r line || [[ -n $line ]]; do
    ((line_number += 1))

    if (( line_number == 1 )); then
      if [[ $line != '---' ]]; then
        report_violation 1 'file must start with a --- frontmatter fence'
        return
      fi
      continue
    fi

    if [[ $line == '---' ]]; then
      closed=1
      break
    fi

    if (( description_block )); then
      if [[ -z $(trim_whitespace "$line") ]]; then
        continue
      fi
      if [[ $line == [[:space:]]* ]]; then
        description_block_has_content=1
        continue
      fi
      description_block=0
    fi

    if [[ $line =~ ^name:[[:space:]]*(.*)$ ]]; then
      name_seen=1
      name_line=$line_number
      name_value=$(scalar_value "${BASH_REMATCH[1]}")
    elif [[ $line =~ ^description:[[:space:]]*(.*)$ ]]; then
      description_seen=1
      description_line=$line_number
      raw_value=$(scalar_value "${BASH_REMATCH[1]}")
      if [[ $raw_value =~ ^[\|\>][0-9+-]*$ ]]; then
        description_block=1
        description_is_block=1
        description_block_has_content=0
        description_value=
      else
        description_is_block=0
        description_value=$raw_value
      fi
    fi
  done < "$file"

  if (( line_number == 0 )); then
    report_violation 1 'file must start with a --- frontmatter fence'
    return
  fi

  if (( ! closed )); then
    report_violation 1 'frontmatter block is not closed with ---'
  fi

  if (( ! name_seen )); then
    report_violation 1 'frontmatter is missing a name key'
  elif [[ -z $name_value ]]; then
    report_violation "$name_line" 'name must have a non-empty value'
  fi

  if (( ! description_seen )); then
    report_violation 1 'frontmatter is missing a description key'
  elif (( description_is_block )); then
    if (( ! description_block_has_content )); then
      report_violation "$description_line" 'description must have a non-empty value'
    fi
  elif [[ -z $description_value ]]; then
    report_violation "$description_line" 'description must have a non-empty value'
  fi

  if (( name_seen )) && [[ -n $name_value ]]; then
    filename=${file##*/}
    if [[ $filename == 'SKILL.md' ]]; then
      expected_name=${file%/*}
      expected_name=${expected_name##*/}
    else
      expected_name=${filename%.SKILL.md}
    fi

    if [[ $name_value != "$expected_name" ]]; then
      report_violation "$name_line" \
        "name '$name_value' does not match path name '$expected_name'"
    fi
  fi
}

while IFS= read -r -d '' skill_file; do
  validate_file "$skill_file"
done < <(
  find "$repo_root" \
    \( -type d \( -name .git -o -name node_modules \) -prune \) -o \
    \( -type d \( \
      -path "$repo_root/.claude/worktrees" -o \
      -path "$repo_root/.codex/worktrees" \
    \) -prune \) -o \
    \( -type f \( -name SKILL.md -o -name '*.SKILL.md' \) -print0 \)
)

exit "$violations"

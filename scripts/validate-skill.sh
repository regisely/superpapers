#!/usr/bin/env bash
# Validate a SKILL.md file for structural correctness.
# Usage: ./scripts/validate-skill.sh skills/<skill-name>/SKILL.md [max_words]
#
# Checks:
#   1. File exists
#   2. YAML frontmatter present with `name:` and `description:` fields
#   3. Description starts with "Use when"
#   4. Required sections present
#   5. Word count under budget (default 3750)
#   6. No placeholder markers

set -euo pipefail

file="${1:?usage: $0 <skill-file> [max_words]}"
max_words="${2:-3750}"

if [[ ! -f "$file" ]]; then
  echo "FAIL: $file does not exist" >&2
  exit 1
fi

errors=0

# Check frontmatter
if ! head -1 "$file" | grep -q '^---$'; then
  echo "FAIL: $file missing YAML frontmatter opening (---)" >&2
  errors=$((errors + 1))
fi

if ! grep -q '^name:' "$file"; then
  echo "FAIL: $file missing 'name:' field in frontmatter" >&2
  errors=$((errors + 1))
fi

if ! grep -q '^description:' "$file"; then
  echo "FAIL: $file missing 'description:' field in frontmatter" >&2
  errors=$((errors + 1))
fi

# Description must start with "Use when"
desc_line=$(grep '^description:' "$file" | head -1 || true)
if [[ -n "$desc_line" ]] && ! echo "$desc_line" | grep -qi 'Use when'; then
  echo "FAIL: $file description does not start with 'Use when'" >&2
  errors=$((errors + 1))
fi

# Required sections
for section in "## Overview" "## When to Use" "## Mandatory Steps" "## Anti-Patterns" "## Verification Before Completion"; do
  if ! grep -qF "$section" "$file"; then
    echo "FAIL: $file missing section: $section" >&2
    errors=$((errors + 1))
  fi
done

# Placeholder markers
if grep -iE '\b(TBD|TODO|FIXME|XXX)\b' "$file"; then
  echo "FAIL: $file contains placeholder markers (TBD/TODO/FIXME/XXX)" >&2
  errors=$((errors + 1))
fi

# Word count
word_count=$(wc -w < "$file")
if (( word_count > max_words )); then
  echo "FAIL: $file has $word_count words (max $max_words)" >&2
  errors=$((errors + 1))
fi

if (( errors > 0 )); then
  echo "FAIL: $file has $errors error(s)" >&2
  exit 1
fi

echo "OK: $file ($word_count words)"

#!/usr/bin/env bash
# Table quality gate: human-readable labels, booktabs rules, note formatting.
# Usage: ./check-tables.sh <dir-or-.tex-files...>   (typically: output/tables/)
#
# For every .tex file containing a tabular environment:
#   1. No raw code identifiers — flags escaped (\_) or raw underscores outside
#      math mode, the proxy for snake_case labels like cost\_income leaking
#      from the analysis code into headers or row labels.
#   2. booktabs discipline — \toprule/\bottomrule present, no \hline, no
#      vertical bars in the column spec.
#   3. Notes inside a tablenotes environment (threeparttable), with a reduced
#      font size (\footnotesize or \scriptsize).
#
# Output: one OK:/WARN:/FAIL: line per file per check. Exit 1 if any FAIL.

set -uo pipefail

if [[ $# -eq 0 ]]; then
  echo "usage: $0 <dir-or-.tex-files...>" >&2
  exit 1
fi

files=()
for arg in "$@"; do
  if [[ -d "$arg" ]]; then
    while IFS= read -r f; do files+=("$f"); done < <(find "$arg" -maxdepth 1 -name '*.tex' | sort)
  elif [[ -f "$arg" ]]; then
    files+=("$arg")
  else
    echo "FAIL: $arg does not exist"
    exit 1
  fi
done

fail=0
checked=0

for f in "${files[@]}"; do
  # Only check files that actually contain a table.
  grep -qE '\\begin\{(tabular|tabularx|longtable)' "$f" || continue
  checked=$((checked + 1))
  file_fail=0

  # --- 1. Code identifiers (underscores outside math mode) -------------------
  # Strip comments and $...$ math segments, then flag remaining underscores.
  ident_lines=$(sed -E 's/(^|[^\\])%.*//; s/\$[^$]*\$//g' "$f" | grep -nE '(\\_|_)' || true)
  if [[ -n "$ident_lines" ]]; then
    echo "$ident_lines" | head -5 | sed "s|^|  $f:|"
    echo "FAIL: $f — raw code identifiers (underscores) in table content; map every variable to a publication label (e.g. fixest etable dict / rename before export)"
    file_fail=1
  fi

  # --- 2. booktabs discipline -------------------------------------------------
  if grep -qE '^[^%]*\\hline' "$f"; then
    echo "FAIL: $f — uses \\hline; use booktabs \\toprule/\\midrule/\\bottomrule"
    file_fail=1
  fi
  if grep -qE '\\begin\{tabular[x]?\}\{[^}]*\|' "$f"; then
    echo "FAIL: $f — vertical bars in column spec; booktabs tables use no vertical rules"
    file_fail=1
  fi
  if ! grep -q '\\toprule' "$f" || ! grep -q '\\bottomrule' "$f"; then
    echo "FAIL: $f — missing \\toprule or \\bottomrule"
    file_fail=1
  fi

  # --- 3. Notes formatting -----------------------------------------------------
  if grep -qiE '(^|[^a-zA-Z])Notes?:' "$f"; then
    if ! grep -q 'tablenotes' "$f"; then
      echo "FAIL: $f — notes outside a tablenotes environment; wrap the table in threeparttable and put notes in tablenotes"
      file_fail=1
    elif ! grep -qE '\\(footnotesize|scriptsize|small)' "$f"; then
      echo "WARN: $f — notes without a reduced font size (\\footnotesize or \\scriptsize)"
    fi
  fi

  if [[ $file_fail -eq 0 ]]; then
    echo "OK: $f"
  else
    fail=1
  fi
done

if [[ $checked -eq 0 ]]; then
  echo "WARN: no .tex files with tabular environments found in: $*"
fi

if [[ $fail -ne 0 ]]; then
  echo "RESULT: FAIL — fix the tables in the generating scripts (never hand-edit output) and re-run"
  exit 1
fi
echo "RESULT: OK ($checked tables checked)"

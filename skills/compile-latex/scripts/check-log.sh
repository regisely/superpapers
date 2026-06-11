#!/usr/bin/env bash
# Post-compile quality gate: overfull boxes, undefined references, citation style.
# Usage: ./check-log.sh path/to/paper.tex [--citation-style=authoryear|numeric]
#
# Run AFTER compile.sh. Exit 0 means the compiled paper passes all checks.
# Checks:
#   1. No Overfull \hbox above 5pt in the .log (table/figure/prose overflow)
#   2. No undefined citations or references in the .log
#   3. Citation style matches the expected style (default: author-year)
#      - static: documentclass/package options that force numeric mode
#      - rendered: pdftotext scan of the PDF for numeric-citation patterns
#
# Output: one OK:/WARN:/FAIL: line per check. Exit 1 if any FAIL.

set -uo pipefail

file="${1:?usage: $0 <paper.tex> [--citation-style=authoryear|numeric]}"
style="authoryear"
for arg in "${@:2}"; do
  case "$arg" in
    --citation-style=authoryear) style="authoryear" ;;
    --citation-style=numeric)    style="numeric" ;;
    *) echo "FAIL: unknown argument $arg" >&2; exit 1 ;;
  esac
done

if [[ ! -f "$file" ]]; then
  echo "FAIL: $file does not exist"
  exit 1
fi

dir=$(dirname "$file")
base=$(basename "$file" .tex)
log="$dir/$base.log"
pdf="$dir/$base.pdf"
fail=0

# --- 1. Overfull \hbox -------------------------------------------------------
if [[ ! -f "$log" ]]; then
  echo "FAIL: no log file at $log — compile first (compile.sh)"
  exit 1
fi

overfull_fail=0
overfull_warn=0
while IFS= read -r line; do
  pts=$(echo "$line" | sed -nE 's/.*Overfull \\hbox \(([0-9.]+)pt too wide.*/\1/p')
  [[ -z "$pts" ]] && continue
  if awk -v p="$pts" 'BEGIN { exit !(p > 5) }'; then
    overfull_fail=$((overfull_fail + 1))
    echo "  overfull ${pts}pt: $line"
  else
    overfull_warn=$((overfull_warn + 1))
  fi
done < <(grep 'Overfull \\hbox' "$log" 2>/dev/null || true)

if [[ $overfull_fail -gt 0 ]]; then
  echo "FAIL: $overfull_fail Overfull \\hbox above 5pt — content bleeds into the margin (apply the tables-and-figures overflow ladder)"
  fail=1
elif [[ $overfull_warn -gt 0 ]]; then
  echo "WARN: $overfull_warn Overfull \\hbox of 5pt or less (tolerated)"
else
  echo "OK: no overfull boxes"
fi

# --- 2. Undefined citations / references -------------------------------------
undef=$(grep -cE "(Citation|Reference) .* undefined" "$log" 2>/dev/null) || undef=0
if [[ "$undef" -gt 0 ]]; then
  grep -E "(Citation|Reference) .* undefined" "$log" | head -10 | sed 's/^/  /'
  echo "FAIL: $undef undefined citations/references — fix keys or rerun the bibliography pass"
  fail=1
else
  echo "OK: no undefined citations or references"
fi

# --- 3a. Citation style: static preamble check -------------------------------
if [[ "$style" == "authoryear" ]]; then
  style_fail=0
  # Journal classes that load natbib internally need the class option.
  docclass=$(grep -E '^[^%]*\\documentclass' "$file" | head -1)
  if echo "$docclass" | grep -qE '\{elsarticle\}' && ! echo "$docclass" | grep -qE '\[[^]]*authoryear'; then
    echo "  $docclass"
    echo "FAIL: elsarticle without the authoryear class option renders numeric citations — use \\documentclass[...,authoryear]{elsarticle}"
    style_fail=1
  fi
  if grep -qE '^[^%]*\\usepackage\[[^]]*numbers[^]]*\]\{natbib\}' "$file"; then
    echo "FAIL: natbib loaded with the numbers option — expected author-year"
    style_fail=1
  fi
  if grep -qE '^[^%]*\\usepackage\[[^]]*style[[:space:]]*=[[:space:]]*numeric' "$file"; then
    echo "FAIL: biblatex loaded with a numeric style — expected author-year (style=authoryear)"
    style_fail=1
  fi
  if [[ $style_fail -eq 0 ]]; then
    echo "OK: preamble consistent with author-year citations"
  else
    fail=1
  fi
else
  echo "OK: numeric style requested (journal requirement) — static author-year checks skipped"
fi

# --- 3b. Citation style: rendered PDF check ----------------------------------
if [[ "$style" == "authoryear" ]]; then
  if [[ ! -f "$pdf" ]]; then
    echo "INCONCLUSIVE: no PDF at $pdf — rendered citation check skipped"
  elif command -v pdftotext >/dev/null 2>&1; then
    text=$(pdftotext "$pdf" - 2>/dev/null || true)
    numeric_n=$(echo "$text" | grep -oE '\[[0-9]+([,–-][0-9 ]+)*\]' | wc -l | tr -d ' ')
    if [[ "$numeric_n" -gt 3 ]]; then
      echo "$text" | grep -oE '\[[0-9]+([,–-][0-9 ]+)*\]' | head -5 | sed 's/^/  example: /'
      echo "FAIL: $numeric_n numeric-citation patterns like [1] in the rendered PDF — expected author-year"
      fail=1
    else
      echo "OK: rendered PDF shows no numeric-citation pattern"
    fi
  else
    echo "INCONCLUSIVE: pdftotext not available — rendered citation check skipped (static check still applies)"
  fi
fi

# ------------------------------------------------------------------------------
if [[ $fail -ne 0 ]]; then
  echo "RESULT: FAIL — fix the issues above and recompile before declaring the task complete"
  exit 1
fi
echo "RESULT: OK"

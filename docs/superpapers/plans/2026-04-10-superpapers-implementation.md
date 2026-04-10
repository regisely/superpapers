# Superpapers Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the complete `superpapers` Claude Code plugin — a standalone plugin for empirical quantitative research implementing 14 skills + 3 templates + plugin configuration, per the design spec at `docs/superpapers/specs/2026-04-09-superpapers-design.md`.

**Architecture:** Plugin follows Claude Code plugin conventions. Skills live in `skills/<name>/SKILL.md` with optional `references/` and `scripts/` subdirectories. 3 orchestration skills (`brainstorm`, `write-plan`, `execute-plan`) adapted for research, 11 domain skills (academic-baseline, replication-driven-research, compile-latex, literature-search, citation-management, data-collection, statistical-modeling, tables-and-figures, robustness-checks, journal-selection, journal-guidelines). Build in phases respecting dependencies: foundation → pipeline → analysis → submission → orchestration → templates.

**Tech Stack:** Markdown (SKILL.md files), JSON (plugin config), Bash (compile script, validation script), LaTeX (templates).

**Global rules for every SKILL.md:**
- English only (plugin internals are English; user output adapts — see Language Policy in spec)
- YAML frontmatter with `name` and `description` fields; description starts with `Use when...`
- Required sections: `## Overview`, `## When to Use`, `## Mandatory Steps`, `## Anti-Patterns`, `## Verification Before Completion`
- Under 5k tokens (~3750 words); lean, imperative prose
- No placeholder text (`TBD`, `TODO`, `FIXME`)
- Cross-references use skill names only (e.g., `replication-driven-research`), never `@` force-loads

---

## File Structure

**27 files total:**

```
superpapers/
├── .claude-plugin/
│   ├── plugin.json                                     # plugin metadata
│   └── marketplace.json                                # marketplace listing
├── README.md                                           # installation + usage
├── scripts/
│   └── validate-skill.sh                               # structural validator
├── skills/
│   ├── academic-baseline/SKILL.md                      # core principles
│   ├── replication-driven-research/SKILL.md            # reproducibility guardrail
│   ├── compile-latex/
│   │   ├── SKILL.md                                    # latex compilation guide
│   │   └── scripts/compile.sh                          # multi-pass compile wrapper
│   ├── literature-search/SKILL.md                      # web-verified lit search
│   ├── citation-management/SKILL.md                    # .bib + CrossRef
│   ├── data-collection/
│   │   ├── SKILL.md                                    # data collection process
│   │   └── references/common-sources.md                # starting-point sources
│   ├── statistical-modeling/
│   │   ├── SKILL.md                                    # modeling process
│   │   └── references/
│   │       ├── modeling-process.md                     # generic process guide
│   │       ├── cross-section.md                        # cross-section methods
│   │       ├── panel.md                                # panel methods
│   │       ├── causal-inference.md                     # causal methods
│   │       └── time-series.md                          # time series methods
│   ├── tables-and-figures/SKILL.md                     # latex tables + pdf figures
│   ├── robustness-checks/SKILL.md                      # robustness recipes
│   ├── journal-selection/SKILL.md                      # journal matching
│   ├── journal-guidelines/SKILL.md                     # submission formatting
│   ├── brainstorm/SKILL.md                             # research brainstorm orchestrator
│   ├── write-plan/SKILL.md                             # research plan orchestrator
│   └── execute-plan/SKILL.md                           # research execution orchestrator
└── templates/
    ├── CLAUDE.superpapers.md                           # project CLAUDE.md template
    ├── paper-skeleton.tex                              # minimal paper template
    └── replication-readme.md                           # replication package README template
```

---

## Task 1: Validation tooling

**Why first:** Every subsequent task will run this script to verify structural correctness before committing.

**Files:**
- Create: `scripts/validate-skill.sh`

- [ ] **Step 1: Create `scripts/` directory at repo root**

Run:
```bash
mkdir -p scripts
```

- [ ] **Step 2: Write validation script**

Create `scripts/validate-skill.sh` with exactly this content:

```bash
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
```

- [ ] **Step 3: Make executable**

Run:
```bash
chmod +x scripts/validate-skill.sh
```

- [ ] **Step 4: Verify script runs (expected: usage error since no file given)**

Run:
```bash
./scripts/validate-skill.sh 2>&1 || true
```

Expected output: `usage: ./scripts/validate-skill.sh <skill-file> [max_words]`

- [ ] **Step 5: Commit**

```bash
git add scripts/validate-skill.sh
git commit -m "add skill validation script"
```

---

## Task 2: Plugin manifest (plugin.json)

**Files:**
- Create: `.claude-plugin/plugin.json`

- [ ] **Step 1: Create `.claude-plugin/` directory**

```bash
mkdir -p .claude-plugin
```

- [ ] **Step 2: Write plugin.json**

Create `.claude-plugin/plugin.json` with exactly this content:

```json
{
  "name": "superpapers",
  "version": "0.1.0",
  "description": "Claude Code plugin for empirical quantitative research. Adapts the Superpowers pipeline (brainstorm, write-plan, execute-plan) for the full academic paper lifecycle with a replication-driven-research guardrail replacing TDD.",
  "author": {
    "name": "Regis A. Ely"
  },
  "homepage": "https://github.com/regisely/superpapers",
  "license": "MIT",
  "keywords": [
    "research",
    "academic",
    "economics",
    "econometrics",
    "statistics",
    "empirical",
    "paper",
    "latex",
    "replication",
    "reproducibility"
  ]
}
```

- [ ] **Step 3: Verify JSON is valid**

Run:
```bash
python3 -c "import json; json.load(open('.claude-plugin/plugin.json'))" && echo "OK"
```

Expected: `OK`

- [ ] **Step 4: Commit**

```bash
git add .claude-plugin/plugin.json
git commit -m "add plugin manifest"
```

---

## Task 3: Marketplace listing (marketplace.json)

**Files:**
- Create: `.claude-plugin/marketplace.json`

- [ ] **Step 1: Write marketplace.json**

Create `.claude-plugin/marketplace.json` with exactly this content:

```json
{
  "name": "superpapers",
  "owner": {
    "name": "Regis A. Ely"
  },
  "plugins": [
    {
      "name": "superpapers",
      "source": ".",
      "description": "Claude Code plugin for empirical quantitative research — brainstorm, plan, execute academic papers with replication-driven discipline. Covers literature search, data collection, statistical modeling, robustness, and journal submission. Field-agnostic: economics, political science, epidemiology, sociology, and more.",
      "category": "research",
      "tags": [
        "research",
        "academic",
        "economics",
        "statistics",
        "latex",
        "replication"
      ]
    }
  ]
}
```

- [ ] **Step 2: Verify JSON is valid**

Run:
```bash
python3 -c "import json; json.load(open('.claude-plugin/marketplace.json'))" && echo "OK"
```

Expected: `OK`

- [ ] **Step 3: Commit**

```bash
git add .claude-plugin/marketplace.json
git commit -m "add marketplace listing"
```

---

## Task 4: Top-level README

**Files:**
- Create: `README.md`

- [ ] **Step 1: Write README.md**

The README must contain these sections in order:

1. **Title and one-line description**
2. **What it is** — 2-3 paragraphs explaining the plugin's purpose and inspiration (Superpowers for research)
3. **Installation** — Instructions for `/plugin marketplace add <path>` with local-path example
4. **Skills overview** — Table listing all 14 skills grouped by phase (orchestration, foundation, pipeline, analysis, submission) with one-line descriptions
5. **Typical workflow** — Numbered walkthrough: user starts project → uses `brainstorm` → gets design → `write-plan` → gets tasks → `execute-plan` → builds paper
6. **Example prompts** — 5-6 sample prompts in English and Portuguese showing how to trigger skills (e.g., "I want to study the effect of X on Y", "Quero fazer um paper sobre...", "Help me collect data on unemployment")
7. **Project setup** — Point to `templates/CLAUDE.superpapers.md` as the starter template for new projects
8. **Language policy** — Short paragraph: plugin is English-only internally; papers can be written in any language
9. **License and author**

**Constraints:**
- English only
- Under 400 lines
- No emojis
- Use fenced code blocks for commands and JSON
- Link to the design spec at `docs/superpapers/specs/2026-04-09-superpapers-design.md`

- [ ] **Step 2: Verify no placeholder markers**

Run:
```bash
grep -iE '\b(TBD|TODO|FIXME|XXX)\b' README.md && echo "FAIL: placeholders found" || echo "OK: no placeholders"
```

Expected: `OK: no placeholders`

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "add top-level README"
```

---

## Task 5: `academic-baseline` skill

**Files:**
- Create: `skills/academic-baseline/SKILL.md`

**Token budget:** Under 1200 words. This is the leanest skill — pure principles, no narrative fluff.

- [ ] **Step 1: Create directory**

```bash
mkdir -p skills/academic-baseline
```

- [ ] **Step 2: Write SKILL.md**

Frontmatter (exact):
```yaml
---
name: academic-baseline
description: Use when working on any empirical academic research context — paper writing, data analysis, literature review, or any task involving citations, results, or publication artifacts. Establishes non-negotiable principles that govern all other superpapers skills.
---
```

Required sections and content:

**## Overview** — 2-3 sentences: this skill is the "constitution" of superpapers; it sets inviolable rules that every other skill must respect; load it early in any research session.

**## When to Use** — bullet list of triggers: starting a research project, analyzing data, writing a paper section, reviewing results, preparing for submission, any time the user talks about papers, journals, citations, regressions, or data.

**## Core Principles** — 8 principles, each with 2-3 lines of explanation. Use exact phrasing:

1. **Never fabricate citations.** Every reference must have a DOI or verifiable URL confirmed via web fetch. Citing from memory is forbidden. If a source cannot be verified, mark it as `[unverified]` explicitly.
2. **Replication is mandatory.** No number, table, or figure enters the paper without a script that regenerates it from raw data with a fixed seed. Manual copying is forbidden.
3. **LaTeX is the default output format.** Tables use `booktabs` + `threeparttable`. Figures are vector PDFs. Papers are `.tex`, not Word documents, unless the journal explicitly requires otherwise.
4. **Distinguish causal from correlational claims.** Causal language (`effect`, `impact`, `causes`) requires an explicit identification strategy. When in doubt, use correlational language (`associated with`, `correlated with`, `related to`).
5. **YAGNI applies to robustness.** Include canonical robustness checks for the chosen design. Do not pile on 30 tests to impress referees.
6. **Exploratory is not confirmatory.** If a result was found by exploring the data, declare it as exploratory. Do not retroactively frame it as a prior hypothesis (HARKing).
7. **Numerical integrity is non-negotiable.** Fix the random seed. Document package versions. Never hardcode intermediate results in the paper.
8. **Respect the user's paper language.** Plugin internals and code are English-only. Paper content (abstracts, sections, table notes, figure captions) follows the user's chosen language, detected from `CLAUDE.superpapers.md` or explicit instruction.

**## Mandatory Steps** — Numbered list: (1) check for `CLAUDE.superpapers.md` in the project root and load its settings, (2) apply the principles above to any recommendation or action, (3) flag any violation explicitly when working with the user, (4) when a user asks for something that violates a principle, state the conflict and propose an alternative.

**## Anti-Patterns** — Bullet list:
- Generating a citation without verifying DOI/URL
- Writing a number into the paper without a script to regenerate it
- Using causal language ("X causes Y") for a design without identification
- Adding more than the canonical robustness checks "just in case"
- Running the analysis with a different seed each time

**## Verification Before Completion** — Checklist:
- [ ] All citations are verifiable
- [ ] All numerical results have generating scripts
- [ ] Causal language matches the identification strategy
- [ ] User's paper language is respected
- [ ] No principle violations flagged as open

- [ ] **Step 3: Validate**

Run:
```bash
./scripts/validate-skill.sh skills/academic-baseline/SKILL.md 1200
```

Expected: `OK: skills/academic-baseline/SKILL.md (<N> words)` with N ≤ 1200.

- [ ] **Step 4: Commit**

```bash
git add skills/academic-baseline/SKILL.md
git commit -m "add academic-baseline skill"
```

---

## Task 6: `replication-driven-research` skill

**Files:**
- Create: `skills/replication-driven-research/SKILL.md`

**Token budget:** Under 3000 words. This is the heart of the plugin — the most detailed domain skill.

- [ ] **Step 1: Create directory**

```bash
mkdir -p skills/replication-driven-research
```

- [ ] **Step 2: Write SKILL.md**

Frontmatter (exact):
```yaml
---
name: replication-driven-research
description: Use when starting empirical analysis, creating a data pipeline, generating results, or when data/model specifications change. Enforces end-to-end reproducibility: every number in the paper must be regenerable from raw data by a script with a fixed seed. Replaces TDD for the research domain.
---
```

**## Overview** — Explain the core principle in 3-4 sentences: same philosophy as TDD (evidence before claims, automated verification, invalidation on input change) but adapted to empirical research. No result is valid until the pipeline runs end-to-end without error.

**## When to Use** — Triggers:
- Start of a new empirical project
- First time running analysis code
- Before generating any table or figure for a paper
- After any change to raw data, sample selection, or model specification
- Before declaring a result "final"
- When the user asks "is this reproducible?"

**## Canonical Directory Structure**

Show exactly:
```
project-root/
├── data/
│   ├── raw/                    # raw downloads, never manually edited
│   ├── processed/              # cleaned data, output of scripts
│   └── manifest.md             # documents every dataset (source, URL, date, variables)
├── code/
│   ├── 01_collect.R            # or .py — fetches raw data
│   ├── 02_clean.R              # raw → processed
│   ├── 03_analyze.R            # processed → results
│   └── 04_figures.R            # processed → figures
├── output/
│   ├── tables/                 # .tex files generated by scripts
│   ├── figures/                # .pdf vector files generated by scripts
│   └── logs/                   # execution logs with timestamp + seed
├── paper/
│   ├── paper.tex               # main document
│   ├── references.bib          # bibliography
│   └── sections/               # split sections if needed
└── CLAUDE.superpapers.md       # project settings
```

Explain: on first invocation in a project, propose this structure. User can accept, adapt, or refuse. If user refuses, skill still works but flags deviations when encountered.

**## Mandatory Steps** — Numbered, imperative:

1. **Verify or scaffold structure.** If `data/raw`, `code/`, and `output/` do not exist, propose scaffolding. Wait for user confirmation before creating directories.
2. **Document every dataset in `data/manifest.md`.** Required fields per dataset: name, source (URL or API), description, collection date, variables used, frequency, period covered, license/usage notes.
3. **Every result must have a generating script.** No exceptions. Paste of numbers into the paper is forbidden. Tables use `\input{output/tables/...}`, figures use `\includegraphics{output/figures/...}`.
4. **Fix the seed in every script that uses randomness.** Document the seed in the script header. Use the project-level default from `CLAUDE.superpapers.md` unless overridden.
5. **Run the pipeline end-to-end before declaring any result verified.** Use a top-level `run_all.sh` (or `make`) that executes scripts in order. Verify exit code 0 and that all expected outputs exist.
6. **Log every run.** Each execution writes to `output/logs/YYYY-MM-DD_HH-MM-SS.log` with: timestamp, seed, package versions, runtime, input file hashes, exit status.
7. **Invalidate on input change.** If `data/raw` or a script changes, all downstream outputs are stale. Re-run the pipeline. Do not trust cached results.

**## Manifest Format**

Show example `data/manifest.md` entry:
```markdown
## unemployment_br

- **Source:** IBGE — PNADC Trimestral
- **URL:** https://sidra.ibge.gov.br/tabela/4099
- **Collected:** 2026-03-15
- **Variables:** unemployment_rate, quarter, state
- **Frequency:** Quarterly
- **Period:** 2012Q1 – 2025Q4
- **Collected by:** code/01_collect.R
- **License:** IBGE open data
```

**## Execution Log Format**

Show example log entry (plain text, one line per field):
```
timestamp: 2026-04-10T14:23:45-03:00
seed: 20260410
R version: 4.4.1
renv lockfile hash: abc123...
inputs:
  data/raw/pnadc.csv: sha256:def456...
scripts:
  code/01_collect.R: OK (4.2s)
  code/02_clean.R: OK (12.8s)
  code/03_analyze.R: OK (45.1s)
outputs:
  output/tables/tab_descriptives.tex: created
  output/tables/tab_main.tex: created
  output/figures/fig_trend.pdf: created
exit: 0
total runtime: 62.1s
```

**## Anti-Patterns** — Bullet list:
- Copying a number from console output into the paper
- "It worked yesterday" without re-running after a change
- Results with no traceable script
- Undocumented manual steps in the pipeline
- Using `set.seed(Sys.time())` or no seed at all
- Ignoring warnings from the pipeline run
- Running only one script and trusting cached outputs from others
- Editing raw data files manually

**## Verification Before Completion** — Checklist:
- [ ] `data/raw/` contains only downloaded files, never hand-edited
- [ ] `data/manifest.md` documents every dataset
- [ ] Every `.tex` table and `.pdf` figure in `output/` has a script that generates it
- [ ] A top-level runner exists and runs end-to-end with exit code 0
- [ ] Seeds are fixed and documented
- [ ] An execution log exists for the latest run
- [ ] No numeric values hardcoded in `paper.tex`

- [ ] **Step 3: Validate**

Run:
```bash
./scripts/validate-skill.sh skills/replication-driven-research/SKILL.md 3000
```

Expected: `OK` with word count ≤ 3000.

- [ ] **Step 4: Commit**

```bash
git add skills/replication-driven-research/SKILL.md
git commit -m "add replication-driven-research skill"
```

---

## Task 7: `compile-latex` skill + compile script

**Files:**
- Create: `skills/compile-latex/SKILL.md`
- Create: `skills/compile-latex/scripts/compile.sh`

**Token budget:** SKILL.md under 1500 words.

- [ ] **Step 1: Create directory structure**

```bash
mkdir -p skills/compile-latex/scripts
```

- [ ] **Step 2: Write compile script**

Create `skills/compile-latex/scripts/compile.sh` with exactly this content:

```bash
#!/usr/bin/env bash
# Multi-pass LaTeX compiler with engine auto-detection.
# Usage: ./compile.sh path/to/paper.tex
#
# Detects:
#   - Engine: xelatex if preamble has \usepackage{fontspec}, else pdflatex
#   - Bibliography: biber if \usepackage{biblatex}, bibtex if \bibliography{}, none otherwise
#
# Strategy:
#   1. First pass with the chosen engine
#   2. Run biber/bibtex if applicable
#   3. Second pass
#   4. Third pass to resolve cross-references
#
# If latexmk is available, prefer it.

set -euo pipefail

file="${1:?usage: $0 <paper.tex>}"

if [[ ! -f "$file" ]]; then
  echo "FAIL: $file does not exist" >&2
  exit 1
fi

dir=$(dirname "$file")
base=$(basename "$file" .tex)

# Detect engine
if grep -qE '^[^%]*\\usepackage\{?fontspec\}?' "$file"; then
  engine="xelatex"
else
  engine="pdflatex"
fi

# Detect bibliography system
bib_system="none"
if grep -qE '^[^%]*\\usepackage(\[.*\])?\{biblatex\}' "$file"; then
  bib_system="biber"
elif grep -qE '^[^%]*\\bibliography\{' "$file"; then
  bib_system="bibtex"
fi

echo "engine: $engine"
echo "bibliography: $bib_system"

# Prefer latexmk if available
if command -v latexmk >/dev/null 2>&1; then
  echo "using latexmk"
  case "$engine" in
    xelatex)
      latexmk -xelatex -interaction=nonstopmode -halt-on-error -cd "$file"
      ;;
    pdflatex)
      latexmk -pdf -interaction=nonstopmode -halt-on-error -cd "$file"
      ;;
  esac
  exit $?
fi

# Manual multi-pass
cd "$dir"

run_engine() {
  "$engine" -interaction=nonstopmode -halt-on-error "$base.tex"
}

echo "pass 1"
run_engine || { echo "FAIL: first pass" >&2; exit 1; }

case "$bib_system" in
  biber)
    echo "biber"
    biber "$base" || { echo "FAIL: biber" >&2; exit 1; }
    ;;
  bibtex)
    echo "bibtex"
    bibtex "$base" || { echo "FAIL: bibtex" >&2; exit 1; }
    ;;
esac

if [[ "$bib_system" != "none" ]]; then
  echo "pass 2"
  run_engine || { echo "FAIL: second pass" >&2; exit 1; }
fi

echo "pass 3"
run_engine || { echo "FAIL: third pass" >&2; exit 1; }

echo "OK: $base.pdf"
```

- [ ] **Step 3: Make script executable**

```bash
chmod +x skills/compile-latex/scripts/compile.sh
```

- [ ] **Step 4: Write SKILL.md**

Frontmatter (exact):
```yaml
---
name: compile-latex
description: Use when compiling a LaTeX paper, debugging LaTeX errors, building a paper PDF, or when a .tex file fails to produce output. Handles engine detection (xelatex vs pdflatex), bibliography systems (biber vs bibtex), and multi-pass compilation.
---
```

**## Overview** — 2-3 sentences: this skill compiles LaTeX documents correctly with the right engine and bibliography system, handles multi-pass compilation, and parses errors to suggest fixes.

**## When to Use** — Triggers:
- Compiling any `.tex` file
- "The paper won't compile"
- LaTeX error messages in output
- Generating the final PDF for submission
- CI/CD build of a paper
- Checking if a reference resolves correctly

**## Mandatory Steps**:

1. **Detect the engine from the preamble.** Look for `\usepackage{fontspec}`. If present, use `xelatex`. Otherwise use `pdflatex`.
2. **Detect the bibliography system.** `\usepackage{biblatex}` → biber. `\bibliography{...}` → bibtex. Neither → no bibliography pass.
3. **Prefer `latexmk` if available.** It handles multi-pass logic automatically.
4. **If `latexmk` is unavailable, run the manual sequence:** engine → bib (if applicable) → engine → engine.
5. **On error: parse the log file** (`<base>.log`), extract lines starting with `!`, report the line number and file, suggest likely fix.
6. **Verify the PDF was produced** after successful compilation.

**## Using the wrapper script**

Invoke:
```bash
./skills/compile-latex/scripts/compile.sh paper/paper.tex
```

The script detects engine and bib system, runs latexmk if available, falls back to manual multi-pass otherwise, and exits non-zero on failure.

**## Common Errors and Fixes**

Show a short table:

| Error | Cause | Fix |
|-------|-------|-----|
| `Undefined control sequence \foo` | Missing package | Add `\usepackage{pkg}` providing `\foo` |
| `File 'x.sty' not found` | Missing package | Install TeX package (`tlmgr install x`) |
| `Citation 'X' undefined` | Bib pass not run | Run biber/bibtex then re-run engine |
| `Missing \begin{document}` | Preamble typo | Check brace balance in preamble |
| `Package fontspec Error` | Used pdflatex instead of xelatex | Switch engine |
| `Overfull \hbox` | Typographical warning | Often safe to ignore, or rephrase |

**## Anti-Patterns**:
- Running `pdflatex` on a document that needs `xelatex`
- Ignoring `Citation undefined` warnings
- Single-pass compilation when cross-references exist
- Committing `.aux`, `.log`, `.bbl`, `.out` auxiliary files
- Ignoring errors and just "running it again"

**## Verification Before Completion** — Checklist:
- [ ] Engine detected matches preamble requirements
- [ ] Bibliography system correctly identified
- [ ] Multi-pass executed when needed
- [ ] Exit code 0 from the compile step
- [ ] `<base>.pdf` exists and is non-empty
- [ ] No `Undefined` warnings in the log

- [ ] **Step 5: Validate SKILL.md**

Run:
```bash
./scripts/validate-skill.sh skills/compile-latex/SKILL.md 1500
```

Expected: `OK`.

- [ ] **Step 6: Smoke-test compile.sh**

Run (expected: usage error):
```bash
./skills/compile-latex/scripts/compile.sh 2>&1 || true
```

Expected output: `usage: ./skills/compile-latex/scripts/compile.sh <paper.tex>`

- [ ] **Step 7: Commit**

```bash
git add skills/compile-latex/
git commit -m "add compile-latex skill and multi-pass script"
```

---

## Task 8: `literature-search` skill

**Files:**
- Create: `skills/literature-search/SKILL.md`

**Token budget:** Under 1800 words.

- [ ] **Step 1: Create directory**

```bash
mkdir -p skills/literature-search
```

- [ ] **Step 2: Write SKILL.md**

Frontmatter (exact):
```yaml
---
name: literature-search
description: Use when the user asks to search for papers, review literature, find references on a topic, verify a paper exists, or build a bibliography. Enforces web verification of every citation via web fetch to prevent hallucinated references.
---
```

**## Overview** — 2-3 sentences on the primary anti-pattern this skill prevents (hallucination of citations) and the verification requirement (every paper must be web-fetched and confirmed).

**## When to Use** — Triggers:
- "What does the literature say about X?"
- "Find papers on Y"
- "Who wrote the seminal paper on Z?"
- Building a reference list for a new project
- Verifying that a paper exists
- Checking the correct citation for a known paper

**## Mandatory Steps**:

1. **Identify the research field from context.** Check `CLAUDE.superpapers.md`, the project abstract, or ask the user. Field determines which databases to search.
2. **Choose databases based on field:**
   - **Core (any field):** Google Scholar, Web of Science, JSTOR, Semantic Scholar
   - **Economics / finance:** SSRN, NBER, RePEc, ScienceDirect
   - **Health / medicine:** PubMed, Cochrane Library
   - **Political science / sociology:** JSTOR, SAGE Journals
   - **Physical / computer sciences:** arXiv, ACM, IEEE
3. **Search with specific queries, not broad terms.** Include methodology keywords when relevant (e.g., `"difference-in-differences" minimum wage`).
4. **For every candidate paper: web fetch the landing page.** Confirm title, authors, year, DOI. If the paper cannot be fetched and verified, mark it as `[unverified]` and exclude from the final list.
5. **Output a markdown table** with columns: `Authors (Year)`, `Title`, `Journal/Venue`, `DOI`, `Relevance`. Keep relevance to one line.
6. **Curate, don't dump.** Prioritize: seminal works, recent (last 5 years), highly cited, and papers directly addressing the user's question. Aim for 8-15 results per query.

**## Output Format**

Show example table:
```markdown
| Authors (Year) | Title | Venue | DOI | Relevance |
|---|---|---|---|---|
| Card & Krueger (1994) | Minimum Wages and Employment | AER | 10.xxxx/xxxxx | Seminal DiD on min wage; identifies employment effects |
| Dube et al. (2010) | Minimum Wage Effects Across State Borders | ReStat | 10.xxxx/xxxxx | Border-pair design, no disemployment effect |
```

**## Anti-Patterns**:
- **Primary: fabricating a paper that does not exist.** Listing "Smith (2021), _Some Plausible Title_" without verification.
- Citing from memory without web fetch
- Listing 30 papers without curation
- Including working papers alongside published versions without distinction
- Confusing a journal article with a book chapter or conference paper
- Listing papers outside the user's field
- Returning results without DOIs

**## Verification Before Completion** — Checklist:
- [ ] Every paper in the final list was fetched via web
- [ ] Every paper has a verified DOI or stable URL
- [ ] No `[unverified]` entries in the final table
- [ ] Field-appropriate databases were used
- [ ] Relevance column is populated
- [ ] Results curated, not dumped

- [ ] **Step 3: Validate**

```bash
./scripts/validate-skill.sh skills/literature-search/SKILL.md 1800
```

- [ ] **Step 4: Commit**

```bash
git add skills/literature-search/SKILL.md
git commit -m "add literature-search skill"
```

---

## Task 9: `citation-management` skill

**Files:**
- Create: `skills/citation-management/SKILL.md`

**Token budget:** Under 1500 words.

- [ ] **Step 1: Create directory**

```bash
mkdir -p skills/citation-management
```

- [ ] **Step 2: Write SKILL.md**

Frontmatter (exact):
```yaml
---
name: citation-management
description: Use when adding citations to a .bib file, importing references by DOI, cleaning a bibliography, detecting duplicate entries, or normalizing citation keys. Uses direct .bib manipulation with CrossRef API for metadata resolution — no external tool dependencies.
---
```

**## Overview** — 2 sentences: this skill manages the project's `references.bib` directly using CrossRef to resolve DOIs into complete BibTeX entries, without requiring Zotero or any external tool.

**## When to Use** — Triggers:
- "Add this paper to the bibliography"
- "Import this DOI"
- "Clean up the .bib file"
- "Are there duplicates in my references?"
- "Fix the citation keys"

**## Mandatory Steps**:

1. **Resolve every DOI via CrossRef.** Call `https://api.crossref.org/works/{doi}`. Extract: title, authors (full list), year, journal, volume, issue, pages, publisher, DOI.
2. **Generate a BibTeX entry with complete fields.** Required: `author`, `title`, `year`, `doi`. For articles: also `journal`, `volume`, `pages`. For books: also `publisher`.
3. **Citation key format:** `FirstAuthorLastnameYear`, e.g., `Santos2024`. Disambiguate collisions with lowercase letters: `Santos2024a`, `Santos2024b`. Strip accents and non-ASCII characters from the key.
4. **Check for duplicates before adding.** Duplicate definition: same DOI, OR same title (case-insensitive, normalized whitespace) AND same first author AND same year. If duplicate, skip and report.
5. **Keep `references.bib` sorted alphabetically by citation key.** Run the sort after every insert.
6. **Preserve existing entries.** Do not rewrite fields of existing entries unless explicitly asked. Append new entries.

**## CrossRef API Example**

Show:
```bash
curl -s 'https://api.crossref.org/works/10.1257/aer.84.4.772' | jq '.message | {title, author, issued, container-title, volume, page, DOI}'
```

**## BibTeX Entry Template**

Show:
```bibtex
@article{CardKrueger1994,
  author  = {Card, David and Krueger, Alan B.},
  title   = {Minimum Wages and Employment: A Case Study of the Fast-Food Industry in New Jersey and Pennsylvania},
  journal = {American Economic Review},
  year    = {1994},
  volume  = {84},
  number  = {4},
  pages   = {772--793},
  doi     = {10.1257/aer.84.4.772}
}
```

**## Anti-Patterns**:
- BibTeX entries with missing DOIs
- Inconsistent citation keys in the same file (mix of `santos2024` and `Santos_2024`)
- Duplicate entries (same DOI or same paper with different keys)
- Entries with "et al." in the author field instead of full author list
- Using `{`braces`}` to preserve capitalization incorrectly
- Editing a paper's existing entry without being asked
- Adding metadata from memory instead of CrossRef

**## Verification Before Completion** — Checklist:
- [ ] Every new entry has a DOI field
- [ ] Every entry has full author list (not "et al.")
- [ ] Citation keys follow `AuthorYear[letter]` format
- [ ] No duplicates detected
- [ ] File sorted alphabetically by key
- [ ] Existing entries untouched unless explicitly asked to modify

- [ ] **Step 3: Validate**

```bash
./scripts/validate-skill.sh skills/citation-management/SKILL.md 1500
```

- [ ] **Step 4: Commit**

```bash
git add skills/citation-management/SKILL.md
git commit -m "add citation-management skill"
```

---

## Task 10: `data-collection` skill

**Files:**
- Create: `skills/data-collection/SKILL.md`
- Create: `skills/data-collection/references/common-sources.md`

**Token budget:** SKILL.md under 2000 words; common-sources.md under 2500 words.

- [ ] **Step 1: Create directories**

```bash
mkdir -p skills/data-collection/references
```

- [ ] **Step 2: Write SKILL.md**

Frontmatter (exact):
```yaml
---
name: data-collection
description: Use when collecting data for a research project, downloading time series, building a dataset, accessing economic or social data APIs, or scraping data from a non-API source. Handles source discovery, respectful collection, local caching, and manifest documentation.
---
```

**## Overview** — 2-3 sentences: this skill guides data collection from research question to versionable artifact. It is field-agnostic and open-ended about sources — references are a starting point, not a boundary.

**## When to Use** — Triggers:
- "I need data on X"
- "Download the unemployment series"
- "Build a dataset of country-level GDP"
- "Scrape this website for paper data"
- "Where can I get data about Y?"

**## Mandatory Steps**:

1. **Identify data needs from the research question.** Variables, units (country, firm, individual), frequency, period, geography.
2. **Find appropriate sources.** Start with `references/common-sources.md`. If the user's needs are not covered, search the web for the relevant source. Never invent a URL.
3. **Prefer APIs over scraping.** APIs are versioned, documented, and legal. Scraping is last resort.
4. **When scraping is necessary, be respectful:**
   - Check and honor `robots.txt`
   - Rate limit: minimum 1 request per second, often slower
   - Exponential backoff on errors
   - Identifiable user agent with contact info
   - Cache aggressively — never re-download unnecessarily
   - **Never scrape a source that explicitly prohibits it**
5. **Save raw data in `data/raw/`** in a versionable format: Parquet preferred, CSV acceptable. Never edit raw files by hand.
6. **Document every dataset in `data/manifest.md`** following the format from `replication-driven-research`: source, URL, collection date, variables, frequency, period, license.
7. **Cache locally.** Check `data/raw/` before re-fetching. Invoke network only if the file is missing or the user explicitly requested a refresh.

**## Source Discovery Process**

Process order: (1) check `references/common-sources.md`, (2) web search for "<topic> open data API", (3) check Dataverse, Zenodo, OSF for research-data repositories, (4) check the topic's primary institutional source (central bank, statistical agency, international org).

**## Anti-Patterns**:
- Scraping a source whose `robots.txt` prohibits it
- Hitting an API without rate limiting
- Re-downloading data that already exists in `data/raw/`
- Raw data without a manifest entry
- Editing a raw data file manually
- Collecting data without specifying the period and frequency
- Trusting a URL invented from memory

**## Verification Before Completion** — Checklist:
- [ ] Data saved under `data/raw/` in versionable format
- [ ] Manifest entry added for the new dataset
- [ ] Collection script in `code/` (not an interactive session)
- [ ] Source license checked and respected
- [ ] Cache honored — no unnecessary re-downloads
- [ ] Rate limiting applied for scraping

- [ ] **Step 3: Write `references/common-sources.md`**

Structure: top-level heading "Common Data Sources", then subsections by domain. Each source entry:

```markdown
### Source Name

- **URL:** https://...
- **API:** yes/no; endpoint if yes
- **Coverage:** geographic / temporal
- **License:** open / restricted / academic
- **R packages:** (if any, e.g., `rbcb`, `sidrar`)
- **Python packages:** (if any, e.g., `python-bcb`)
- **Notes:** one-line usage tip
```

Domains to cover (one subsection per domain, with 3-8 sources per subsection):

1. **Brazil — Economics & Finance:** SGS/BCB, SIDRA/IBGE, Ipeadata, CVM, B3, Tesouro Nacional
2. **International — Economics & Finance:** FRED, World Bank Open Data, IMF, OECD, Penn World Table, Comtrade, BIS
3. **Financial / Accounting:** WRDS, Compustat, CRSP, Bloomberg
4. **Social Sciences — General:** ICPSR, Harvard Dataverse, UK Data Service, Eurostat, UN Data
5. **Health & Epidemiology:** WHO, CDC, PubMed datasets, NHANES, DataSUS (Brazil)
6. **Political Science:** V-Dem, Polity, Correlates of War, Manifesto Project
7. **Environmental:** NOAA, NASA Earth Data, Copernicus, Our World in Data
8. **Open Science Repositories:** Harvard Dataverse, Zenodo, Open Science Framework, figshare

End with a note: "This list is a starting point, not a boundary. Search the web for the source that best fits your research question."

- [ ] **Step 4: Validate SKILL.md**

```bash
./scripts/validate-skill.sh skills/data-collection/SKILL.md 2000
```

- [ ] **Step 5: Word-count common-sources.md**

```bash
wc -w skills/data-collection/references/common-sources.md
```

Expected: under 2500 words.

- [ ] **Step 6: Commit**

```bash
git add skills/data-collection/
git commit -m "add data-collection skill with common sources reference"
```

---

## Task 11: `statistical-modeling` skill (SKILL.md only)

**Files:**
- Create: `skills/statistical-modeling/SKILL.md`

**Token budget:** Under 2000 words. Individual references built in Task 12.

- [ ] **Step 1: Create directories**

```bash
mkdir -p skills/statistical-modeling/references
```

- [ ] **Step 2: Write SKILL.md**

Frontmatter (exact):
```yaml
---
name: statistical-modeling
description: Use when estimating a statistical or econometric model, running a regression, specifying an identification strategy, testing a hypothesis, or fitting any model to empirical data. Guides the PROCESS (assumptions, estimation, reporting, diagnostics) without forcing a fixed method list.
---
```

**## Overview** — 3-4 sentences: this skill defines the process for statistical modeling in empirical research. It is method-agnostic — the LLM chooses the appropriate method for the research question, from cross-section to panel to time series to causal inference. Reference files offer starting points for common method families but are not exhaustive.

**## When to Use** — Triggers:
- Estimating any regression or model
- Designing an identification strategy
- Testing a hypothesis
- Fitting a time-series model
- "Run a DiD for me"
- "Fit a VAR"
- "Is this the right model for the data?"

**## Modeling Process** (the core of the skill)

Present the process as 6 phases, each with a short explanation:

1. **Define the estimand.** What parameter do you want to learn? Is it causal or descriptive? What population does it apply to? Without a clear estimand, model choice is premature.
2. **Verify assumptions match the data.** Every method has assumptions (e.g., exogeneity, stationarity, parallel trends, common support). Check the ones that apply. Document which assumptions are plausible and which are weak.
3. **Choose the method.** Pick the simplest method that meets the identification needs. More complex methods should be justified by the estimand or data structure, not by novelty.
4. **Estimate.** Run the model. Use standard errors appropriate to the design (clustered where needed). Report coefficients with SEs and the SE type.
5. **Diagnose.** Run post-estimation checks. Does the model fit? Are residuals well-behaved? Are there influential observations? Is the identification assumption supported by the data (where testable)?
6. **Report.** Table with coefficient, SE in parentheses, significance markers with documented convention, N, R² (where applicable), notes with SE type and sample.

**## Reference Files**

List the files with one-line descriptions:

- `references/modeling-process.md` — detailed walkthrough of the 6 phases above, applicable to any method
- `references/cross-section.md` — OLS, GLS, IV/2SLS, quantile, logit/probit, Poisson, survival, starting points
- `references/panel.md` — FE, RE, dynamic panel (GMM), mixed-effects / hierarchical
- `references/causal-inference.md` — DiD, CS-DiD, RD (sharp and fuzzy), synthetic control, matching, IPW
- `references/time-series.md` — ARIMA, VAR, VECM, GARCH, state-space, structural breaks, cointegration

Important note in the SKILL.md: **The reference files are starting points, not boundaries.** If a method not listed is appropriate for the research question (Bayesian models, machine learning, spatial econometrics, network models), use it — the modeling process applies regardless.

**## Integration with Other Skills**

- Invoke `replication-driven-research` before declaring any result final
- After a main specification produces a result, signal that `robustness-checks` should be invoked
- Use `tables-and-figures` to format output for the paper
- Use `academic-baseline` to enforce the causal-vs-correlational distinction in reporting

**## Anti-Patterns**:
- Estimating without stating the estimand
- Skipping assumption checks
- Using causal language ("effect", "impact") without an identification strategy
- Reporting without specifying the SE type (robust, clustered, HC1, bootstrap)
- Picking the method by the significance of the result
- Choosing a complex method when a simpler one identifies the estimand
- Treating p-values as probability the null is true

**## Verification Before Completion** — Checklist:
- [ ] Estimand defined explicitly
- [ ] Assumptions checked and documented
- [ ] Method justified by the estimand and data
- [ ] SE type specified
- [ ] Post-estimation diagnostics run
- [ ] Results generated by script (see `replication-driven-research`)
- [ ] Signal sent to invoke `robustness-checks` if main result

- [ ] **Step 3: Validate**

```bash
./scripts/validate-skill.sh skills/statistical-modeling/SKILL.md 2000
```

- [ ] **Step 4: Commit**

```bash
git add skills/statistical-modeling/SKILL.md
git commit -m "add statistical-modeling skill"
```

---

## Task 12: `statistical-modeling` reference files

**Files:**
- Create: `skills/statistical-modeling/references/modeling-process.md`
- Create: `skills/statistical-modeling/references/cross-section.md`
- Create: `skills/statistical-modeling/references/panel.md`
- Create: `skills/statistical-modeling/references/causal-inference.md`
- Create: `skills/statistical-modeling/references/time-series.md`

**Token budget:** Each reference file under 2500 words.

- [ ] **Step 1: Write `modeling-process.md`**

No frontmatter (this is a reference, not a skill). Structure:

```markdown
# The Empirical Modeling Process

Generic 6-phase process for any statistical model in empirical research. Applies regardless of discipline or method family.

## 1. Define the Estimand
[2-3 paragraphs: what a good estimand looks like, examples across fields]

## 2. Verify Assumptions
[2-3 paragraphs: how to approach assumption checking, which checks are universal vs method-specific, what to do when assumptions fail]

## 3. Choose the Method
[2-3 paragraphs: simplicity principle, matching method to identification needs, when to use more complex methods]

## 4. Estimate
[2-3 paragraphs: standard errors, numerical issues, convergence]

## 5. Diagnose
[2-3 paragraphs: residuals, influential observations, testable implications of the identification assumption]

## 6. Report
[2-3 paragraphs: what a publication-quality results table looks like, what notes to include]

## Common Pitfalls
[Short bulleted list of traps that apply to any method]
```

Constraints: under 2500 words, English only, no method-specific detail (that goes in the other reference files), no placeholder text.

- [ ] **Step 2: Write `cross-section.md`**

Structure:

```markdown
# Cross-Section Methods

Starting-point reference for single-period data. Not exhaustive.

## OLS with Appropriate Standard Errors
[Assumptions: linearity, exogeneity, homoskedasticity (or correction). When robust SEs vs classical. Clustered SEs and when. R packages: `fixest`, `sandwich`, `lmtest`. Python: `statsmodels`, `linearmodels`.]

## Instrumental Variables (2SLS)
[Assumptions: relevance, exclusion. Weak-IV diagnostics (first-stage F, Stock-Yogo critical values). Overid tests (Sargan/Hansen). R: `fixest::feols`, `AER::ivreg`. Python: `linearmodels`.]

## Quantile Regression
[When to use: heterogeneous effects across distribution. Assumptions. R: `quantreg`. Python: `statsmodels.QuantReg`.]

## Binary and Count Outcomes
[Logit, probit, Poisson, negative binomial. When to prefer each. Interpretation (odds ratios vs marginal effects). R: `glm`, `margins`. Python: `statsmodels`.]

## Survival Analysis
[Cox proportional hazards, Kaplan-Meier. When appropriate. R: `survival`. Python: `lifelines`.]

## Not in This Reference
[Brief note: Bayesian, nonparametric, spatial, machine-learning — use the modeling process and pick the method that fits the estimand.]
```

- [ ] **Step 3: Write `panel.md`**

Structure:

```markdown
# Panel Methods

Starting-point reference for repeated observations on the same units. Not exhaustive.

## Fixed Effects
[Assumption: strict exogeneity conditional on FE. Within transformation vs LSDV. Two-way FE. Hausman test vs RE. R: `fixest::feols`. Python: `linearmodels.PanelOLS`.]

## Random Effects
[When appropriate: exchangeable draws. Assumption: effects uncorrelated with regressors. Hausman. R: `plm`. Python: `linearmodels.RandomEffects`.]

## Dynamic Panel (GMM)
[Arellano-Bond, Blundell-Bover. When lagged outcome appears on RHS. Instrument proliferation problem. R: `plm::pgmm`. Python: `linearmodels.DynamicPanelModel`.]

## Mixed-Effects / Hierarchical Models
[When cross-classified or nested structure. Random slopes. R: `lme4`, `glmmTMB`. Python: `statsmodels.MixedLM`.]

## Clustered Standard Errors
[Rule of thumb: cluster at the level of treatment assignment or policy variation. Multi-way clustering.]

## Not in This Reference
[Note: panel cointegration, panel quantile — use the modeling process.]
```

- [ ] **Step 4: Write `causal-inference.md`**

Structure:

```markdown
# Causal Inference Methods

Starting-point reference for methods aimed at identifying causal effects. Not exhaustive.

## Difference-in-Differences (Canonical 2x2)
[Assumption: parallel trends. Diagnostics: event-study plot, pre-trend test, triple-diff as placebo. R: `fixest`, `did`. Python: `differences`, `linearmodels`.]

## Staggered DiD (Callaway-Sant'Anna, de Chaisemartin-D'Haultfoeuille, Borusyak-Jaravel-Spiess)
[Problem with two-way FE under heterogeneous effects and staggered timing. When to use each modern estimator. R: `did`, `DIDmultiplegt`, `didimputation`. Python: `differences`.]

## Regression Discontinuity
[Sharp and fuzzy. Assumptions: continuity of potential outcomes, no manipulation. Diagnostics: McCrary density test, covariate balance, bandwidth sensitivity, polynomial order choice. R: `rdrobust`, `rddensity`. Python: `rdrobust`.]

## Synthetic Control
[Assumption: donor pool, pre-treatment fit. Placebo tests in space. MSPE ratios. R: `Synth`, `tidysynth`, `augsynth`. Python: `pysyncon`.]

## Matching and IPW
[Propensity score, CEM, entropy balancing. Common support. R: `MatchIt`, `WeightIt`. Python: `causalml`.]

## IV for Causal Effects
[See cross-section reference for IV mechanics; here focus on exclusion restriction plausibility and LATE interpretation.]

## Sensitivity Analysis
[Rosenbaum bounds (matching), Oster bounds (OLS), sensitivity to confounding.]

## Not in This Reference
[Note: Bayesian causal inference, double ML, synthetic DiD — use the modeling process.]
```

- [ ] **Step 5: Write `time-series.md`**

Structure:

```markdown
# Time-Series Methods

Starting-point reference for temporally-ordered data. Not exhaustive.

## Stationarity and Unit Roots
[ADF, PP, KPSS tests. Differencing. When to prefer each test. R: `urca`, `tseries`. Python: `statsmodels.tsa.stattools`.]

## ARIMA / SARIMA
[Box-Jenkins methodology. Model selection (AIC, BIC). Diagnostic checks (Ljung-Box). R: `forecast`, `fable`. Python: `statsmodels.tsa`.]

## VAR and VECM
[Lag selection. Impulse response functions. Forecast error variance decomposition. Cointegration (Johansen). R: `vars`, `tsDyn`. Python: `statsmodels.tsa.vector_ar`.]

## GARCH Family
[When to use (volatility clustering). GARCH, EGARCH, GJR-GARCH. R: `rugarch`, `rmgarch`. Python: `arch`.]

## State-Space Models
[Local-level, local-linear trend, BSTS. Kalman filter. Missing-data handling. R: `dlm`, `KFAS`, `bsts`. Python: `statsmodels.tsa.statespace`.]

## Structural Breaks
[Chow, Bai-Perron, QLR. Endogenous break detection. R: `strucchange`. Python: `ruptures`.]

## High-Frequency / Realized Volatility
[Brief pointer: realized variance, microstructure noise, pre-averaging. R: `highfrequency`.]

## Not in This Reference
[Note: wavelet methods, machine-learning forecasting (Prophet, NBEATS), long-memory models — use the modeling process.]
```

- [ ] **Step 6: Word-count each reference**

```bash
for f in skills/statistical-modeling/references/*.md; do
  wc -w "$f"
done
```

Expected: each file under 2500 words.

- [ ] **Step 7: Commit**

```bash
git add skills/statistical-modeling/references/
git commit -m "add statistical-modeling reference files"
```

---

## Task 13: `tables-and-figures` skill

**Files:**
- Create: `skills/tables-and-figures/SKILL.md`

**Token budget:** Under 1800 words.

- [ ] **Step 1: Create directory**

```bash
mkdir -p skills/tables-and-figures
```

- [ ] **Step 2: Write SKILL.md**

Frontmatter (exact):
```yaml
---
name: tables-and-figures
description: Use when generating a LaTeX results table, creating a figure for a paper, formatting descriptive statistics, preparing regression output for publication, or producing vector-quality graphics. Enforces booktabs, threeparttable, vector PDFs, and script-generated output.
---
```

**## Overview** — 2-3 sentences: produces publication-quality tables and figures that are regenerated by scripts, not hand-edited. Uses `booktabs` for tables and vector PDFs for figures.

**## When to Use** — Triggers:
- "Make a table of descriptive statistics"
- "Format regression results for the paper"
- "Create a figure showing X over time"
- "Generate the event-study plot"
- Preparing final outputs for submission

**## Table Standards**

Required packages in paper preamble:
```latex
\usepackage{booktabs}
\usepackage{threeparttable}
\usepackage{siunitx}  % optional, for numerical alignment
```

Structure of a results table:
```latex
\begin{table}[htbp]
\centering
\begin{threeparttable}
\caption{Main Results}
\label{tab:main}
\begin{tabular}{lcc}
\toprule
 & (1) & (2) \\
 & OLS & FE \\
\midrule
Treatment & 0.123*** & 0.098** \\
          & (0.034)  & (0.041) \\
\midrule
N         & 10,234   & 10,234   \\
R²        & 0.42     & 0.58     \\
\bottomrule
\end{tabular}
\begin{tablenotes}[flushleft]
\footnotesize
\item \textit{Notes:} Standard errors clustered at state level in parentheses. * p<0.10, ** p<0.05, *** p<0.01. Sample: 2010-2020.
\end{tablenotes}
\end{threeparttable}
\end{table}
```

**## Significance Convention**

Default: `* p<0.10, ** p<0.05, *** p<0.01` (economics/finance convention).

Alternative: `* p<0.05, ** p<0.01, *** p<0.001` (common in psychology, medicine).

Detect from `CLAUDE.superpapers.md` (field setting) or ask the user. Always document the convention in the table note.

**## Figure Standards**

- Format: vector PDF only. Never PNG/JPG in the final paper.
- Generator: ggplot2 in R (preferred for publication) or pgfplots/tikz for native LaTeX integration.
- Theme: `theme_minimal()` or `theme_classic()`, with adjustments for print (B&W-safe palettes when possible).
- No titles on the plot itself — title goes in the LaTeX caption.
- Axis labels readable, units specified.
- Color palettes colorblind-safe (e.g., `viridis`, `scales::brewer_pal("Dark2")`).
- Save with `ggsave("output/figures/fig_name.pdf", width = W, height = H, device = cairo_pdf)`.

**## File Naming**

Convention:
- Tables: `tab_<purpose>.tex` (e.g., `tab_descriptives.tex`, `tab_main_results.tex`, `tab_robustness.tex`)
- Figures: `fig_<purpose>.pdf` (e.g., `fig_event_study.pdf`, `fig_trends.pdf`)

**## Mandatory Steps**:

1. Generate tables/figures from a script that reads `data/processed/` and writes to `output/tables/` or `output/figures/`. Never hand-edit.
2. Use `booktabs` rules (`\toprule`, `\midrule`, `\bottomrule`) — never `\hline`.
3. Wrap every table in `threeparttable` with a notes block documenting: SE type, significance convention, sample, data source.
4. Save figures as vector PDF.
5. Include in the paper with `\input{output/tables/tab_X.tex}` or `\includegraphics{output/figures/fig_X.pdf}`.
6. Table notes and figure captions in the user's paper language; internal file paths and script comments in English.

**## Anti-Patterns**:
- Tables with `\hline` instead of booktabs rules
- Tables without a notes block
- Figures saved as PNG or JPG in the final paper
- Hand-edited `.tex` table file
- Significance convention undocumented
- Figure with embedded title (clashing with LaTeX caption)
- Missing sample description in the table note

**## Verification Before Completion** — Checklist:
- [ ] Generated by a script in `code/`
- [ ] Output in `output/tables/` or `output/figures/`
- [ ] Tables use `booktabs` + `threeparttable`
- [ ] Significance convention documented in the note
- [ ] Figures are vector PDFs
- [ ] No titles on figures themselves
- [ ] Axis labels and units specified

- [ ] **Step 3: Validate**

```bash
./scripts/validate-skill.sh skills/tables-and-figures/SKILL.md 1800
```

- [ ] **Step 4: Commit**

```bash
git add skills/tables-and-figures/SKILL.md
git commit -m "add tables-and-figures skill"
```

---

## Task 14: `robustness-checks` skill

**Files:**
- Create: `skills/robustness-checks/SKILL.md`

**Token budget:** Under 1600 words.

- [ ] **Step 1: Create directory**

```bash
mkdir -p skills/robustness-checks
```

- [ ] **Step 2: Write SKILL.md**

Frontmatter (exact):
```yaml
---
name: robustness-checks
description: Use when a main specification has produced a result, when preparing a paper appendix, when a reviewer requests robustness, or before declaring any empirical finding final. Guides selection of design-appropriate checks without mandating a fixed checklist.
---
```

**## Overview** — 2-3 sentences: applies canonical robustness checks relevant to the chosen design. Open-ended: the skill suggests the checks that fit, not a blanket checklist. YAGNI applies.

**## When to Use** — Triggers:
- After `statistical-modeling` has produced a main result
- Reviewer requested robustness tests
- Preparing the paper's appendix
- User asks "is this result robust?"
- Before submission

**## The YAGNI Principle**

Include only checks that are (a) canonical for the design, (b) plausibly challenging to the result, or (c) requested by a reviewer. Do not pile on 30 tests to signal rigor — this is noise, not evidence. A paper with 5 well-chosen robustness checks is stronger than one with 30 redundant ones.

**## Canonical Checks by Design**

Present as a table or structured list. The starting-point recipes:

- **Sample splits:** by period, by subgroup, excluding outliers, excluding influential observations
- **Alternative specifications:** controls added/removed, alternative functional forms, alternative outcome definitions
- **Placebo tests:** fake treatment, fake period, fake outcome, cross-unit placebos
- **Leave-one-out:** exclude each unit/period/cluster once, report distribution
- **Sensitivity to outliers:** winsorization, trimming, Cook's distance
- **Alternative standard errors:** robust, clustered at alternative levels, bootstrap, wild bootstrap, permutation
- **Alternative estimators:** Poisson vs OLS for counts, IV vs OLS, quantile vs mean regression
- **Sensitivity to unobserved confounding:** Rosenbaum bounds (matching), Oster bounds (OLS)

**## Process**:

1. Identify the identification strategy of the main result.
2. List the canonical challenges to that strategy. Example: for DiD, parallel trends is the key assumption, so checks should probe it (pre-trends, placebo periods, event study).
3. Pick 4-8 checks that address those challenges. More is rarely better.
4. Run each check as a separate script under `code/`.
5. Report all checks in a dedicated section or appendix table, including checks where the result does NOT survive.
6. Never hide a check that failed. Discuss it transparently.

**## Reporting Format**

Show example structure:
```markdown
## Robustness

Table A1 reports alternative specifications. Column (1) reproduces the main result. Column (2) excludes the 2020 shock. Column (3) uses an alternative outcome measure. Column (4) clusters at the municipality level instead of state. The coefficient remains statistically significant and economically meaningful across all variations, except for Column (2), where the point estimate falls by 40% and is no longer significant at conventional levels. This sensitivity to the 2020 period is discussed in Section 6.
```

**## Anti-Patterns**:
- Running 30 checks without a criterion for selection
- Reporting only the checks where the result survived
- A robustness check that tests a different estimand than the main result
- Running the wrong test for the design (e.g., McCrary for a DiD)
- Not discussing checks that fail
- Adding a check because "someone did this in another paper", not because it challenges this result

**## Verification Before Completion** — Checklist:
- [ ] Each check is justified by the identification strategy of the main result
- [ ] 4-8 checks (not 30)
- [ ] Every check run by a script in `code/`
- [ ] Results tabulated, including failures
- [ ] Narrative in the paper discusses both survivors and failures
- [ ] YAGNI: no check included "just to be safe"

- [ ] **Step 3: Validate**

```bash
./scripts/validate-skill.sh skills/robustness-checks/SKILL.md 1600
```

- [ ] **Step 4: Commit**

```bash
git add skills/robustness-checks/SKILL.md
git commit -m "add robustness-checks skill"
```

---

## Task 15: `journal-selection` skill

**Files:**
- Create: `skills/journal-selection/SKILL.md`

**Token budget:** Under 1400 words.

- [ ] **Step 1: Create directory**

```bash
mkdir -p skills/journal-selection
```

- [ ] **Step 2: Write SKILL.md**

Frontmatter (exact):
```yaml
---
name: journal-selection
description: Use when choosing a target journal for a paper, comparing journal rankings, asking "where should I submit this", or building a submission strategy across multiple journals. Field-agnostic — detects the paper's research area and suggests appropriate outlets across tiers.
---
```

**## Overview** — 2-3 sentences: field-agnostic journal selection based on current web information (no static database). Presents a ranked list across ambition tiers.

**## When to Use** — Triggers:
- "Where should I submit this paper?"
- "What journals would take a paper on X?"
- "Rank these three journals for me"
- Planning a submission strategy
- Checking a journal's current scope

**## Mandatory Steps**:

1. **Identify the paper's field and contribution level** from the abstract, topic, and the user's stated ambition.
2. **Search journals via web search** — do not use a static list. Journal scopes, rankings, and editorial boards change.
3. **Verify each candidate via web fetch** on the journal homepage: confirm it is still active, currently accepting submissions, and matches the paper's topic.
4. **Check rankings appropriate to the user's context:**
   - JCR and Scimago (SJR) for most fields
   - RePEc for economics
   - Qualis/Capes for Brazilian authors
   - Field-specific rankings (e.g., ABS for business, Australian Research Council for social sciences)
5. **Present 5-8 options in a markdown table** with columns: `Journal`, `Area`, `Ranking`, `Avg. Review Time` (when known), `Submission Fee`, `Fit`, `Tier` (ambitious/realistic/safety).
6. **Mix tiers:** 1-2 ambitious, 3-4 realistic, 1-2 safety.
7. **Include regional/national journals when relevant.** If the user is Brazilian or the paper targets a Brazilian audience, include strong national journals.

**## Output Example**

Show:
```markdown
| Journal | Area | Ranking | Review Time | Fee | Fit | Tier |
|---|---|---|---|---|---|---|
| American Economic Review | General econ | JCR Q1 | ~6 months | 0 | Top-5; requires general interest | Ambitious |
| Journal of Development Economics | Development | JCR Q1 | ~9 months | 0 | Strong fit for development topic | Realistic |
| World Development | Development, policy | JCR Q1 | ~6 months | 0 | Interdisciplinary, policy-oriented | Realistic |
| Revista Brasileira de Economia | Econ (Brazil) | Qualis A2 | ~3 months | 0 | National relevance | Safety |
```

**## Anti-Patterns**:
- Maintaining a static journal database in this skill (will go stale)
- Suggesting only top-5 journals without fit analysis
- Ignoring regional journals when the paper has regional relevance
- Not verifying the journal is still active
- Suggesting predatory journals
- Copying rankings from memory (rankings change)

**## Verification Before Completion** — Checklist:
- [ ] Each candidate verified via web fetch
- [ ] Rankings current (checked on the web, not from memory)
- [ ] Mix of tiers presented
- [ ] Fit column populated with substantive reasoning, not just "interesting"
- [ ] No predatory journals

- [ ] **Step 3: Validate**

```bash
./scripts/validate-skill.sh skills/journal-selection/SKILL.md 1400
```

- [ ] **Step 4: Commit**

```bash
git add skills/journal-selection/SKILL.md
git commit -m "add journal-selection skill"
```

---

## Task 16: `journal-guidelines` skill

**Files:**
- Create: `skills/journal-guidelines/SKILL.md`

**Token budget:** Under 1500 words.

- [ ] **Step 1: Create directory**

```bash
mkdir -p skills/journal-guidelines
```

- [ ] **Step 2: Write SKILL.md**

Frontmatter (exact):
```yaml
---
name: journal-guidelines
description: Use when preparing a paper for submission to a specific journal, checking formatting requirements, parsing instructions for authors, building a submission checklist, or adapting a paper to a journal template. Fetches the journal's official guidelines via web and produces a verifiable checklist.
---
```

**## Overview** — 2-3 sentences: fetches instructions for authors from the journal's official page, parses them into a structured checklist, and adapts the paper to the journal's template when provided.

**## When to Use** — Triggers:
- "Format the paper for journal X"
- "What does journal Y require for submission?"
- "Build a submission checklist"
- "Adapt the paper to this template"
- Final formatting pass before submission

**## Mandatory Steps**:

1. **Fetch the journal's instructions for authors** via web fetch on the official URL. Never rely on memory or cached knowledge.
2. **Parse key requirements into a structured list:**
   - Word/page limit (manuscript, abstract, each)
   - Citation style (APA, Chicago, Harvard, numeric, bespoke)
   - Section structure (some journals require IMRAD, some structured abstracts)
   - Figures and tables (placement, format, size, color vs B&W)
   - Supplementary material rules
   - Replication package requirements
   - Blinding (single, double, triple blind)
   - Cover letter expectations
   - Submission portal and format (.tex, .docx, .pdf)
3. **Produce a checklist in markdown** with each requirement as a verifiable item.
4. **If the journal provides a LaTeX template:** download it via web, adapt the paper to the template's structure, map existing `\input{}` table calls to the template's expectations.
5. **If no template:** adjust the existing paper — margins, font, spacing, citation style — to meet the requirements.
6. **Verify compliance item-by-item before declaring the paper ready.** Run through the checklist and mark each item.

**## Checklist Format Example**

Show:
```markdown
## Submission Checklist — Journal of Applied Econometrics

- [ ] Manuscript under 8,000 words (current: 7,421)
- [ ] Abstract under 150 words (current: 148)
- [ ] Harvard citation style (currently: using biblatex authoryear — OK)
- [ ] Double-blind: remove author names from title page, footnote acknowledgments
- [ ] Figures as vector PDF, embedded in text
- [ ] Data and code deposit with replication package (Dataverse acceptable)
- [ ] Cover letter: significance statement + suggested referees
- [ ] Submit via Editorial Manager: https://...
```

**## Anti-Patterns**:
- Using guidelines from memory instead of fetching the current version
- Skipping the replication package requirement
- Ignoring blinding when required
- Formatting "close enough" instead of exactly matching requirements
- Missing the cover letter when required
- Submitting in `.docx` when the journal wants `.tex`

**## Verification Before Completion** — Checklist:
- [ ] Guidelines fetched from official URL in the last session (not cached)
- [ ] Every requirement in the guidelines parsed into the checklist
- [ ] Each checklist item verified against the current paper
- [ ] Template applied if provided
- [ ] Supplementary / replication materials prepared
- [ ] Cover letter drafted if required

- [ ] **Step 3: Validate**

```bash
./scripts/validate-skill.sh skills/journal-guidelines/SKILL.md 1500
```

- [ ] **Step 4: Commit**

```bash
git add skills/journal-guidelines/SKILL.md
git commit -m "add journal-guidelines skill"
```

---

## Task 17: `brainstorm` skill (research orchestration)

**Files:**
- Create: `skills/brainstorm/SKILL.md`

**Token budget:** Under 2500 words.

- [ ] **Step 1: Create directory**

```bash
mkdir -p skills/brainstorm
```

- [ ] **Step 2: Write SKILL.md**

Frontmatter (exact):
```yaml
---
name: brainstorm
description: Use when starting a new research project, exploring a research idea, deciding whether a question is viable, or before touching code or data for a new paper. Runs a research-focused brainstorm that clarifies research question, identification strategy, data feasibility, and contribution before any implementation.
---
```

**## Overview** — 3-4 sentences: this is the first step in the superpapers pipeline for any new research project. It mirrors the Superpowers brainstorming philosophy (Socratic questions, proposed approaches, incremental design approval) but asks research-specific questions. The terminal state is invoking `write-plan`.

**## When to Use** — Triggers:
- "I have an idea for a paper"
- "I want to study X"
- "Can you help me think through this research question?"
- Start of any new research project
- Before any data collection or analysis

**## When NOT to Use**:
- Mid-project troubleshooting (use `statistical-modeling` or a specific domain skill)
- When the research question and design are already clear and stable
- Formatting or submission tasks

**## Process Flow**

1. **Explore project context.** Check for `CLAUDE.superpapers.md`, existing `data/`, `paper/`, `.bib` files, git history. Detect language (user's conversation) and paper language (from project config or ask).
2. **Detect research field** from context or ask. This shapes which databases and methods are relevant.
3. **Ask Socratic questions, one at a time.** Do NOT batch questions. Use multiple choice where possible. Topics to cover (in roughly this order):
   - What is the research question? Can it be rejected by data?
   - Is the project exploratory or confirmatory? (This shapes all later decisions.)
   - What would a causal answer require — and is that answerable with available data?
   - What identification strategy is candidate? (DiD, RD, IV, SC, time-series, none because descriptive.)
   - What data would you need? Does it exist? Is it accessible? At what cost?
   - What is the contribution over existing literature? Invoke `literature-search` if needed to verify the gap.
   - Order-of-magnitude statistical power: is the sample large enough to detect plausible effect sizes?
   - What is the target publication tier — and is the design consistent with that tier's expectations?
4. **Propose 2-3 empirical approaches with trade-offs.** Always recommend one and explain why. Present options conversationally.
5. **Present the research design section-by-section, getting approval after each section.** Sections: research question, data strategy, identification strategy, estimation plan, expected outputs (tables/figures), robustness plan, submission target.
6. **Scale each section to its complexity.** A simple descriptive study may need one paragraph per section. A novel identification strategy may need several paragraphs.
7. **Write the spec** to `docs/superpapers/specs/YYYY-MM-DD-<topic>-design.md` in English.
8. **Self-review the spec** for placeholders, contradictions, scope problems, ambiguity. Fix inline.
9. **Ask the user to review the written spec.** Wait for approval before proceeding.
10. **Transition to `write-plan`.** This is the only terminal state.

**## Hard Gate**

Do NOT invoke `write-plan`, `execute-plan`, any data-collection, any analysis, any literature search beyond validation of the research gap, until the design spec is written and the user has approved it.

**## Guardrails**

- Invoke `academic-baseline` principles throughout — especially the causal-vs-correlational distinction.
- Invoke `replication-driven-research` as a constraint on the design — the plan must be reproducible end-to-end.
- Never commit to a result framing in advance. The brainstorm ends with a design, not conclusions.
- Questions asked in the user's conversation language. Spec document written in English (plugin artifact). User's paper content later, per Language Policy.

**## Anti-Patterns**:
- Batching multiple questions in one message
- Jumping to implementation before a design is approved
- Skipping the exploratory-vs-confirmatory distinction
- Proposing only one approach instead of 2-3
- Writing the spec without user approval
- Letting the user drift into "it's too simple to need a design"
- Assuming a causal answer is feasible without asking about identification

**## Verification Before Completion** — Checklist:
- [ ] Research field detected and confirmed
- [ ] Paper language established (even if default English)
- [ ] Research question is falsifiable and explicit
- [ ] Exploratory vs confirmatory distinction made
- [ ] Identification strategy identified (or "none, this is descriptive" made explicit)
- [ ] Data feasibility confirmed
- [ ] Contribution over literature established
- [ ] 2-3 approaches presented with recommendation
- [ ] Design presented section-by-section with approval
- [ ] Spec written to `docs/superpapers/specs/`
- [ ] User approved the spec
- [ ] Next step (`write-plan`) announced

- [ ] **Step 3: Validate**

```bash
./scripts/validate-skill.sh skills/brainstorm/SKILL.md 2500
```

- [ ] **Step 4: Commit**

```bash
git add skills/brainstorm/SKILL.md
git commit -m "add brainstorm orchestration skill"
```

---

## Task 18: `write-plan` skill (research orchestration)

**Files:**
- Create: `skills/write-plan/SKILL.md`

**Token budget:** Under 2000 words.

- [ ] **Step 1: Create directory**

```bash
mkdir -p skills/write-plan
```

- [ ] **Step 2: Write SKILL.md**

Frontmatter (exact):
```yaml
---
name: write-plan
description: Use when a research design spec exists and the user is ready to translate it into a concrete implementation plan with phased tasks, artifacts, and verification criteria. Produces a research execution plan organized in canonical research phases (collection, preparation, analysis, robustness, writing, submission).
---
```

**## Overview** — 3-4 sentences: writes a detailed, research-structured implementation plan from an approved design spec. The plan is organized in research phases — not software phases — and every task has an expected artifact and a verification criterion. Invokes `replication-driven-research` as a constraint.

**## When to Use** — Triggers:
- An approved design spec exists in `docs/superpapers/specs/`
- User says "now write the plan" or "let's plan this out"
- Transitioning from `brainstorm` to implementation
- Planning a revision round after reviewer feedback

**## Prerequisites**:
- A spec in `docs/superpapers/specs/YYYY-MM-DD-<topic>-design.md`, written and approved via `brainstorm`
- User has confirmed they want to proceed

**## Canonical Research Phases**

The plan is organized in these phases (not software phases). Each phase has tasks; each task has an expected artifact and a verification step.

1. **Collection** — Fetch raw data. Tasks: identify sources (via `data-collection`), implement collection scripts, save to `data/raw/`, update `data/manifest.md`. Verification: raw files exist, manifest entries present.
2. **Preparation** — Clean and merge. Tasks: cleaning scripts, merge logic, derived variables, sample selection rules. Verification: processed data exists in `data/processed/`, sample selection documented.
3. **Exploratory Analysis** — Descriptive statistics, visualizations, data quality checks. Tasks: `tab_descriptives.tex`, `fig_trends.pdf`, anomaly detection. Verification: outputs exist; reviewer can read them before the main analysis.
4. **Main Analysis** — The specified model from the design. Tasks: one estimation script per specification (main, alternate outcome, alternate controls). Verification: `tab_main_results.tex` exists, coefficients reproducible.
5. **Robustness** — Canonical checks for the design (via `robustness-checks`). Tasks: one script per check, one table or column per check. Verification: `tab_robustness.tex` exists; all checks present; failures discussed.
6. **Writing** — Paper sections from data to narrative. Tasks: draft each section (Abstract, Intro, Data, Methods, Results, Discussion, Conclusion), pull tables/figures via `\input{}` and `\includegraphics{}`. Verification: `paper.tex` compiles with `compile-latex`.
7. **Submission** — Target journal, formatting, checklist. Tasks: invoke `journal-selection`, invoke `journal-guidelines` for the chosen journal, final compliance check. Verification: submission checklist complete.

**## Task Template**

Every task must specify:
- **Title** — imperative, actionable
- **Phase** — one of the 7 above
- **Inputs** — files/data this task reads
- **Outputs** — files this task produces
- **Script** — path to the script that implements it, e.g., `code/02_clean.R`
- **Verification** — command to run to verify the task completed (e.g., "file exists and is non-empty", "script exits 0", "pipeline still runs end-to-end")
- **Skills involved** — which superpapers skills are invoked (e.g., `statistical-modeling`, `tables-and-figures`)
- **Commit** — git commit message after the task succeeds

**## Mandatory Steps**:

1. **Read the design spec.** Understand every decision the brainstorm made.
2. **Decompose into tasks following the canonical phases.** Aim for bite-sized tasks (10-30 minutes each). If a task is a full day of work, split it.
3. **For every task, specify all task-template fields.** No placeholders.
4. **Map dependencies.** Later phases depend on earlier phases. Within a phase, tasks may be parallel or sequential.
5. **Apply `replication-driven-research` as a constraint.** Every task must produce a versionable artifact. Every script must fix seed. Every output must feed into an end-to-end pipeline.
6. **Write the plan** to `docs/superpapers/plans/YYYY-MM-DD-<topic>-plan.md` in English.
7. **Self-review** for coverage (every spec requirement has a task?), placeholders, type/name consistency across tasks, scope fit (can this be one plan or does it need splitting?).
8. **Offer execution.** Present `execute-plan` as the next step.

**## Anti-Patterns**:
- Plan organized by software phases (architecture, backend, frontend) instead of research phases
- Tasks with vague outputs ("build the analysis")
- Tasks without verification criteria
- Skipping the manifest update in the collection phase
- Hardcoding numeric results in the writing phase
- Planning robustness checks before knowing the main result's design
- A task that mixes multiple phases

**## Verification Before Completion** — Checklist:
- [ ] Every spec requirement mapped to a task
- [ ] All 7 phases represented (or explicitly excluded with reason)
- [ ] Every task has inputs, outputs, script path, verification, skills, commit message
- [ ] No placeholders in the plan
- [ ] Dependencies between tasks explicit
- [ ] Plan saved to `docs/superpapers/plans/` in English
- [ ] Self-review completed
- [ ] Next step (`execute-plan`) offered to user

- [ ] **Step 3: Validate**

```bash
./scripts/validate-skill.sh skills/write-plan/SKILL.md 2000
```

- [ ] **Step 4: Commit**

```bash
git add skills/write-plan/SKILL.md
git commit -m "add write-plan orchestration skill"
```

---

## Task 19: `execute-plan` skill (research orchestration)

**Files:**
- Create: `skills/execute-plan/SKILL.md`

**Token budget:** Under 2000 words.

- [ ] **Step 1: Create directory**

```bash
mkdir -p skills/execute-plan
```

- [ ] **Step 2: Write SKILL.md**

Frontmatter (exact):
```yaml
---
name: execute-plan
description: Use when a research implementation plan exists in docs/superpapers/plans/ and the user is ready to execute it — collecting data, running analysis, producing outputs, writing the paper. Orchestrates task execution with replication-driven verification and two-stage review at phase boundaries.
---
```

**## Overview** — 3-4 sentences: executes a research plan phase by phase. Uses subagents for independent tasks. Invokes `replication-driven-research` as a guardrail. Two-stage review at phase boundaries: correctness and reproducibility. Stops and asks at any scaffolding or destructive action.

**## When to Use** — Triggers:
- A plan exists in `docs/superpapers/plans/`
- User says "execute the plan" or "run the plan"
- Transitioning from `write-plan` to implementation
- Resuming execution of a partially-completed plan

**## Prerequisites**:
- An approved plan in `docs/superpapers/plans/YYYY-MM-DD-<topic>-plan.md`
- User has confirmed they want to proceed
- `replication-driven-research` has been invoked at least once in this project (to scaffold directories)

**## Execution Flow**

1. **Load the plan.** Parse tasks, phases, dependencies.
2. **Scaffold the project structure** if not already done. Invoke `replication-driven-research` — propose canonical directories, get user confirmation.
3. **Execute tasks phase by phase.** Within a phase, dispatch independent tasks to subagents in parallel. Sequential tasks run in order.
4. **After every task: verify.** Run the task's verification command. If it fails, stop and report.
5. **After every phase: run end-to-end integration.** Execute the full pipeline from `data/raw/` to the farthest artifact produced so far. Verify exit 0 and all expected outputs.
6. **Two-stage phase review:**
   - **Stage 1 — correctness:** are the results right? Does the analysis make sense? Review narratively.
   - **Stage 2 — reproducibility:** is the pipeline end-to-end clean? Is the seed fixed? Is the manifest updated? Run `replication-driven-research` verification checklist.
7. **Only proceed to the next phase after both stages pass.**
8. **On failure:** stop, diagnose root cause, fix, re-run from the failing task (not from scratch).
9. **At the end:** final full-pipeline run, all verifications pass, commit, report to user.

**## Subagent Dispatch**

Use subagents for:
- Independent collection tasks (different data sources)
- Independent robustness checks (different specifications)
- Independent exploratory analyses (different subgroups)

Do not use subagents for:
- Sequential tasks where one depends on another
- Writing paper sections (context-dependent, needs main session)
- Decisions that require user input

**## Guardrails**

- **Scaffolding is not automatic.** Always ask the user before creating directories or files outside the plan.
- **Destructive actions need confirmation.** Never delete data, reset git state, or overwrite existing artifacts without explicit approval.
- **Invalidation on input change is mandatory.** If raw data or a script changes mid-execution, all downstream outputs are stale. Re-run the affected phases.
- **No result is final until the pipeline runs end-to-end.** "It worked on my session" is not evidence.

**## Mandatory Steps**:

1. Load and parse the plan.
2. Invoke `replication-driven-research` to ensure project structure.
3. Execute tasks phase by phase, dispatching independent tasks to subagents.
4. Verify after each task and each phase.
5. Run two-stage review at phase boundaries.
6. Stop on any verification failure; diagnose and fix at the root cause.
7. Final end-to-end pipeline run before declaring the plan complete.
8. Update `data/manifest.md` and `output/logs/` throughout.
9. Commit at task boundaries with informative messages.
10. Report status to user at phase boundaries.

**## Anti-Patterns**:
- Skipping verification between tasks
- Declaring a phase complete without the end-to-end integration run
- Running tasks out of dependency order
- Silent failures — masking errors to keep moving
- Editing downstream outputs when an upstream input changed, without re-running the pipeline
- Parallelizing tasks that share state
- Forgetting to update the manifest or logs
- Skipping user confirmation for scaffolding or destructive actions

**## Verification Before Completion** — Checklist:
- [ ] Every task in the plan executed (or explicitly skipped with reason)
- [ ] Verification command of every task passed
- [ ] Every phase ended with an end-to-end pipeline run
- [ ] Two-stage review (correctness + reproducibility) completed per phase
- [ ] Final full-pipeline run exits 0
- [ ] `data/manifest.md` up to date
- [ ] `output/logs/` has the latest execution log
- [ ] All expected outputs exist
- [ ] Plan file updated with completion status
- [ ] Final commit pushed (if remote configured)

- [ ] **Step 3: Validate**

```bash
./scripts/validate-skill.sh skills/execute-plan/SKILL.md 2000
```

- [ ] **Step 4: Commit**

```bash
git add skills/execute-plan/SKILL.md
git commit -m "add execute-plan orchestration skill"
```

---

## Task 20: `CLAUDE.superpapers.md` template

**Files:**
- Create: `templates/CLAUDE.superpapers.md`

- [ ] **Step 1: Create directory**

```bash
mkdir -p templates
```

- [ ] **Step 2: Write template**

Create `templates/CLAUDE.superpapers.md` with exactly this content:

```markdown
# <Project Name>

## Research Context

- **Field:** <e.g., applied economics, political science, epidemiology>
- **Research question:** <falsifiable statement of the question>
- **Type:** <exploratory | confirmatory>
- **Identification strategy:** <DiD | RD | IV | SC | time-series | descriptive>
- **Paper language:** <en | pt-BR | es | fr | ...>  <!-- default: en -->
- **Significance convention:** <econ (0.10/0.05/0.01) | psi-med (0.05/0.01/0.001)>

## Target Outlets

- **Primary target journal:** <name>
- **Backup journals:** <name1, name2>
- **Tier strategy:** <ambitious | realistic | safety>

## Reproducibility

- **Default seed:** <integer, e.g., 20260410>
- **R version / Python version:** <e.g., R 4.4.1 / Python 3.12>
- **Package lockfile:** <renv.lock | requirements.txt | uv.lock>

## Directory Structure

This project follows the superpapers canonical structure:

- `data/raw/` — raw downloads, never edited manually
- `data/processed/` — cleaned data, script outputs
- `code/` — collection, cleaning, analysis scripts
- `output/tables/` — `.tex` tables generated by scripts
- `output/figures/` — `.pdf` vector figures generated by scripts
- `output/logs/` — execution logs
- `paper/` — `.tex` paper and `.bib` bibliography

## Instructions for Claude Code

- Use the `superpapers` plugin skills for all research tasks in this project.
- Enforce `replication-driven-research` as a guardrail for every analysis step.
- Respect the paper language setting above for all user-facing paper content (sections, tables notes, figure captions).
- Plugin internals, scripts, and code comments remain in English regardless of paper language.
- Never fabricate citations — verify every reference via web.
- Never hardcode results in `paper/paper.tex` — always use `\input{}` from `output/`.
```

- [ ] **Step 3: Verify no placeholder markers beyond the documented angle-bracket fields**

Run:
```bash
grep -iE '\b(TBD|TODO|FIXME|XXX)\b' templates/CLAUDE.superpapers.md && echo "FAIL" || echo "OK"
```

Expected: `OK`.

- [ ] **Step 4: Commit**

```bash
git add templates/CLAUDE.superpapers.md
git commit -m "add CLAUDE.superpapers.md template"
```

---

## Task 21: `paper-skeleton.tex` template

**Files:**
- Create: `templates/paper-skeleton.tex`

- [ ] **Step 1: Write template**

Create `templates/paper-skeleton.tex` with exactly this content:

```latex
% Superpapers paper skeleton — minimal LaTeX template for empirical research
% Compile with: ./skills/compile-latex/scripts/compile.sh paper/paper.tex
%
% Language: default English. For other languages, uncomment the babel line
% and adjust. All preamble comments remain in English.

\documentclass[12pt,a4paper]{article}

% --- Encoding and language ---
\usepackage[utf8]{inputenc}
\usepackage[T1]{fontenc}
% \usepackage[english]{babel}      % default
% \usepackage[brazilian]{babel}    % for pt-BR
% \usepackage[spanish]{babel}      % for es
% \usepackage[french]{babel}       % for fr

% --- Typography ---
\usepackage{lmodern}
\usepackage{microtype}
% \usepackage{fontspec}            % uncomment to use xelatex with custom fonts

% --- Math ---
\usepackage{amsmath}
\usepackage{amssymb}
\usepackage{amsthm}

% --- Tables and figures ---
\usepackage{booktabs}
\usepackage{threeparttable}
\usepackage{graphicx}
\usepackage{float}

% --- Bibliography (choose one) ---
\usepackage[authoryear,round]{natbib}  % natbib style
% \usepackage[style=authoryear,backend=biber]{biblatex}  % biblatex alternative
% \addbibresource{references.bib}                        % for biblatex

% --- Links ---
\usepackage[colorlinks=true,allcolors=blue]{hyperref}

% --- Layout ---
\usepackage[margin=1in]{geometry}
\usepackage{setspace}
\onehalfspacing

% --- Metadata ---
\title{<Title of the Paper>}
\author{<Author Name>\thanks{<Affiliation and contact>}}
\date{\today}

\begin{document}

\maketitle

\begin{abstract}
\noindent <Abstract: 150-250 words. State the research question, data, method,
main finding, and contribution.>

\noindent\textbf{Keywords:} <keyword1, keyword2, keyword3>

\noindent\textbf{JEL codes:} <JEL1, JEL2>  % remove if not an economics paper
\end{abstract}

\section{Introduction}
\label{sec:intro}

<Motivation. Research question. Contribution. Preview of findings. Roadmap.>

\section{Literature Review}
\label{sec:lit}

<Position in the literature. Identify the gap this paper fills.>

\section{Data}
\label{sec:data}

<Sources, sample selection, summary statistics. Reference the descriptives
table generated by script.>

\input{../output/tables/tab_descriptives.tex}

\section{Empirical Strategy}
\label{sec:methods}

<Identification strategy. Estimation model. Discussion of assumptions.>

\section{Results}
\label{sec:results}

<Main findings. Reference the main results table generated by script.>

\input{../output/tables/tab_main_results.tex}

\begin{figure}[H]
\centering
\includegraphics[width=0.8\textwidth]{../output/figures/fig_main.pdf}
\caption{<Figure caption>}
\label{fig:main}
\end{figure}

\section{Robustness}
\label{sec:robustness}

<Canonical robustness checks appropriate to the design. Invoke
\texttt{robustness-checks} skill to structure this section.>

\input{../output/tables/tab_robustness.tex}

\section{Conclusion}
\label{sec:conclusion}

<Summary of findings. Limitations. Policy or theoretical implications.
Directions for future research.>

% --- Bibliography ---
\bibliographystyle{apalike}
\bibliography{references}
% \printbibliography  % for biblatex

% --- Appendix ---
\appendix
\section{Additional Results}
\label{app:additional}

<Supplementary tables and figures that support the main text.>

\end{document}
```

- [ ] **Step 2: Basic syntax check**

Ensure braces are balanced:
```bash
python3 -c "
content = open('templates/paper-skeleton.tex').read()
assert content.count('{') == content.count('}'), 'unbalanced braces'
assert content.count(r'\begin{document}') == 1
assert content.count(r'\end{document}') == 1
print('OK')
"
```

Expected: `OK`.

- [ ] **Step 3: Commit**

```bash
git add templates/paper-skeleton.tex
git commit -m "add paper-skeleton.tex template"
```

---

## Task 22: `replication-readme.md` template

**Files:**
- Create: `templates/replication-readme.md`

- [ ] **Step 1: Write template**

Create `templates/replication-readme.md` with exactly this content:

```markdown
# Replication Package — <Paper Title>

This package reproduces all results, tables, and figures in the paper
_<Paper Title>_ by <Authors>, published in <Journal> (<Year>).

## Citation

<Full BibTeX entry or APA citation>

DOI: <paper DOI>

## Requirements

- **R version:** <e.g., 4.4.1>  *or*  **Python version:** <e.g., 3.12>
- **Package manager:** `renv` (R) or `uv`/`pip-tools` (Python)
- **LaTeX distribution:** TeX Live 2024 or later
- **OS:** Tested on <Linux / macOS / Windows>
- **Disk space:** <e.g., 2 GB including raw data>
- **Runtime (end-to-end):** <e.g., ~15 minutes on a standard laptop>

## Installation

R:
```bash
R -e "renv::restore()"
```

Python:
```bash
uv sync  # or: pip install -r requirements.txt
```

## Directory Structure

- `data/raw/` — raw downloads. Included when licensing allows; otherwise fetched by `code/01_collect.*`.
- `data/processed/` — cleaned data, generated by scripts.
- `code/` — all analysis scripts, numbered in execution order.
- `output/tables/` — `.tex` tables.
- `output/figures/` — `.pdf` figures.
- `output/logs/` — execution logs.
- `paper/` — `.tex` paper source and bibliography.

## Reproducing the Results

Run the end-to-end pipeline:
```bash
./run_all.sh
```

This executes scripts in order:

1. `code/01_collect.*` — fetches raw data into `data/raw/`
2. `code/02_clean.*` — cleans and merges into `data/processed/`
3. `code/03_analyze.*` — estimates models and writes tables to `output/tables/`
4. `code/04_figures.*` — generates figures to `output/figures/`
5. `code/05_robustness.*` — robustness checks

Then compile the paper:
```bash
./skills/compile-latex/scripts/compile.sh paper/paper.tex
```

## Random Seed

All stochastic scripts fix the seed to `<INTEGER>` (set at the top of each script). Results are bit-identical across runs on the same platform.

## Data Sources

See `data/manifest.md` for a complete list of data sources with URLs, collection dates, and licenses.

## Known Issues / Caveats

<List anything a replicator should know: proprietary data requiring separate access, platform-specific quirks, known numerical differences across OS, etc.>

## Contact

<Corresponding author name, email, institutional affiliation>

## License

Code: <MIT / BSD / GPL / ...>
Data: respect each source's original license (see `data/manifest.md`)
```

- [ ] **Step 2: Verify no placeholder markers beyond documented angle-bracket fields**

Run:
```bash
grep -iE '\b(TBD|TODO|FIXME|XXX)\b' templates/replication-readme.md && echo "FAIL" || echo "OK"
```

Expected: `OK`.

- [ ] **Step 3: Commit**

```bash
git add templates/replication-readme.md
git commit -m "add replication-readme.md template"
```

---

## Task 23: Final integration — validate all skills

- [ ] **Step 1: Validate every SKILL.md**

Run:
```bash
for f in skills/*/SKILL.md; do
  ./scripts/validate-skill.sh "$f" || exit 1
done
echo "ALL SKILLS OK"
```

Expected: every skill passes, final line `ALL SKILLS OK`.

- [ ] **Step 2: Confirm file structure matches the plan**

Run:
```bash
find . -type f \( -name '*.md' -o -name '*.json' -o -name '*.sh' -o -name '*.tex' \) \
  | grep -v '^./\.git' \
  | sort
```

Expected: the list should match the file structure at the top of this plan (27 files including `docs/superpapers/specs/...` and `docs/superpapers/plans/...` from brainstorming/planning phase).

- [ ] **Step 3: Run JSON validators**

```bash
python3 -c "import json; json.load(open('.claude-plugin/plugin.json'))" && echo "plugin.json OK"
python3 -c "import json; json.load(open('.claude-plugin/marketplace.json'))" && echo "marketplace.json OK"
```

Expected: both `OK`.

- [ ] **Step 4: Confirm git history is clean**

Run:
```bash
git status
git log --oneline
```

Expected: clean working tree, one commit per task with informative messages.

- [ ] **Step 5: Final commit if anything remains**

If `git status` shows untracked or modified files:
```bash
git add -A
git commit -m "final integration pass"
```

---

## Task 24: Local install smoke test

- [ ] **Step 1: Verify plugin can be discovered by Claude Code**

From any Claude Code session:
```
/plugin marketplace add /home/rae/OneDrive/devel/superpapers
```

Expected: marketplace added without error.

- [ ] **Step 2: Attempt to activate the plugin**

```
/plugin install superpapers
```

Expected: plugin installs.

- [ ] **Step 3: Smoke test one skill**

In a fresh session, send: "I want to brainstorm a new research paper on the effect of minimum wage on employment."

Expected: the `brainstorm` skill activates and begins the Socratic flow.

- [ ] **Step 4: Report results**

Document any issues encountered during local install in the user-facing output. If everything works, report success.

---

## Completion

Plan complete when all 24 tasks are checked off, all 27 files exist, all validations pass, and the plugin installs and activates successfully in a smoke test.

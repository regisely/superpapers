# Superpapers — Design Spec

**Date:** 2026-04-09 (last updated 2026-04-10)
**Status:** Approved
**Author:** Regis A. Ely + Claude

## Overview

Superpapers is a standalone Claude Code plugin for empirical quantitative research. It replicates the Superpowers philosophy (brainstorm → write-plan → execute-plan with subagent-driven development) adapted for the full research lifecycle: ideation to submission.

Target users: researchers in any field that works with datasets and statistical models — economics, finance, political science, sociology, epidemiology, public health, environmental science, quantitative psychology, etc. Applied economics is the primary inspiration but not the boundary.

Core substitution: TDD → replication-driven-research.

## Language Policy

**Plugin is English-only.** All SKILL.md files, scripts, templates, documentation, examples, comments, and identifiers are in English. This is a hard rule — the plugin must be understandable to researchers globally.

**User output adapts.** When the user writes a paper in Portuguese, Spanish, French, or any other language, the plugin produces paper content (abstract, sections, table notes, figure captions) in the user's chosen language. Language detection happens at project setup (via `CLAUDE.superpapers.md`) or via explicit user instruction.

**Separation principle:**
- Plugin internals (SKILL.md, scripts, templates) → always English
- User-facing content (paper drafts, generated tables, figure labels) → user's language
- Code comments in user's project → user's preference (default English)

## Key Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Superpowers dependency | Standalone | Avoid coupling — Superpowers changes could break plugin |
| Research field scope | Empirical quantitative research (any field) | Broader market; methods and discipline are universal |
| Plugin language | English-only internals, multilingual user output | Global accessibility; user's paper in user's language |
| Script language | Agnostic (R or Python per project) | Skills guide process, don't impose runtime |
| Data source skills | 1 consolidated `data-collection` | Sources depend on research question, not a fixed list |
| Citation management | Direct .bib + CrossRef API | No external tool dependency (no Zotero CLI) |
| Orchestration depth | Deep research adaptation | Brainstorm/write-plan/execute-plan redesigned for research, not just relabeled |
| Project structure | Hybrid scaffolding | Propose canonical structure, adapt to existing projects |
| Statistical methods | Open-ended with reference examples | LLM chooses method for the problem; references are starting points, not boundaries |

## Plugin Structure

```
superpapers/
├── .claude-plugin/
│   ├── plugin.json
│   └── marketplace.json
├── skills/
│   ├── brainstorm/SKILL.md
│   ├── write-plan/SKILL.md
│   ├── execute-plan/SKILL.md
│   ├── academic-baseline/SKILL.md
│   ├── replication-driven-research/SKILL.md
│   ├── compile-latex/
│   │   ├── SKILL.md
│   │   └── scripts/compile.sh
│   ├── literature-search/SKILL.md
│   ├── citation-management/SKILL.md
│   ├── data-collection/
│   │   ├── SKILL.md
│   │   └── references/common-sources.md
│   ├── statistical-modeling/
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── cross-section.md
│   │       ├── panel.md
│   │       ├── causal-inference.md
│   │       ├── time-series.md
│   │       └── modeling-process.md
│   ├── tables-and-figures/SKILL.md
│   ├── robustness-checks/SKILL.md
│   ├── journal-selection/SKILL.md
│   └── journal-guidelines/SKILL.md
├── templates/
│   ├── CLAUDE.superpapers.md
│   ├── paper-skeleton.tex
│   └── replication-readme.md
└── README.md
```

**Total: 14 skills** (3 orchestration + 11 domain).

## Skills — Orchestration

### `brainstorm`

**Trigger:** Research idea, beginning of research project, "I want to write a paper on X".

**Flow:**
1. Explore project context (repo, data, .bib, .tex, `CLAUDE.superpapers.md` if present)
2. Detect (or ask): research field, paper language (default English)
3. Socratic questions one at a time:
   - Research question (falsifiable?)
   - Exploratory or confirmatory?
   - Candidate identification strategy?
   - Data needed? Available? Accessible?
   - Contribution relative to existing literature?
   - Statistical power viability? (order-of-magnitude check)
4. Propose 2-3 empirical approaches with trade-offs
5. Present research design section by section, get approval
6. Write spec to `docs/superpapers/specs/YYYY-MM-DD-<topic>-design.md` (in English — plugin artifact)
7. Invoke `write-plan`

**Guardrails:** References `academic-baseline` and `replication-driven-research`. Distinguishes causal vs correlational from the start. Questions asked in the user's conversation language, but spec documents written in English.

### `write-plan`

**Trigger:** After approved brainstorm, or when user has spec and wants execution plan.

**Generates plan in research phases:**
1. **Collection** — data sources, formats, storage
2. **Preparation** — cleaning, merging, derived variables, sample selection
3. **Exploratory analysis** — descriptive statistics, preliminary visualizations
4. **Main analysis** — model(s) specified in brainstorm
5. **Robustness** — canonical checks + design-specific
6. **Writing** — paper sections, tables, figures
7. **Submission** — journal selection, formatting, checklist

Each step with: expected output artifact, verification criterion, dependencies.

Invokes `replication-driven-research` as constraint: plan must ensure end-to-end reproducibility.

### `execute-plan`

**Trigger:** After approved write-plan.

**Flow:**
1. Propose directory scaffolding (if new project) via `replication-driven-research`
2. Execute tasks via subagents (parallel when independent)
3. After each step: verify pipeline runs end-to-end
4. Two-stage review: (a) result correct? (b) reproducible?
5. Data/spec change → invalidate downstream results, mandatory re-run

## Skills — Foundation

### `academic-baseline`

**Trigger:** Any academic research context, paper writing, empirical analysis.

**Non-negotiable principles (~800 tokens):**
- Never fabricate citations — every reference needs verified DOI/URL
- Mandatory replication — no number in paper without regenerating script
- LaTeX output by default — tables in .tex (booktabs), figures in vector PDF
- Causal vs correlational — causal language only with explicit identification strategy
- YAGNI in robustness — canonical checks for chosen design, not 30 tests to impress referee
- Exploratory ≠ confirmatory — if discovered by exploring data, don't pretend it was a prior hypothesis
- Numerical integrity — fixed seed, documented package versions, no hardcoded intermediate results
- Respect the user's paper language — paper content (sections, tables, captions, citations formatting) in user's language; plugin internals and code in English

### `replication-driven-research`

**Trigger:** Start of empirical analysis, data pipeline creation, result generation, data/spec changes.

**Heart of the plugin.** Replaces TDD for research domain. Same principle: evidence before claims, automated verification, invalidation on input change.

**Mandatory steps:**

1. **Directory structure** — On first invocation, propose to user:
   ```
   data/raw/          # raw data, never manually edited
   data/processed/    # clean data, generated by script
   code/              # collection, cleaning, analysis scripts
   output/tables/     # .tex generated by script
   output/figures/    # .pdf generated by script
   output/logs/       # execution logs with timestamps
   paper/             # paper .tex, .bib
   ```
   User can refuse or adapt. Skills work with any structure but flag deviations.

2. **Reproducible pipeline** — Every result requires:
   - Script from raw data to final output
   - Fixed seed documented in script
   - No manual steps between raw → output
   - Versionable artifacts: parquet for data, .tex for tables, .pdf for figures

3. **End-to-end run** — Before any result is declared verified, entire pipeline must run without errors.

4. **Invalidation** — Any change to raw data, variables, or model spec invalidates all downstream results. Mandatory re-run.

5. **Execution log** — Each run records: timestamp, seed, relevant package versions, execution time, input hashes.

6. **Manifest** — `data/manifest.md` documenting each dataset: source, description, collection date, URL/API used, variables used.

**Anti-patterns:**
- Manually copying numbers from output to .tex
- "Worked yesterday" without re-run after change
- Result without traceable script
- Undocumented manual step in pipeline
- Different seed between runs without justification

**Verification:**
- Pipeline runs from raw data to final output without error
- Every table/figure has a generating script
- Manifest documents all datasets
- Execution log exists with timestamp and seed
- No hardcoded numbers in .tex

### `compile-latex`

**Trigger:** Compile .tex, LaTeX error, paper build, PDF generation.

**Mandatory steps:**
1. Detect engine from preamble (`\usepackage{fontspec}` → xelatex, else pdflatex)
2. Detect bibliography system (biber vs bibtex)
3. Compile with multi-pass: engine → bib → engine → engine
4. Parse error log, extract useful messages, suggest fixes
5. If latexmk available, prefer `latexmk -pdf` or `latexmk -xelatex`

**Script:** `scripts/compile.sh` — wrapper that detects engine, runs necessary passes, returns clean exit code and parsed errors.

## Skills — Research Pipeline

### `literature-search`

**Trigger:** Paper search, literature review, "what does the literature say about X", finding references.

**Mandatory steps:**
1. Identify the research field from project context to pick appropriate sources
2. Search via web search in academic databases — core list + field-specific:
   - **Core (any field):** Google Scholar, Web of Science, JSTOR, Semantic Scholar
   - **Economics/Finance:** SSRN, NBER, RePEc, ScienceDirect
   - **Health/Medicine:** PubMed, Cochrane Library
   - **Political Science/Sociology:** JSTOR, SAGE Journals
   - **Other fields:** arXiv, discipline-specific repositories as needed
3. For each paper found: mandatory web fetch to confirm real existence — title, authors, year, DOI
4. Output in markdown table: authors, year, title, journal, verified DOI, relevance
5. Never cite from memory. If cannot verify via web, explicitly declare "unverified"
6. Prioritize seminal + recent papers (last 5 years)

**Anti-patterns:** Fabricating papers (primary), citing from memory, listing 30 papers without relevance curation, confusing working paper with publication.

### `citation-management`

**Trigger:** Add citation to .bib, import by DOI, clean bibliography, check duplicates.

**Mandatory steps:**
1. Resolve DOI via CrossRef API for complete metadata
2. Generate BibTeX entry with standard fields: author, title, journal, year, volume, pages, doi
3. Key format: `AuthorYear` (e.g., `Santos2024`), disambiguate with letters if needed
4. Check duplicates by DOI and by similar title before adding
5. Keep .bib sorted alphabetically by key

### `data-collection`

**Trigger:** Data collection, download series, build dataset, access economic data API.

**Mandatory steps:**
1. Identify data needs from research question
2. Search appropriate sources — start from `references/common-sources.md`, expand via web search as needed
3. Collect via API when available, respectful scraping when not (rate limiting, robots.txt, backoff, identifiable user-agent)
4. Save raw data in versionable format (parquet preferred, csv acceptable)
5. Document each series in manifest: series code, description, source, URL/API endpoint, collection date, frequency, period
6. Local cache: don't re-download already collected data unless explicitly requested

**`references/common-sources.md`** — Starting point (not closed list), organized by domain:
- **Economics/Finance — Brazil:** SGS/BCB, SIDRA/IBGE, Ipeadata, CVM, B3, Tesouro Nacional
- **Economics/Finance — International:** FRED, World Bank Open Data, IMF, OECD, Penn World Table, Comtrade, BIS
- **Financial/Accounting:** WRDS, Compustat, CRSP, Bloomberg (when accessible)
- **Social Sciences / General:** ICPSR, Harvard Dataverse, UK Data Service, Eurostat, UN Data
- **Health/Epidemiology:** WHO, CDC, PubMed datasets, NHANES, DataSUS (Brazil)
- **Political Science:** V-Dem, Polity, Correlates of War, Manifesto Project
- **Environmental:** NOAA, NASA Earth Data, Copernicus, Our World in Data
- **Academic repositories (any field):** Harvard Dataverse, Zenodo, Open Science Framework

## Skills — Analysis and Output

### `statistical-modeling`

**Trigger:** Estimate model, run regression, statistical analysis, identification strategy, hypothesis testing, fit model to data.

**Mandatory steps:**
1. Before estimating: verify model assumptions (method-specific checklist)
2. Estimate with main specification defined in brainstorm
3. Report in standard publication format: coefficient, standard error (in parentheses), significance markers with documented convention
4. Invoke `replication-driven-research` — result only valid if script reproduces end-to-end
5. After main result: signal that `robustness-checks` should be invoked

**Open-ended method selection.** The skill guides the PROCESS (assumptions → estimation → reporting → diagnostics → robustness), not a fixed method list. The LLM chooses the appropriate method for the research question regardless of discipline.

**`references/`** — Starting points organized by method family, not exhaustive:
- `cross-section.md` — OLS, IV/2SLS, GLS, quantile regression, logit/probit, Poisson, survival, etc.
- `panel.md` — FE, RE, dynamic panel (GMM), mixed-effects / hierarchical models, etc.
- `causal-inference.md` — DiD, CS-DiD, RD, SC, matching, IPW, instrumental variables
- `time-series.md` — ARIMA, VAR, VECM, GARCH, state-space, structural breaks, cointegration
- `modeling-process.md` — Generic guide: identification → assumptions → estimation → diagnostics → reporting

The reference files cover methods commonly used across empirical disciplines (economics, political science, epidemiology, quantitative sociology, etc.). Bayesian and machine-learning methods can be added to references as needed but are not required in the initial build.

### `tables-and-figures`

**Trigger:** Generate results table, create figure, format output for paper, descriptive statistics table.

**Mandatory steps:**
1. Tables in LaTeX with: `booktabs`, `threeparttable`, notes with SE type and significance convention explicitly documented
2. Significance markers follow field convention — detect from project context or ask user:
   - Economics/finance default: `*, **, *** = 0.10, 0.05, 0.01`
   - Psychology/medicine default: `*, **, *** = 0.05, 0.01, 0.001`
   - Whatever the convention, document it in the table note (`* p<0.10, ** p<0.05, *** p<0.01`)
3. Figures in vector PDF: via ggplot2 (`theme_minimal` + B&W adjustments) or tikz/pgfplots
4. Each table/figure generated by script — never manually edited in .tex
5. Include in paper via `\input{}` (tables) or `\includegraphics{}` (figures)
6. Naming convention: `tab_descriptives.tex`, `tab_main_results.tex`, `fig_event_study.pdf`

**Formatting standards:**
- Variables with readable labels (not code names)
- Appropriate precision (2-3 decimals for coefficients, 0 for N)
- Notes at table base: SE type, significance convention, data source, sample period
- Figures: clear axis labels, no title (title goes in LaTeX caption), source when applicable
- Table notes and figure captions in the user's chosen paper language (see Language Policy)

### `robustness-checks`

**Trigger:** After main result estimated, verify robustness, reviewer asked for robustness, prepare appendix.

**Mandatory steps:**
1. Activate after `statistical-modeling` produces main result
2. Apply relevant canonical checks (open-ended, not exhaustive checklist)
3. Each check: run, compare with main result, report if result survives
4. Organize in table/appendix with clear reference to main result

**Starting-point recipe** (apply relevant ones, not all):
- Sample splits, alternative specifications, placebo tests, leave-one-out, sensitivity to outliers, alternative SE, alternative estimators

**Anti-patterns:** 30 checks without criteria (YAGNI), reporting only checks that "worked", not declaring when result does NOT survive a check.

## Skills — Submission

### `journal-selection`

**Trigger:** Choose journal, where to submit, journal ranking, "which journal for this paper".

**Field-agnostic.** Detects the paper's research field from abstract/topic and searches journals appropriate to that field.

**Mandatory steps:**
1. From abstract and topic, identify research field (economics, political science, epidemiology, etc.) and contribution level
2. Search journals via web search — no static database
3. For each suggestion, verify via web fetch: current scope, ISSN, impact factor / updated ranking
4. Present 5-8 options in table: name, area, ranking (field-appropriate: JCR/SJR universal; Qualis/Capes for Brazilian authors; RePEc for econ; field-specific rankings when relevant), average review time, submission fee, fit
5. Include tier mix: 1-2 ambitious, 3-4 realistic, 1-2 safety
6. When the user is Brazilian or the paper targets a Brazilian audience, include relevant national journals in the mix

### `journal-guidelines`

**Trigger:** Format paper for journal X, instructions for authors, submission checklist, journal template.

**Mandatory steps:**
1. Fetch instructions for authors from journal's official URL via web fetch
2. Parse requirements: word/page limit, citation format, section structure, supplementary material, formatting rules
3. Produce submission checklist in markdown with each requirement as verifiable item
4. If journal provides LaTeX template: download and adapt paper
5. If no template: adjust existing paper to requirements
6. Verify compliance item by item before declaring ready

## Templates

### `CLAUDE.superpapers.md`
Template for project CLAUDE.md. ~30 lines. Fields: project name, research field, research question, empirical design, directory structure, default seed, target journals, **paper language** (default English; user sets to pt-BR, es, fr, etc. when writing in another language). All template text in English; user fills in their own content in their language.

### `paper-skeleton.tex`
Minimal LaTeX template for empirical quantitative research papers (field-agnostic). Packages: booktabs, threeparttable, natbib/biblatex, hyperref, graphicx, amsmath. Sections: Abstract, Introduction, Literature Review, Data, Methodology, Results, Robustness, Conclusion, References, Appendix. Section names and placeholder text in English — user adapts to paper language as needed. Supports `babel` for non-English papers (commented example in preamble).

### `replication-readme.md`
Template for replication package README, in English. Fields: project description, requirements (R/Python + versioned packages), directory structure, execution instructions, data sources, seed and version used. Follows open science conventions (AER, Econometrica, AJPS, PNAS replication package standards).

## SKILL.md Design Principles

Every SKILL.md follows:
- **Frontmatter:** `name` + `description` starting with "Use when..." — triggers only, no workflow summary
- **Sections:** Overview → When to Use → Mandatory Steps → Anti-patterns → Verification Before Completion
- **Token budget:** Under 5k tokens; progressive disclosure via `references/` for details
- **CSO:** Keywords for discovery (error messages, symptoms, tool names)
- **Cross-references:** By skill name, never force-load via @

## Build Order

### Phase 1: Foundation
1. Plugin scaffolding (plugin.json, marketplace.json, README)
2. `academic-baseline`
3. `replication-driven-research`
4. `compile-latex` + `scripts/compile.sh`

### Phase 2: Research Pipeline
5. `literature-search`
6. `citation-management`
7. `data-collection` + `references/common-sources.md`

### Phase 3: Analysis and Output
8. `statistical-modeling` + `references/` (5 files)
9. `tables-and-figures`
10. `robustness-checks`

### Phase 4: Submission
11. `journal-selection`
12. `journal-guidelines`

### Phase 5: Orchestration
13. `brainstorm`
14. `write-plan`
15. `execute-plan`

### Phase 6: Templates
16. `CLAUDE.superpapers.md`
17. `paper-skeleton.tex`
18. `replication-readme.md`

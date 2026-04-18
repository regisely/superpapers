---
description: Run a holistic pre-submission audit on a completed paper
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion
---

Use the `academic-baseline` skill first, then the `paper-review` skill from the superpapers plugin for the current project.

Command intent:

- Run a terminal, cross-cutting audit of a drafted paper covering text, code, tables, figures, results, citations, and reproducibility. Produce a persistent audit report with severity-ranked findings and a go/no-go verdict.

Execution rules:

1. Inspect the project for:
   - `paper.tex` (or the main TeX file), `references.bib`
   - `output/tables/`, `output/figures/`, `output/logs/`
   - the code directory and `run_all.sh`
   - `docs/superpapers/plans/` and `docs/superpapers/specs/` when present (context only — not required)
   (`CLAUDE.superpapers.md` is loaded automatically by `academic-baseline` on activation when it exists — no manual check needed here.)

2. The skill works both on papers produced by this plugin and on externally authored papers. If the canonical layout is missing, it asks the user for the paths it needs via AskUserQuestion. Do not refuse to run because `CLAUDE.superpapers.md` or `docs/superpapers/plans/` is absent.

3. Run the `paper-review` skill as the authoritative workflow:
   - invoke `academic-baseline` first and keep it active through the audit
   - execute all 11 mandatory steps in order (discovery → inventory → numerical → narrative → citations → code → tables/figures → AI-patterns → language → report → summary)
   - produce the report at `docs/superpapers/review/audit-YYYYMMDD-HHMM.md`
   - write the report in the paper's declared language (`paper_language` from `CLAUDE.superpapers.md` or detected heuristically)
   - surface findings with severity (Critical / Major / Minor) and location (`file:line`)
   - emit an explicit go/no-go verdict — "go" requires zero Critical findings
   - offer remediation one finding at a time via AskUserQuestion; never apply a batch fix

4. Delegate out when appropriate rather than duplicating work:
   - deep prose critique → `paper-writing`
   - additional robustness checks → `robustness-checks`
   - executable reproducibility verification → `replication-driven-research`
   - bibliography repair → `citation-management`
   - table/figure remediation patterns → `tables-and-figures`
   - LaTeX compilation and log inspection → `compile-latex`

5. Keep this command within superpapers. Do not route to generic review behavior from other plugins.

6. This command is the recommended final pre-submission step and can also be run standalone at any time.

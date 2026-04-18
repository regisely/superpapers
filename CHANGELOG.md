# Changelog

## [1.4.0] - 2026-04-18

Pre-submission audit skill and command.

- `paper-review` skill added: terminal, cross-cutting pre-submission audit covering numerical consistency (paper prose ↔ tables ↔ logs), narrative coherence (abstract ↔ introduction ↔ results ↔ conclusion), literature dialogue in Results and Discussion, citation integrity, code and reproducibility hygiene (hard-coded paths, seeds, data-loading errors, orphaned scripts), tables and figures quality (booktabs, vector figures, `Overfull \hbox` detection), AI-pattern surface scan including em-dash density, and language consistency
- New command `/superpapers:paper-review` — runs standalone on papers written inside or outside the plugin; produces a persistent audit report at `docs/superpapers/review/audit-YYYYMMDD-HHMM.md` with severity-ranked findings (Critical / Major / Minor) and a go/no-go verdict
- `execute-plan` ends with a non-blocking suggestion to run the new audit before submission; no auto-invocation and no gate on plan completion
- Audit report is written in the paper's declared `paper_language`; remediation is per-finding via AskUserQuestion — never batch-fixed

## [1.2.0] - 2026-04-14

Reliable `CLAUDE.superpapers.md` loading and multi-paper repository support.

- `CLAUDE.superpapers.md` is now reliably loaded by every skill via an explicit walk-up Read on activation (starting from the current working directory and walking up parent directories until found) instead of the previous soft "check for" language that relied on Claude's discretion
- Multi-paper repositories are now supported: place a `CLAUDE.superpapers.md` inside each paper subfolder; skills resolve the correct file based on the current working directory
- `/superpapers:init` repositioned as an opt-in command for advanced users who want to pre-populate settings, pin a reproducibility seed, or add explicit rules; no other command or skill calls or suggests it
- `/superpapers:init` now writes `CLAUDE.superpapers.md` in the current working directory (not the project root) to support multi-paper layouts, and echoes the written content in its summary so same-session skills see it without re-reading disk
- `templates/CLAUDE.superpapers.md` cleaned up: `## Directory Structure` block removed (owned by `replication-driven-research`); `Reproducibility` section removed (seed, version, lockfile were either redundant or better inferred automatically); `Code language` field added to Research Context; target-journal bias and recent-publications rules added to Instructions for Claude Code
- `brainstorm` now explicitly invokes `journal-selection`, `statistical-modeling`, and `data-collection` at the appropriate Socratic steps (publication tier, identification strategy, statistical power, data feasibility), and elevates `replication-driven-research` from a passing guardrail to a foundational step 1 invocation alongside `academic-baseline`
- `write-plan` now includes a canonical `Literature` phase at the start of the pipeline (phases renumbered from 7 to 8); every plan must contain a task that invokes `literature-search` in full mode (all Mandatory Steps, including target-journal bias) to produce a curated bibliography and notes document before data collection begins. `brainstorm` continues to do only the brief gap verification in Step 4 Contribution — the full literature review is an execution-pipeline task, not a brainstorm step
- README documents both single-paper and multi-paper layouts with directory trees

## [1.1.0] - 2026-04-13

Strengthened orchestration rules for skill loading and task routing.

- `academic-baseline` is now explicitly invoked first in `brainstorm`, `write-plan`, and `execute-plan`
- `write-plan` now treats `Skills involved` as mandatory routing metadata, with `academic-baseline` required on every task
- `journal-guidelines` is now required for journal-facing tasks, submission formatting, and compliance checks
- `execute-plan` now explicitly honors each task's declared `Skills involved` field during execution
- `CLAUDE.superpapers.md` template and README updated to document the stronger orchestration contract

## [1.0.0] - 2025-04-13

Initial stable release.

- 14 skills: `academic-baseline`, `replication-driven-research`, `compile-latex`, `brainstorm`, `write-plan`, `execute-plan`, `literature-search`, `citation-management`, `data-collection`, `statistical-modeling`, `tables-and-figures`, `robustness-checks`, `journal-selection`, `journal-guidelines`
- Explicit slash commands: `/superpapers:init`, `/superpapers:brainstorm`, `/superpapers:write-plan`, `/superpapers:execute-plan`
- Reference files for statistical methods (cross-section, panel, causal inference, time series)
- Templates: `CLAUDE.superpapers.md`, `paper-skeleton.tex`, `replication-readme.md`
- Skill validation script (`validate-skill.sh`)
- LaTeX compilation script with engine and bibliography auto-detection
- Writing quality principle in `academic-baseline` (clean prose, minimal subsections)
- Target journal citation bias in `literature-search`
- Variable scale verification and justification requirements in `statistical-modeling`
- Table overflow prevention and landscape fallback in `tables-and-figures`
- End-matter sections (Data Availability, Competing Interests, Acknowledgments with AI declaration) in `journal-guidelines`
- Interactive presentation deployed to GitHub Pages
- Worked example: `examples/credit_and_productivity.pdf`

[1.4.0]: https://github.com/regisely/superpapers/releases/tag/v1.4.0
[1.2.0]: https://github.com/regisely/superpapers/releases/tag/v1.2.0
[1.1.0]: https://github.com/regisely/superpapers/releases/tag/v1.1.0
[1.0.0]: https://github.com/regisely/superpapers/releases/tag/v1.0.0

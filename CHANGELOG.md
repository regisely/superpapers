# Changelog

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
- Worked example: `credit_and_productivity/`

[1.0.0]: https://github.com/regisely/superpapers/releases/tag/v1.0.0

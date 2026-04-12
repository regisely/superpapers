# Superpapers

A Claude Code plugin for empirical quantitative research — brainstorm, plan, and execute academic papers with the same discipline that Superpowers brings to software engineering.

## What It Is

Superpapers adapts the Superpowers pipeline (brainstorm → write-plan → execute-plan with subagent-driven development) for the full academic paper lifecycle. It covers everything from ideation to submission: literature search, data collection, statistical modeling, robustness checks, writing, and journal targeting. The pipeline is anchored by a `replication-driven-research` guardrail that replaces test-driven development in the research domain: every number, table, and figure in the paper must be regenerable from raw data by a script with a fixed seed.

The plugin is field-agnostic. Although it is inspired by applied economics and econometrics, the process and tooling work for any empirical quantitative field — political science, sociology, epidemiology, public health, environmental science, quantitative psychology, and more. Methods, data sources, and journal suggestions are not constrained to a fixed list; the plugin adapts to the research question.

Superpapers is a standalone plugin with no dependencies on Superpowers or any other Claude Code plugin. Plugin internals (skills, scripts, templates, comments) are English-only, but the plugin produces paper content (sections, tables, captions) in whatever language the user chooses for their paper.

## Installation

Add the plugin from GitHub in any Claude Code session:

```
/plugin marketplace add regisely/superpapers
/plugin install superpapers
```

Claude Code accepts a GitHub repo directly as the marketplace source. After installation, the skills become available automatically when you discuss research tasks.

## Demo Materials

The repository includes a full presentation and the paper generated from the real research session shown in that deck.

The demo is not a scripted toy example. It walks through a real Claude Code session in which:

- the project starts from a concrete empirical question;
- the first identification strategy looks plausible, then fails after estimation;
- the workflow pivots to a second strategy instead of forcing a weak result;
- null results, failed diagnostics, robustness checks, and reframing decisions stay explicit;
- the user remains in the loop for major research decisions.

Links:

- Live presentation: [regisely.github.io/superpapers/](https://regisely.github.io/superpapers/)
- Hosted paper PDF: [regisely.github.io/superpapers/credit_and_productivity_paper.pdf](https://regisely.github.io/superpapers/credit_and_productivity_paper.pdf)
- Repository copy of the paper: [`credit_and_productivity_paper.pdf`](credit_and_productivity_paper.pdf)

The presentation source lives in `presentation/`, with screenshot assets in `presentation/screenshots/`. GitHub Pages publishes that directory directly at the site root, so no separate `pages/` source folder is needed.

## Skills Overview

Fourteen skills organized by role:

| Skill | Role | Purpose |
|---|---|---|
| `brainstorm` | Orchestration | Socratic exploration of a research idea; produces a design spec |
| `write-plan` | Orchestration | Translates an approved spec into a phased research execution plan |
| `execute-plan` | Orchestration | Runs the plan phase by phase with subagents and two-stage review |
| `academic-baseline` | Foundation | Non-negotiable principles that govern all other skills |
| `replication-driven-research` | Foundation | End-to-end reproducibility guardrail (replaces TDD) |
| `compile-latex` | Foundation | Multi-pass LaTeX compilation with engine and bib detection |
| `literature-search` | Pipeline | Web-verified search across academic databases |
| `citation-management` | Pipeline | BibTeX management via CrossRef API (no Zotero needed) |
| `data-collection` | Pipeline | Data discovery, respectful collection, manifest documentation |
| `statistical-modeling` | Analysis | Open-ended modeling process with method-family references |
| `tables-and-figures` | Analysis | Publication-quality LaTeX tables and vector PDF figures |
| `robustness-checks` | Analysis | Design-appropriate canonical robustness checks |
| `journal-selection` | Submission | Field-agnostic journal matching with tier strategy |
| `journal-guidelines` | Submission | Parses instructions for authors, builds submission checklist |

## Typical Workflow

1. **Start a new project.** Copy `templates/CLAUDE.superpapers.md` into your project root, fill in the research context (field, question, paper language, target journals).
2. **Brainstorm.** Ask Claude Code something like "I want to study the effect of X on Y". The `brainstorm` skill activates and asks Socratic questions about your research question, identification strategy, data, and contribution. The output is a design spec saved inside the research project, typically under `docs/superpapers/specs/`.
3. **Plan.** Once the spec is approved, the `write-plan` skill generates a phased research plan (collection, preparation, analysis, robustness, writing, submission) with explicit artifacts and verification criteria per task, typically saved inside the research project under `docs/superpapers/plans/`.
4. **Execute.** The `execute-plan` skill dispatches subagents per task, verifies after each phase, and runs the full pipeline end-to-end before declaring any result final.
5. **Submit.** When the paper is ready, use `journal-selection` to pick a target outlet and `journal-guidelines` to format the paper to that journal's requirements.

Throughout the workflow, `academic-baseline` enforces the non-negotiable principles and `replication-driven-research` guarantees the pipeline stays reproducible.

## Example Prompts

English:

```
I want to write a paper on the effect of Bolsa Família on child nutrition outcomes.
```

```
Help me find recent papers on minimum wage effects in Latin America, verified via DOI.
```

```
Run a staggered DiD on this panel of state-level policy adoptions from 2010 to 2024.
```

Skills activate automatically based on the conversation context — you do not need to invoke them by name.

## Project Setup

For new research projects, copy `templates/CLAUDE.superpapers.md` into the project root and fill in the fields (field, research question, paper language, default seed, target journals). This file tells Claude Code which skills apply to the project and what settings to respect.

The canonical project structure — proposed by `replication-driven-research` on first invocation — is:

```
project-root/
├── data/
│   ├── raw/
│   ├── processed/
│   └── manifest.md
├── code/
├── output/
│   ├── tables/
│   ├── figures/
│   └── logs/
├── paper/
│   ├── paper.tex
│   └── references.bib
└── CLAUDE.superpapers.md
```

You can use `templates/paper-skeleton.tex` as a starting point for the paper itself and `templates/replication-readme.md` for the replication package.

## Language Policy

Plugin internals — SKILL.md files, scripts, templates, code comments, identifiers — are English-only. This keeps the plugin accessible to researchers globally.

Paper content — abstract, sections, table notes, figure captions, output strings — follows the user's chosen paper language. Set `paper_language` in `CLAUDE.superpapers.md` (default: `en`, options include `pt-BR`, `es`, `fr`, and so on). Skills that produce user-facing paper content respect this setting.

Your conversation with Claude Code can happen in any language. Only the plugin internals are fixed to English.

## License and Author

MIT License.

Author: Regis A. Ely (<regisaely@gmail.com>).

Issues and contributions: see the project homepage.

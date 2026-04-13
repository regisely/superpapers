---
name: write-plan
description: Use when a research design spec exists and the user is ready to translate it into a concrete implementation plan with phased tasks, artifacts, and verification criteria. Produces a research execution plan organized in canonical research phases — collection, preparation, analysis, robustness, writing, submission.
---

# Write Plan

## Overview

This skill writes a detailed, research-structured implementation plan from an approved design spec. It begins by invoking `academic-baseline` as the standing policy layer for the planning session. The plan is organized in research phases — not software phases — and every task has an expected artifact, verification criterion, and explicit skill routing. `replication-driven-research` is invoked as a hard constraint: every task must produce a versionable artifact and fit into an end-to-end reproducible pipeline.

## When to Use

- An approved design spec exists in `docs/superpapers/specs/`
- User says "now write the plan", "let's plan this out", or "next step"
- Transitioning from `brainstorm` to implementation
- Planning a revision round after reviewer feedback

## Prerequisites

- A spec in `docs/superpapers/specs/YYYY-MM-DD-<topic>-design.md`, written and approved via `brainstorm`
- User has confirmed they want to proceed from the spec to a concrete plan

## Mandatory Steps

1. **Invoke `academic-baseline` first.** Load `CLAUDE.superpapers.md` if present and carry its settings and principles through the entire planning step.

2. **Read the design spec in full.** Understand every decision the brainstorm made — research question, identification strategy, data sources, models, robustness plan, submission target.

3. **Decompose into tasks following the canonical research phases** (see below). Aim for bite-sized tasks — 10 to 30 minutes of work each. If a task is a full day of work, split it.

4. **For every task, specify all task-template fields** (see template below). No placeholders. Every field filled explicitly.

5. **Map dependencies.** Later phases depend on earlier phases. Within a phase, tasks may be parallel or sequential — mark explicitly.

6. **Assign skills deliberately.** The `Skills involved` field is mandatory routing metadata, not decoration. Include `academic-baseline` on every task as the standing foundation, then add the domain skills actually needed. Any task involving target journal selection, author instructions, formatting, templates, blinding, cover letters, checklists, or submission portals must include `journal-guidelines`; if the outlet is not fixed yet, include `journal-selection` before `journal-guidelines`.

7. **Apply `replication-driven-research` as a constraint.** Every task must produce a versionable artifact. Every stochastic script must fix the seed. Every output must feed into an end-to-end pipeline.

8. **Write the plan** to `docs/superpapers/plans/YYYY-MM-DD-<topic>-plan.md` in English. The plan is a plugin artifact like the spec — English for consistency.

9. **Self-review** for coverage (every spec requirement has a task?), placeholders, name or type consistency across tasks, skill routing completeness, and scope fit (can this be one plan or does it need splitting?).

10. **Offer execution options.** Present `execute-plan` as the next step, with the choice between subagent-driven execution and inline execution.

## Canonical Research Phases

The plan is organized in these phases — not software phases. Each phase has tasks; each task has an expected artifact and a verification step.

### 1. Collection
Fetch raw data. Tasks: identify sources (via `data-collection`), implement collection scripts, save to `data/raw/`, update `data/manifest.md`. Verification: raw files exist, manifest entries present.

### 2. Preparation
Clean and merge. Tasks: cleaning scripts, merge logic, derived variables, sample selection rules. Verification: processed data exists in `data/processed/`, sample selection documented.

### 3. Exploratory Analysis
Descriptive statistics, visualizations, data quality checks. Tasks: `tab_descriptives.tex`, `fig_trends.pdf`, anomaly detection. Verification: outputs exist; a reviewer can read them before the main analysis.

### 4. Main Analysis
The specified model from the design. Tasks: one estimation script per specification (main, alternate outcome, alternate controls). Verification: `tab_main_results.tex` exists, coefficients reproducible.

### 5. Robustness
Canonical checks for the design (via `robustness-checks`). Tasks: one script per check, one table or column per check. Verification: `tab_robustness.tex` exists; all checks present; failures discussed.

### 6. Writing
Paper sections from data to narrative. Tasks: draft each section (Abstract, Introduction, Data, Methods, Results, Discussion, Conclusion), pull tables and figures via `\input{}` and `\includegraphics{}`. Writing tasks operate under `academic-baseline`; use `journal-guidelines` here only when the work is already tied to a specific journal template or formatting requirement. Verification: `paper.tex` compiles with `compile-latex`.

### 7. Submission
Target journal, formatting, checklist. Tasks: invoke `journal-selection` if not already decided, then invoke `journal-guidelines` for the chosen journal, adapt the manuscript and submission materials, and run the final compliance check. Journal-facing work without `journal-guidelines` is invalid. Verification: submission checklist complete.

## Task Template

Every task must specify:

- **Title** — imperative, actionable (e.g., "Collect unemployment series from IBGE")
- **Phase** — one of the 7 above
- **Inputs** — files or datasets this task reads
- **Outputs** — files this task produces
- **Script** — path to the script that implements it (e.g., `code/01_collect.R`)
- **Verification** — command or check to verify the task completed (file exists and is non-empty, script exits 0, pipeline still runs end-to-end)
- **Skills involved** — which superpapers skills are invoked. This field is mandatory routing metadata: include `academic-baseline` on every task, add the relevant domain skills (e.g., `statistical-modeling`, `tables-and-figures`, `data-collection`), and include `journal-guidelines` on every journal-facing task
- **Commit message** — exact message to use after the task succeeds

## Anti-Patterns

- Plan organized by software phases (architecture, backend, frontend) instead of research phases
- Tasks with vague outputs ("build the analysis", "write the results section")
- Tasks without verification criteria
- Skipping the manifest update in the collection phase
- Hardcoding numeric results in the writing phase
- Planning robustness checks before knowing the main result's design
- A task that mixes multiple phases
- Omitting `academic-baseline` from a task's `Skills involved`
- Scheduling journal-facing work without `journal-guidelines`
- Placeholders anywhere in the plan — any "fill in later" marker or empty step
- Using "similar to Task N" instead of repeating the details — tasks are often read in isolation

## Verification Before Completion

- [ ] Every spec requirement mapped to at least one task
- [ ] All 7 phases represented, or a phase explicitly excluded with reason
- [ ] Every task has inputs, outputs, script path, verification, skills, commit message
- [ ] Every task includes `academic-baseline` plus the necessary domain skills
- [ ] Every journal-facing task includes `journal-guidelines` (or `journal-selection` followed by `journal-guidelines` when the outlet is still undecided)
- [ ] No placeholders in the plan
- [ ] Dependencies between tasks explicit
- [ ] Plan saved to `docs/superpapers/plans/` in English
- [ ] Self-review completed
- [ ] Execution options (`execute-plan` subagent-driven vs inline) offered to the user

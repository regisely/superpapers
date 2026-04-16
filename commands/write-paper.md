---
description: Draft, rewrite, review, or audit prose for a paper section using the superpapers paper-writing skill
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion
---

Use the `academic-baseline` skill first, then the `paper-writing` skill from the superpapers plugin for the current project.

Command intent:

- Apply universal academic prose discipline to drafting a new section, rewriting an existing passage, reviewing a finished section, or producing a specialized output (job market paper, grant proposal, policy brief, op-ed, referee response).
- This command does not collect data, run analysis, or produce tables / figures. It writes and revises prose.

Argument hint:

- "draft introduction for the minimum-wage paper"
- "rewrite this paragraph for clarity"
- "review the results section in paper/paper.tex"
- "audit my paper end-to-end with the 100-point rubric"
- "tighten my abstract to under 150 words"
- "draft a referee response based on the comments in docs/referee_report.md"
- "convert my working paper to a journal version targeting [journal]"

Execution rules:

1. Inspect the project for:
   - `docs/superpapers/specs/` (current design spec, used to determine paper type)
   - `docs/superpapers/plans/` (current plan, in case this command is being run as part of a Writing-phase task)
   - `paper/paper.tex` and `paper/references.bib` (the artifact being drafted, rewritten, or reviewed)
   - `output/tables/`, `output/figures/` (referenced by `\input{}` and `\includegraphics{}` — never re-create these here)
   (`CLAUDE.superpapers.md` is loaded automatically by `academic-baseline` on activation — no manual check needed here.)

2. Identify the writing task type from the user's request:
   - **Drafting** new text → load `references/section-formulas.md` for the target section.
   - **Rewriting** existing text → load `references/style-rules.md` and identify violations.
   - **Reviewing / auditing** → load `references/review-checklist.md` and apply the 3-reviewer simulation + 100-point rubric.
   - **Specialized output** (JMP, grant, policy brief, op-ed, referee response) → load the relevant section of `references/section-formulas.md`.

3. Identify the paper type (applied empirical, theory, mixed theory-empirical, structural, descriptive) from the design spec when present, or ask the user.

4. Run the `paper-writing` skill as the authoritative workflow:
   - invoke `academic-baseline` first and keep it active through writing
   - apply the seven core principles (Reader First, Triangular Style, One Contribution, Concrete, Every Word Counts, Active Voice, Simple > Complex)
   - apply the style rules from `references/style-rules.md` including the AI-pattern avoidance list
   - respect `paper_language` from `CLAUDE.superpapers.md`
   - mark author-input gaps with `[AUTHOR: …]` — never invent numbers, citations, dataset names, or institutional details
   - use causal vs correlational language deliberately per academic-baseline principle 4
   - run the five-pass self-check before declaring the output done

5. Defer to sibling skills for non-prose work:
   - tables / figures → `tables-and-figures` (do not regenerate them here)
   - new bibliography entries → `citation-management`
   - LaTeX compilation → `compile-latex`
   - replication / reproducibility scaffolding → `replication-driven-research`
   - canonical robustness checks → `robustness-checks`
   - journal-specific formatting → `journal-guidelines`

6. Keep this command within superpapers. Do not route to generic writing behavior from other plugins.

7. At the end, state explicitly:
   - what was drafted, rewritten, or reviewed, and where it lives in the project
   - any `[AUTHOR: …]` gaps the user must resolve
   - next step (typically: re-run `/superpapers:execute-plan` to advance the plan, or `/superpapers:write-paper` again to iterate on another section, or compile via `compile-latex` to verify the draft renders)

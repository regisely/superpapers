---
name: brainstorm
description: Use when starting a new research project, exploring a research idea, deciding whether a question is viable, or before touching code or data for a new paper. Runs a research-focused brainstorm that clarifies research question, identification strategy, data feasibility, and contribution before any implementation.
---

# Brainstorm

## Overview

This is the first step in the superpapers pipeline for any new research project. It starts by invoking `academic-baseline` as the standing policy layer for the session, then mirrors the Superpowers brainstorming philosophy — Socratic questions, proposed approaches, incremental design approval — but asks research-specific questions. The terminal state is invoking `write-plan`. No implementation, data collection, or literature review beyond gap-verification happens until the design spec is written and approved by the user.

## When to Use

- "I have an idea for a paper"
- "I want to study X"
- "Can you help me think through this research question?"
- Start of any new empirical research project
- Before any data collection or analysis begins
- Revisiting a stalled project with a new angle

## When NOT to Use

- Mid-project troubleshooting — use `statistical-modeling` or the relevant domain skill
- The research question and design are already clear and stable
- Formatting, writing, or submission tasks — use `journal-guidelines` or other late-stage skills

## Hard Gate

Do NOT invoke `write-plan`, `execute-plan`, data collection, analysis, or any literature search beyond gap-verification until the design spec is written and the user has explicitly approved it. This applies to every project regardless of apparent simplicity.

## Mandatory Steps

1. **Invoke `academic-baseline` first.** Load `CLAUDE.superpapers.md` if present, carry its settings into the session, and apply `academic-baseline` principles from the first question onward.

2. **Explore project context.** Check for `CLAUDE.superpapers.md`, existing `data/`, `paper/`, `.bib` files, and git history. Learn what already exists before asking questions.

3. **Detect research field and paper language.** From project context when possible; otherwise ask the user. The field shapes which databases, methods, and journals will be relevant. The paper language determines later user-facing output.

4. **Ask Socratic questions one at a time.** Do not batch. Use multiple choice where possible. Cover these topics in roughly this order:
   - **Research question:** What is the question? Can it be rejected by data?
   - **Exploratory vs confirmatory:** This shapes every downstream decision — specification rigidity, multiple testing corrections, framing.
   - **Causal vs descriptive:** What would a causal answer require — and is that answerable with the available data?
   - **Identification strategy:** Candidate — DiD, RD, IV, SC, time-series, none (descriptive)?
   - **Data:** What would you need? Does it exist? Is it accessible? At what cost?
   - **Contribution:** What's the contribution over existing literature? Invoke `literature-search` briefly to verify the gap is real.
   - **Statistical power:** Order-of-magnitude check — is the sample large enough to detect plausible effect sizes?
   - **Publication tier:** Target journal tier — and is the design consistent with that tier's expectations?

5. **Propose 2-3 empirical approaches with trade-offs.** Always recommend one and explain why. Present options conversationally, not as a menu.

6. **Present the research design section by section, getting approval after each section.** Sections: research question, data strategy, identification strategy, estimation plan, expected outputs (tables/figures), robustness plan, submission target.

7. **Scale each section to its complexity.** A simple descriptive study may need one paragraph per section. A novel identification strategy may need several.

8. **Write the spec** to `docs/superpapers/specs/YYYY-MM-DD-<topic>-design.md` in English. The spec is a plugin artifact, not paper content — English keeps it consistent across projects.

9. **Self-review the spec** for placeholders, internal contradictions, scope problems, and ambiguous requirements. Fix inline.

10. **Ask the user to review the written spec.** Wait for explicit approval before proceeding.

11. **Transition to `write-plan`.** This is the only terminal state. Do not invoke `execute-plan` or any implementation skill directly.

## Guardrails

- Invoke `academic-baseline` principles throughout — especially the causal-versus-correlational distinction.
- Invoke `replication-driven-research` as a constraint on the design: the plan must be reproducible end-to-end.
- Never commit to a result framing in advance. The brainstorm ends with a design, not with conclusions.
- Questions asked in the user's conversation language. Spec documents written in English (plugin artifact). User paper content respects the paper language later.

## Anti-Patterns

- Batching multiple questions in one message
- Jumping to implementation before a design is approved
- Skipping the exploratory-versus-confirmatory distinction
- Proposing only one approach instead of 2-3
- Writing the spec without user approval
- Letting the user drift into "it's too simple to need a design" — every project gets a design, even if short
- Assuming a causal answer is feasible without asking about identification
- Starting literature search, data collection, or analysis during the brainstorm itself (beyond minimal gap verification)

## Verification Before Completion

- [ ] Research field detected and confirmed
- [ ] Paper language established (even if default English)
- [ ] `academic-baseline` invoked first and applied throughout the brainstorm
- [ ] Research question is falsifiable and explicit
- [ ] Exploratory-versus-confirmatory distinction made
- [ ] Identification strategy identified (or "none, this is descriptive" made explicit)
- [ ] Data feasibility confirmed
- [ ] Contribution over literature established
- [ ] 2-3 approaches presented with a recommendation
- [ ] Design presented section by section with approval
- [ ] Spec written to `docs/superpapers/specs/` in English
- [ ] User approved the spec
- [ ] Next step (`write-plan`) announced, not executed

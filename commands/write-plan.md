---
description: Translate an approved superpapers design spec into a research execution plan
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion
---

Use the `academic-baseline` skill first, then the `write-plan` skill from the superpapers plugin for the current project.

Command intent:

- Take an approved research design spec and turn it into a phased empirical research plan.

Execution rules:

1. Inspect the project for:
   - `docs/superpapers/specs/`
   - `docs/superpapers/plans/`
   - `CLAUDE.superpapers.md`

2. If no design spec exists, do not improvise a plan from thin air. Tell the user that the expected previous step is `/superpapers:brainstorm`, unless they already have a design elsewhere and want to provide it.

3. If a spec exists, prefer the most recent approved spec unless the user points to a different one.

4. Run the `write-plan` skill as the authoritative workflow:
   - invoke `academic-baseline` first and keep it active through planning
   - read the spec in full
   - organize work into research phases
   - write the plan to `docs/superpapers/plans/`
   - make verification criteria explicit per task
   - require explicit `Skills involved` per task, including `academic-baseline` on every task and `journal-guidelines` on every journal-facing task

5. Keep this command within superpapers. Do not route to generic planning behavior from other plugins.

6. At the end, state the next step explicitly:
   - next step is usually `/superpapers:execute-plan`
   - `/superpapers:init` can still be used later if the project settings file has not been created yet

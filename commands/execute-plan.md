---
description: Execute a superpapers research plan phase by phase with reproducibility checks
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion
---

Use the `academic-baseline` skill first, then the `execute-plan` skill from the superpapers plugin for the current project.

Command intent:

- Execute an approved superpapers research plan with phase-by-phase verification and replication-driven discipline.

Execution rules:

1. Inspect the project for:
   - `docs/superpapers/plans/`
   - `docs/superpapers/specs/`
   - current project structure and outputs
   (`CLAUDE.superpapers.md` is loaded automatically by `academic-baseline` on activation — no manual check needed here.)

2. If no plan exists, do not jump directly into execution. Tell the user the expected previous step is `/superpapers:write-plan`, unless they already have a concrete plan they want to execute.

3. If a plan exists, prefer the most recent approved plan unless the user specifies another one.

4. Run the `execute-plan` skill as the authoritative workflow:
   - invoke `academic-baseline` first and keep it active through execution
   - load the plan in full
   - honor each task's `Skills involved` field as required routing
   - invoke `replication-driven-research`
   - invoke `journal-guidelines` for any journal-facing task
   - execute phase by phase
   - stop on verification failures
   - summarize phase boundaries and final status

5. Keep this command within superpapers. Do not route to generic execution behavior from other plugins.

6. Execution proceeds without `CLAUDE.superpapers.md`; `academic-baseline` asks inline for any setting it needs.

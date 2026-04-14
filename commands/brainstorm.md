---
description: Start the superpapers brainstorm workflow for a research project
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion
---

Use the `academic-baseline` skill first, then the `brainstorm` skill from the superpapers plugin for the current project.

Command intent:

- Start a new empirical research project or re-open an early-stage idea.
- Run the research-specific brainstorm workflow, not the generic software-planning workflow.

Execution rules:

1. Inspect the current project context first:
   - `docs/superpapers/specs/`
   - `data/`, `paper/`, `.bib` files
   - existing plans or notes
   (`CLAUDE.superpapers.md` is loaded automatically by `academic-baseline` on activation — no manual check needed here.)

2. If the project already has an approved design spec, do not start a fresh brainstorm silently. Tell the user what already exists and ask whether they want to revise the existing design or start a new one.

3. If no approved spec exists, run the `brainstorm` skill exactly as intended by the plugin:
   - invoke `academic-baseline` and `replication-driven-research` first; invoke `statistical-modeling`, `journal-selection`, and `data-collection` at the appropriate Socratic steps as the skill prescribes
   - establish field and paper language
   - ask Socratic research questions one at a time
   - compare approaches with trade-offs
   - write the design spec to `docs/superpapers/specs/` (the full literature review is not part of brainstorm — it is a task in the execution pipeline, scheduled by `write-plan`)

4. Keep this command in the research domain. Do not delegate to generic `/brainstorm` behavior from other plugins.

5. At the end, make the transition explicit:
   - next step is usually `/superpapers:write-plan`
   - the design spec stands on its own as the authoritative research design; any optional project-level settings live separately in `CLAUDE.superpapers.md` only if the user chose to create one

---
description: Start the superpapers brainstorm workflow for a research project
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion
---

Use the `brainstorm` skill from the superpapers plugin for the current project.

Command intent:

- Start a new empirical research project or re-open an early-stage idea.
- Run the research-specific brainstorm workflow, not the generic software-planning workflow.

Execution rules:

1. Inspect the current project context first:
   - `CLAUDE.superpapers.md`
   - `docs/superpapers/specs/`
   - `data/`, `paper/`, `.bib` files
   - existing plans or notes

2. If the project already has an approved design spec, do not start a fresh brainstorm silently. Tell the user what already exists and ask whether they want to revise the existing design or start a new one.

3. If no approved spec exists, run the `brainstorm` skill exactly as intended by the plugin:
   - establish field and paper language
   - ask Socratic research questions one at a time
   - compare approaches with trade-offs
   - write the design spec to `docs/superpapers/specs/`

4. Keep this command in the research domain. Do not delegate to generic `/brainstorm` behavior from other plugins.

5. At the end, make the transition explicit:
   - next step is usually `/superpapers:write-plan`
   - `CLAUDE.superpapers.md` is separate from the design spec
   - if the project settings file is missing, mention that `/superpapers:init` can create or update it

---
description: Create or update CLAUDE.superpapers.md for the current research project
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion
---

Create or update `CLAUDE.superpapers.md` in the current project root.

Goals:

- Make the file optional but easy to generate.
- Prefer existing project context over asking the user to retype information.
- Preserve user edits when the file already exists.

Workflow:

1. Inspect the current project root for:
   - `CLAUDE.superpapers.md`
   - `docs/superpapers/specs/*.md`
   - `docs/superpapers/plans/*.md`
   - `paper/`, `data/`, `.bib` files
   - common lockfiles such as `renv.lock`, `uv.lock`, `requirements.txt`, `poetry.lock`, `package-lock.json`

2. If one or more design specs exist in `docs/superpapers/specs/`, prefer the most recent spec as the main source of truth unless the user explicitly asks for a different one.

3. Extract as many settings as possible from the spec and project context:
   - project name
   - field
   - research question
   - type (`exploratory` or `confirmatory`)
   - identification strategy
   - paper language
   - significance convention
   - primary target journal
   - backup journals
   - tier strategy
   - default seed
   - R version / Python version if already documented anywhere
   - package lockfile

4. Ask the user only for missing high-value settings that cannot be inferred safely. Keep questions minimal. If a recent brainstorm spec exists, do not re-ask things already settled there.

5. Use `templates/CLAUDE.superpapers.md` as the base format.
   - If the file does not exist, create it in the project root.
   - If it already exists, update the populated fields in place and preserve any custom instructions the user already added when possible.
   - If there is a conflict between the existing file and the most recent spec, show the conflict briefly and ask before overwriting the existing value.

6. Do not create the canonical directory structure in this command unless the user explicitly asks for scaffolding too. This command is only for the project settings file.

7. After writing the file, summarize:
   - where the file was written
   - which values came from the brainstorm spec or project context
   - which values were filled by asking the user
   - which values remain intentionally generic

Important constraints:

- `CLAUDE.superpapers.md` is recommended, not mandatory. If the user decides not to create it, say that superpapers can still work from conversation context.
- Treat the file as persistent project configuration, not as the brainstorm spec itself.
- Never fabricate a journal target, identification strategy, or research question just to fill every field.

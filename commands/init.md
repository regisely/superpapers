---
description: Create or update CLAUDE.superpapers.md in the current paper folder
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion
---

Create or update `CLAUDE.superpapers.md` in the current working directory (the paper folder the user is working in).

This command is opt-in and aimed at advanced users who want to pre-populate project settings, pin reproducibility defaults, or add explicit rules and preferences that every skill invocation will respect. The plugin does not require this command to be run. Brainstorm, write-plan, execute-plan, and every other skill work without `CLAUDE.superpapers.md` — they ask for settings inline when needed.

When `CLAUDE.superpapers.md` exists, every superpapers skill reads it on activation (walking up from the current working directory to find it), so anything the user writes in the file — seed, paper language, target journals, significance convention, custom rules, preferred workflow steps — becomes the standing project config for the session.

## Workflow

1. Inspect the current working directory and its parents for signals:
   - existing `CLAUDE.superpapers.md` in CWD or any parent directory
   - `docs/superpapers/specs/*.md`
   - `docs/superpapers/plans/*.md`
   - `paper/`, `data/`, `.bib` files
   - lockfiles: `renv.lock`, `uv.lock`, `requirements.txt`, `poetry.lock`, `package-lock.json`

2. If one or more design specs exist in `docs/superpapers/specs/`, prefer the most recent spec as the main source of truth unless the user explicitly points to a different one.

3. Extract as many settings as possible from the spec, the existing `CLAUDE.superpapers.md` (if any), and project context:
   - project name
   - field
   - research question (summary)
   - type (`exploratory` or `confirmatory`)
   - identification strategy (summary)
   - paper language
   - code language (R | Python | both | other) — infer from existing scripts when present; ask if undetermined
   - significance convention
   - primary target journal
   - backup journals
   - tier strategy

4. Ask the user only for missing high-value settings that cannot be inferred safely. Keep questions minimal and batched where reasonable. If a recent brainstorm spec exists, do not re-ask things already settled there.

5. Render the file from `templates/CLAUDE.superpapers.md` with the gathered settings and write it to `CLAUDE.superpapers.md` in the current working directory.
   - If the file does not exist, create it.
   - If the file already exists, update populated fields in place and preserve any custom rules, instructions, or user-authored sections the user already added.
   - If a populated field conflicts with the most recent spec, show the conflict briefly and ask before overwriting.

6. After writing, echo the full content of the file verbatim in the summary message. This ensures the written content is in the current session's context so any skill invoked later in the same session sees it without needing to re-read disk. From the next Claude Code session onward, skills read the file from disk on activation.

7. Summarize:
   - where the file was written (absolute path)
   - which values came from the spec, existing file, or project context
   - which values were filled by asking the user
   - which values remain intentionally generic

## Important Constraints

- `CLAUDE.superpapers.md` is recommended for advanced users, not mandatory. Superpapers works without it — skills ask inline when a setting is needed.
- This command is never called or suggested by other skills or commands. It exists purely for users who choose to invoke it.
- Treat the file as persistent project configuration, not as the brainstorm spec. The spec is the authoritative research design; this file carries reproducibility config, routing preferences, and user rules.
- Never fabricate a journal target, identification strategy, or research question to fill every field. Leave ambiguous fields generic rather than inventing content.
- In a multi-paper repo, the command writes to whichever paper folder is the current working directory. Users working on multiple papers should `cd` into the specific paper's folder before invoking.

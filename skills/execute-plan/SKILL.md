---
name: execute-plan
description: Use when a research implementation plan exists in docs/superpapers/plans/ and the user is ready to execute it — collecting data, running analysis, producing outputs, writing the paper. Orchestrates task execution with replication-driven verification and two-stage review at phase boundaries.
---

# Execute Plan

## Overview

This skill executes a research plan phase by phase. It dispatches subagents for independent tasks, invokes `replication-driven-research` as a guardrail, and runs two-stage review at phase boundaries: correctness first, reproducibility second. Stops and asks the user at any scaffolding or destructive action. The skill never proceeds past a phase until both reviews pass.

## When to Use

- A plan exists in `docs/superpapers/plans/`
- User says "execute the plan", "run the plan", or "let's start implementing"
- Transitioning from `write-plan` to implementation
- Resuming execution of a partially-completed plan

## Prerequisites

- An approved plan in `docs/superpapers/plans/YYYY-MM-DD-<topic>-plan.md`
- User has explicitly confirmed they want to proceed to execution
- `replication-driven-research` has been invoked at least once in this project (to scaffold directories) or will be invoked as the first step

## Mandatory Steps

1. **Load and parse the plan.** Read the plan file in full. Extract tasks, phases, dependencies, and verification criteria.

2. **Invoke `replication-driven-research` to ensure project structure.** If directories are missing, propose scaffolding. Wait for user confirmation before creating directories or files at the project root.

3. **Execute tasks phase by phase.** Within a phase, independent tasks can be dispatched to subagents in parallel. Sequential tasks run in order.

4. **Verify after every task.** Run the task's verification command. If it fails, stop and diagnose — do not proceed silently.

5. **Run end-to-end integration at each phase boundary.** Execute the full pipeline from `data/raw/` to the farthest artifact produced so far. Confirm exit code 0 and that all expected outputs exist.

6. **Two-stage phase review:**
   - **Stage 1 — correctness.** Are the results right? Does the analysis make sense? Narrative review of the outputs, specs, and diagnostics.
   - **Stage 2 — reproducibility.** Is the pipeline clean end-to-end? Is the seed fixed? Is the manifest updated? Use the `replication-driven-research` verification checklist.

7. **Only proceed to the next phase after both stages pass.**

8. **On failure: stop, diagnose root cause, fix, re-run from the failing task.** Never skip failed tasks. Never re-run from scratch without understanding what broke.

9. **Final full-pipeline run.** Before declaring the plan complete, run everything from raw data to final PDF. All verifications must pass.

10. **Report status to the user at phase boundaries.** At the end, summarize what was built, what passed review, and where the artifacts live.

## Subagent Dispatch

Use subagents for:

- Independent collection tasks (different data sources, no shared files)
- Independent robustness checks (different specifications, writing to different files)
- Independent exploratory analyses (different subgroups or variables)

Do NOT use subagents for:

- Sequential tasks where one depends on another's output
- Writing paper sections (context-dependent, needs the main session's understanding of the project)
- Decisions that require user input
- Tasks that touch the same file (git conflicts, clobber risk)

## Guardrails

- **Scaffolding is not automatic.** Always ask the user before creating directories, files, or structure outside the plan.
- **Destructive actions need confirmation.** Never delete data, reset git state, force-push, or overwrite existing artifacts without explicit user approval.
- **Invalidation on input change is mandatory.** If raw data or a script changes mid-execution, all downstream outputs are stale. Re-run the affected phases — do not patch around the invalidation.
- **No result is final until the pipeline runs end-to-end.** "It worked in my session" is not evidence. Only a clean end-to-end run counts.
- **Stop on any verification failure.** Do not mask errors by re-running, ignoring warnings, or adjusting thresholds.

## Anti-Patterns

- Skipping verification between tasks
- Declaring a phase complete without the end-to-end integration run
- Running tasks out of dependency order
- Silent failures — masking errors to keep moving
- Editing downstream outputs when an upstream input changed, without re-running the pipeline
- Parallelizing tasks that share state or touch the same files
- Forgetting to update the manifest or logs
- Skipping user confirmation for scaffolding or destructive actions
- Declaring success without the final full-pipeline run

## Verification Before Completion

- [ ] Every task in the plan executed (or explicitly skipped with reason)
- [ ] Verification command of every task passed
- [ ] Every phase ended with an end-to-end pipeline run
- [ ] Two-stage review (correctness + reproducibility) completed per phase
- [ ] Final full-pipeline run exits with code 0
- [ ] `data/manifest.md` up to date with every dataset used
- [ ] `output/logs/` contains the latest execution log
- [ ] All expected outputs exist in `output/tables/`, `output/figures/`, and `paper/`
- [ ] Plan file updated with completion status per task
- [ ] Final commit recorded

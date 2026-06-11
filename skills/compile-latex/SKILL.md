---
name: compile-latex
description: Use when compiling a LaTeX paper, debugging LaTeX errors, building a paper PDF, or when a .tex file fails to produce output. Handles engine detection (xelatex vs pdflatex), bibliography systems (biber vs bibtex), and multi-pass compilation.
---

# Compile LaTeX

## Overview

This skill compiles LaTeX documents correctly with the right engine and bibliography system, handles multi-pass compilation, and parses errors to suggest fixes. It ships with a wrapper script (`scripts/compile.sh`) that detects everything automatically and can be invoked directly.

## When to Use

- Compiling any `.tex` file
- "The paper won't compile"
- LaTeX error messages appearing in output
- Generating the final PDF for submission
- CI or automated builds of a paper
- Verifying that cross-references and citations resolve correctly

## Mandatory Steps

1. **Detect the engine from the preamble.** Look for `\usepackage{fontspec}`. If present, use `xelatex`. Otherwise use `pdflatex`. The wrapper script does this automatically.

2. **Detect the bibliography system.** `\usepackage{biblatex}` in the preamble implies biber. `\bibliography{...}` at the end of the document implies bibtex. Neither implies no bibliography pass.

3. **Prefer `latexmk` if available.** It handles multi-pass logic automatically and is more robust than running passes manually.

4. **If `latexmk` is unavailable, run the manual sequence:** engine → bib (if applicable) → engine → engine.

5. **On error, parse the log file** (`<base>.log`). Extract lines starting with `!`, report the line number and file, and suggest a likely fix from the error table below.

6. **Verify the PDF was produced** after successful compilation and that it is non-empty.

7. **Run the post-compile checks: `scripts/check-log.sh <paper.tex>`.** It verifies that the log has no `Overfull \hbox` above 5pt, no undefined citations or references, and that citations render in the expected style. The plugin default is **author–year citations** (e.g., `(Card and Krueger, 1994)`); numeric citations (`[1]`) are acceptable only when the target journal explicitly requires them per `journal-guidelines` — pass `--citation-style=numeric` in that case. For journal classes that load natbib internally (elsarticle and similar), author–year requires the class option — `\documentclass[preprint,12pt,authoryear]{elsarticle}`; `\bibliographystyle{elsarticle-harv}` alone still renders numeric citations. **Gate: compilation is not complete until `check-log.sh` exits 0.** If it fails on a table overflow, apply the overflow ladder from `tables-and-figures` and recompile.

## Using the Wrapper Script

Invoke the compile script directly:

```bash
./skills/compile-latex/scripts/compile.sh paper/paper.tex
```

The script detects engine and bibliography system, runs `latexmk` if available, falls back to manual multi-pass otherwise, and exits non-zero on failure. All detection and pass logic is handled internally — no flags needed beyond the path to the `.tex` file.

After a successful compile, always run the post-compile gate:

```bash
./skills/compile-latex/scripts/check-log.sh paper/paper.tex
# numeric citations only with a documented journal requirement:
./skills/compile-latex/scripts/check-log.sh paper/paper.tex --citation-style=numeric
```

## Common Errors and Fixes

| Error | Cause | Fix |
|-------|-------|-----|
| `Undefined control sequence \foo` | Missing package | Add `\usepackage{pkg}` providing `\foo` |
| `File 'x.sty' not found` | Missing package | Install TeX package (`tlmgr install x`) |
| `Citation 'X' undefined` | Bib pass not run | Run biber or bibtex, then re-run engine |
| `Missing \begin{document}` | Preamble typo | Check brace balance in preamble |
| `Package fontspec Error` | Used pdflatex instead of xelatex | Switch engine |
| `Overfull \hbox` | Line, table, or figure wider than the text width | In tables/figures: must fix — apply the `tables-and-figures` overflow ladder. In prose: rephrase the line. Never ignore overfulls above 5pt |
| `LaTeX Error: File 'x.tex' not found` | Missing `\input{}` target | Verify path relative to the main file |

## Anti-Patterns

- Running `pdflatex` on a document that needs `xelatex`
- Ignoring `Citation undefined` warnings — they mean the bibliography is broken
- Single-pass compilation when cross-references exist (`\ref`, `\cite`, `\label`)
- Committing `.aux`, `.log`, `.bbl`, `.out`, `.toc`, `.fls`, `.fdb_latexmk` auxiliary files to git
- Ignoring errors and just "running it again" until it compiles
- Treating `Overfull \hbox` in tables or figures as ignorable — it means content bleeds into the margin
- Compiling an elsarticle (or similar journal-class) paper without the `authoryear` class option when author–year citations are expected
- Declaring compilation done without running `check-log.sh`

## Verification Before Completion

- [ ] Engine detected matches preamble requirements
- [ ] Bibliography system correctly identified
- [ ] Multi-pass executed when needed (engine → bib → engine → engine)
- [ ] Exit code 0 from the compile step
- [ ] `<base>.pdf` exists and is non-empty
- [ ] No `Undefined` warnings in the final log
- [ ] `scripts/check-log.sh` exits 0 (no overfull above 5pt, no undefined references, citation style as expected)
- [ ] Citations render author–year in the PDF (or numeric with a documented journal requirement)
- [ ] Auxiliary files not staged in git

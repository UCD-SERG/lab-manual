# CLAUDE.md

Guidance for Claude Code (and other AI assistants) working in this repository.

## What this is

This is the UCD-SeRG Lab Manual: the Seroepidemiology Research Group's authority
on coding, reproducibility, and collaboration conventions. It is built with
[Quarto](https://quarto.org/) as a book and published as a website at
<https://ucd-serg.github.io/lab-manual/>. The repo is also a small R package
(`labmanual`, see `DESCRIPTION`) so it can carry R dependencies and a wordlist.

`.github/copilot-instructions.md` is the source of truth for repository-specific
style and workflow. This file is a short orientation; when the two disagree,
copilot-instructions.md wins. Read it before non-trivial content edits.

## Repository layout

- `index.qmd`, `*.qmd` at the root - chapter sources, listed in `_quarto.yml`
- `<chapter-name>/` subdirectories - Quarto `{{< include >}}` fragments for each
  chapter (e.g. `coding-style/`, `ai-tools/`, `coding-practices/`)
- `appendix-*.qmd` - appendices, also wired into `_quarto.yml`
- `_quarto.yml` - the only Quarto config; `type: book`, `output-dir: docs`,
  HTML + PDF + DOCX + EPUB formats, chapter and appendix lists
- `book.bib`, `packages.bib` - BibTeX bibliographies (`references.qmd` renders them)
- `_extensions/` - vendored Quarto Lua filters; do not edit
- `R/`, `man/`, `NAMESPACE`, `DESCRIPTION` - the R-package shell
- `lms/` - the shared UCD-SERG linter package, installed locally for linting
- `inst/WORDLIST` - accepted spell-check terms
- `lychee.toml` - link-checker config; `.lintr.R` - lint config
- `.github/workflows/` - CI; `.github/scripts/` - Python helpers for preview/checks
- `.ai-config/` - git submodule (`d-morrison/ai-config`); see below
- `docs/`, `.quarto/`, `_freeze/`, `*_files/` - build outputs, git-ignored; do not edit

## Build, preview, render

```bash
quarto render                          # full book, all formats -> docs/
quarto preview                         # live-reload local preview
quarto render coding-style.qmd --to html   # one chapter, HTML only
```

Render a single chapter when verifying one page; render the full book before
requesting review. CI publishes from `main` via `.github/workflows/publish.yml`;
each PR gets a preview through `preview.yml`.

The render depends on the `.ai-config` submodule (chapters transclude its
`shared/` fragments), so populate it first:

```bash
git submodule update --init --recursive
```

## The `.ai-config` submodule

`.ai-config` vendors `d-morrison/ai-config`. It supplies two things:

- `shared/` guidance fragments that chapters transclude, e.g.
  `{{< include .ai-config/shared/coding/avoid-nesting.md >}}` in `coding-style.qmd`
  and the writing/workflow fragments in `writing.qmd` and `ai-tools.qmd`. The
  fragment is the single source of truth, shared with ai-config's own CLAUDE.md.
- Reusable Claude skills, exposed as project skills through the symlink
  `.claude/skills -> ../.ai-config/skills`.

A plain clone leaves the submodule empty and the symlink dangling. The
`bump-ai-config.yml` workflow advances the pointer to ai-config's `main` weekly
and opens a PR. The build and `@claude` workflows check out with
`submodules: recursive`.

Note: the repo also has a top-level `shared/` directory (vendored
`copilot-review-before-human.md`, `prompt-formats.md`) that `ai-tools.qmd`
includes directly. That is separate from `.ai-config/shared/`.

## CI checks and how to satisfy them

- Spellcheck (`check-spelling.yaml`, `insightsengineering/r-spellcheck-action`).
  Add genuine technical terms and names to `inst/WORDLIST`, one per line.
- Link check (`check-links.yml`, `lycheeverse/lychee-action`) over `.qmd`/`.md`/
  `.html`. Fix broken links; only add an exclusion to `lychee.toml` when a URL
  is valid for humans but trips the automated checker.
- Lint (`lint-project.yaml`, `lintr::lint_dir()`). The root `.lintr.R` calls
  `lms::default_linters()`, so install the local `lms` package first:
  `R CMD INSTALL lms`. Repo-specific exclusions stay in `.lintr.R`, not in `lms`.
- Non-standard characters (`check-non-standard-chars.yaml`). `.qmd` and `.R`
  files must use ASCII only - no curly quotes, no en/em dashes. Use `"`, `'`,
  and `-` (or write the dash as `---` in prose, which Quarto renders as an em dash).
- Render/deploy (`publish.yml`, `preview.yml`) and bibliography DOI checks
  (`check-bibliography-dois.yml`).

Don't bypass a failing check; fix the underlying issue.

## Content conventions (see copilot-instructions.md for the full set)

- Decompose chapters with `{{< include <chapter>/<section>.qmd >}}`. Keep the
  `##` heading in the main chapter file, a blank line, then the include. Prefix
  partial/helper files with `_` so Quarto doesn't render them standalone.
- Leave a blank line before every bullet or numbered list.
- One sentence or phrase per source line (semantic line breaks) in prose,
  comments, and docstrings.
- Backtick code (`dplyr::mutate()`); link packages as
  [`{dplyr}`](https://dplyr.tidyverse.org/). No raw HTML in `.qmd`.
- Use Quarto cross-references: `#fig-`, `#tbl-`, `#sec-`, etc., referenced with
  `@fig-label`. Store images locally under `assets/images/`, not external URLs.
- Use `#| code-fold: true` when the output is the point and the code is incidental.
- R style: tidyverse, native `|>` pipe, `snake_case`, `.qmd` not `.Rmd`.

## Pull request expectations

- Keep PRs scoped; don't smuggle refactors into content fixes.
- Explain the *why* in commit messages and PR descriptions, especially for
  version-pinning and workflow choices.
- Don't commit build outputs (`docs/`, `_freeze/`, rendered previews).
- Render the affected pages and clear the CI checks before requesting review.

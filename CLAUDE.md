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
  chapter (e.g. `coding-style/`, `coding-practices/`)
- `appendix-*.qmd` - appendices, also wired into `_quarto.yml`
- `_quarto.yml` - the only Quarto config; `type: book`, `output-dir: docs`,
  HTML + PDF + DOCX + EPUB formats, chapter and appendix lists
- `book.bib`, `packages.bib` - BibTeX bibliographies (`references.qmd` renders them)
- `_extensions/` - vendored Quarto Lua filters; do not edit
- `DESCRIPTION` - declares the book's R dependencies (package `labmanual`,
  `Type: Book`); the only R-package file at the root
- `lms/` - the shared UCD-SERG linter package (a proper R package with `R/`,
  `man/`, `NAMESPACE`, `DESCRIPTION`), installed locally for linting
- `inst/WORDLIST` - accepted spell-check terms
- `lychee.toml` - link-checker config; `.lintr.R` - lint config
- `.github/workflows/` - CI; `.github/scripts/` - R, Python, and shell helpers for preview/checks
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

R dependencies are managed with `renv` (`renv.lock`, activated by `.Rprofile`).
Run `renv::restore()` once to install them before rendering or linting locally;
CI does the same via `r-lib/actions/setup-renv`.

## CI checks and how to satisfy them

- Spellcheck (`check-spelling.yaml`, `insightsengineering/r-spellcheck-action`).
  Validated against `inst/WORDLIST`.
  Add genuine technical terms, proper nouns, pathogen names, and product names
  introduced in the repository to `inst/WORDLIST`, one per line in alphabetical order.
  All-caps acronyms are not reliably auto-skipped and may need an entry.
  Grep any new proper noun or acronym against `inst/WORDLIST` before pushing.
- Link check (`check-links.yml`, `lycheeverse/lychee-action`) over `.qmd`/`.md`/
  `.html`. Fix broken links; only add an exclusion to `lychee.toml` when a URL
  is valid for humans but trips the automated checker.
- Lint (`lint-project.yaml`, `lintr::lint_dir()`). The root `.lintr.R` calls
  `lms::default_linters()`, so install the local `lms` package first:
  `R CMD INSTALL lms`. Repo-specific exclusions stay in `.lintr.R`, not in `lms`.
  `default_linters()` includes `cyclocomp_linter()` and a custom
  `function_length_linter()` (the `<150` line heuristic from
  `coding-practices/function-length-limits.qmd`; lintr has no built-in
  line-count linter). `lms/tests/testthat.R` already has its own `.lintr.R`
  exclusion entry; the same pattern applies to any nested path --- the
  standard testthat boilerplate's `library()` calls need an explicit entry
  keyed to the nested path (e.g. `"lms/tests/testthat.R"`), since the
  existing root-level `"tests/testthat.R"` exclusion entry is for a
  different, not-yet-existing root-level tests directory and does not match
  nested paths.
- Non-standard characters (`check-non-standard-chars.yaml`). `.qmd`, `.R`,
  and `.md` files must use ASCII punctuation only - no curly quotes, no
  en/em dashes. Use `"`, `'`, and `-` (or write the dash as `---` in prose,
  which Quarto renders as an em dash). The check scans the merge tree, not
  only the PR diff, so a pre-existing hit in any scanned file fails every PR.
- Render/deploy (`publish.yml`, `preview.yml`) and bibliography DOI checks
  (`check-bibliography-dois.yml`). The full-book render (HTML + PDF + DOCX +
  EPUB) plus PR-preview deploy legitimately takes 10-15 minutes; its check-run
  status can lag behind actual completion in the GitHub API, so confirm via
  the job's own step list or the preview-deploy comment's timestamp before
  concluding it is stuck.

Don't bypass a failing check; fix the underlying issue.

## Content conventions (see copilot-instructions.md for the full set)

- Decompose chapters with `{{< include <chapter>/<section>.qmd >}}`. Keep the
  `##` heading in the main chapter file, a blank line, then the include.
  (In a `type: book` project, only chapters listed in `_quarto.yml` render standalone,
  so chapter include fragments do not require an underscore prefix.
  The `_` prefix has no functional effect in this book project;
  follow the naming convention already in use in the chapter subdirectory you are editing).
- Leave a blank line before every bullet or numbered list.
- One sentence or phrase per source line (semantic line breaks) in prose,
  comments, and docstrings.
- Backtick code (`dplyr::mutate()`); link packages as
  [`{dplyr}`](https://dplyr.tidyverse.org/). No raw HTML in `.qmd`.
- Use Quarto cross-references: `#fig-`, `#tbl-`, `#sec-`, etc., referenced with
  `@fig-label`. Store images locally under `assets/images/`, not external URLs.
  A bare markdown anchor link like `[text](#sec-foo)` is **not** the same
  thing and will pass a render but fail review --- always use `[text](@sec-foo)`
  for an internal cross-reference, even when linking custom prose text rather
  than the auto-generated "Section N".
- Use `#| code-fold: true` when the output is the point and the code is incidental.
- R style: tidyverse, native `|>` pipe, `snake_case`, `.qmd` not `.Rmd`.

## Pull request expectations

- Keep PRs scoped; don't smuggle refactors into content fixes.
- Explain the *why* in commit messages and PR descriptions, especially for
  version-pinning and workflow choices.
- Don't commit build outputs (`docs/`, `_freeze/`, rendered previews).
- Render the affected pages and clear the CI checks before requesting review.
- Automated code review is handled by `.github/workflows/claude-code-review.yml`
  (triggered on pull request events and manual workflow dispatch).
  Do not request `copilot-pull-request-reviewer[bot]` via API
  as Copilot PR code review is not active on this repository.

# lms — Lab Manual Style

`lms` ("lab manual style") is the shared UCD-SERG [`{lintr}`](https://lintr.r-lib.org/)
configuration, packaged as a small R package so every lab repository enforces the
**same** linter set without copy-pasting `.lintr.R` files (which drift apart over time).

It lives in the `lms/` subdirectory of
[`UCD-SERG/lab-manual`](https://github.com/UCD-SERG/lab-manual) and exports:

- `default_linters()` — the canonical linter set (`lintr::linters_with_defaults()`
  plus the lab's rules: `|>` pipe consistency, snake_case-with-acronyms object names,
  and `cli::`-oriented undesirable functions).
- `undesirable_functions()` — the underlying undesirable-function map, if a repo needs
  to extend it.

## Using lms in a repository

Each applied repo keeps a thin `.lintr.R` that calls `lms::default_linters()` and
supplies its **own** local exclusions:

```r
# .lintr.R
if (!requireNamespace("lms", quietly = TRUE)) {
  stop(
    "Package 'lms' is required to lint this project. Install it with:\n",
    "  install.packages('remotes')\n",
    "  remotes::install_github('UCD-SERG/lab-manual/lms@v0.1.0')",
    call. = FALSE
  )
}
linters <- lms::default_linters()

# Exclusions are repo-specific and stay LOCAL — do not move them into lms.
exclusions <- list(
  `data-raw` = list(pipe_consistency_linter = Inf)
)
```

Install `lms` in CI with an **explicit** step in the lint workflow, before linting:

```yaml
- name: Install lms (shared linter config)
  run: |
    install.packages("remotes")
    remotes::install_github("UCD-SERG/lab-manual/lms@v0.1.0")
  shell: Rscript {0}
```

## Do NOT declare lms in DESCRIPTION

`lms` is **lint-only tooling, not a runtime dependency** — a linter configuration, not
something your package calls. Keep it out of `Imports`/`Suggests`, and do not
add a `Remotes:` entry for it. Two reasons:

1. **`{pak}` cannot resolve the subdir Remote.** The reference
   `UCD-SERG/lab-manual/lms@v0.1.0` (a package in a repo *subdirectory*) resolves with
   the `{remotes}` package but **not** with `{pak}` /
   `r-lib/actions/setup-r-dependencies`, which fail with `Can't find package called
   lms`. If `lms` is in `Suggests`, that failure breaks *every* `{pak}`-based workflow in
   the consuming repo (e.g. a bibliography/DOI check), even ones unrelated to linting.
2. **CRAN hygiene.** A linter config has no place in a package's declared dependency
   graph; lint checks should be skipped on CRAN (`testthat::skip_on_cran()`) anyway.

The version pin lives in the CI `install_github(...@<tag>)` step, not in DESCRIPTION.

## Versioning

`lms` is released as a git **tag** on `lab-manual` `main` (currently `v0.1.0`). To roll
out a rule change: merge it to `main`, cut a new tag, then bump the `@<tag>` ref in each
consuming repo's lint workflow when ready. Pinning to a tag (not `main`) means routine
edits to the lab manual never churn downstream linting.

## Developing lms

Because `default_linters()` includes `object_usage_linter()`, lint **this** package
with the source loaded so symbols (and `.onLoad()` side effects) resolve correctly:

```r
pkgload::load_all()
lintr::lint_package()
```

`.onLoad()` calls `rex::register_shortcuts()` so the `{rex}` DSL tokens used in the
snake_case regex are not flagged as undefined globals. After editing `R/` roxygen
comments, run `devtools::document()`.

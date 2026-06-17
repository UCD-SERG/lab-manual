# Shared UCD-SERG linter set, defined once in the lms package (this repo's
# lms/ subdirectory). To lint this repo locally, first install it:
#
#   R CMD INSTALL lms        # or: pak::local_install("lms")
#
# CI installs lms from the local subdir before running lintr.
linters <- lms::default_linters()

# Exclusions are repo-specific and stay LOCAL — do not move these into lms.
exclusions <- list(
  `data-raw` = list(
    pipe_consistency_linter = Inf,
    undesirable_function_linter = Inf
  ),
  vignettes = list(
    undesirable_function_linter = Inf,
    object_name_linter = Inf
  ),
  "inst/examples" = list(
    undesirable_function_linter = Inf
  ),
  "tests/testthat.R" = list(
    undesirable_function_linter = Inf
  ),
  "quarto/mermaid-diagrams.qmd" = Inf
)

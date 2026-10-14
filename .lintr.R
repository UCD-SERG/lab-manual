# Shared linter set, defined once in the lms package, which lives in the
# lms/ subdirectory of Morrison-Lab/psc (moved there from this repo in
# October 2026). To lint this repo locally, first install it:
#
#   remotes::install_github("Morrison-Lab/psc/lms@lms-v0.1.1")
#
# CI installs the same tag before running lintr.
if (!requireNamespace("lms", quietly = TRUE)) {
  stop(
    "Package 'lms' is required to lint this repo. Install it with:\n",
    "  remotes::install_github('Morrison-Lab/psc/lms@lms-v0.1.1')",
    call. = FALSE
  )
}
linters <- lms::default_linters()

# Exclusions are repo-specific and stay LOCAL; do not move these into lms.
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
  )
)

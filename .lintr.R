# Shared linter set, defined once in the lms package, which lives in the
# lms/ subdirectory of Morrison-Lab/psc (moved there from this repo in
# October 2026). To lint this repo locally, first install it:
#
#   remotes::install_github(
#     "Morrison-Lab/psc/lms@3d92ab2bb1115231ebee5ef071e2f4669b160945",
#     upgrade = "never",
#     build = FALSE
#   )
#
# CI installs the same commit this way, adding dependencies = FALSE.
if (!requireNamespace("lms", quietly = TRUE)) {
  stop(
    "Package 'lms' is required to lint this repo. Install it with:\n",
    "  remotes::install_github(\n",
    "    'Morrison-Lab/psc/lms@3d92ab2bb1115231ebee5ef071e2f4669b160945',\n",
    "    upgrade = 'never',\n",
    "    build = FALSE\n",
    "  )",
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

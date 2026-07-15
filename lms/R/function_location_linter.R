#' Function-location linter
#'
#' Flags **top-level named function definitions** in files outside the
#' allowed directories. The lab convention is that named functions belong in a
#' package's `R/` directory, one per file (see the lab manual's
#' `coding-practices/complete-package-development-workflow.qmd`), so a function
#' defined inline in a `data-raw/` script, a vignette, or `inst/` is usually
#' misplaced.
#'
#' Matches the three named-definition forms — `name <- function(...)`,
#' `name = function(...)`, and the `name <- \(...)` lambda shorthand. It does
#' **not** flag anonymous functions passed as arguments
#' (`purrr::map(x, function(z) z)`), lambdas used inline, or nested/local
#' function definitions inside another function's body — only top-level
#' definitions bound to a name.
#'
#' lintr has no built-in linter for function *location*; this complements
#' [function_length_linter()] (which flags over-long definitions wherever they
#' live). Genuine "unless absolutely necessary" exceptions use a `# nolint`
#' marker or a repo-local `.lintr.R` exclusion.
#'
#' @param allowed_dirs Character vector of directory names in which top-level
#'   function definitions are permitted. A file is exempt when any component of
#'   its path matches one of these names. Defaults to `c("R", "tests")`: `R/`
#'   is where package functions belong, and `tests/` is exempt because
#'   `helper-*.R` and setup functions there are standard testthat convention.
#' @return A [lintr::Linter()] object.
#' @export
function_location_linter <- function(allowed_dirs = c("R", "tests")) {
  xpath <- "
    /exprlist/*[
      (LEFT_ASSIGN or EQ_ASSIGN)
      and expr[SYMBOL]
      and expr[FUNCTION or OP-LAMBDA]
    ]
  "

  lintr::Linter(linter_level = "file", function(source_expression) {
    if (!lintr::is_lint_level(source_expression, "file")) {
      return(list())
    }

    path_parts <- strsplit(source_expression$filename, "/", fixed = TRUE)[[1]]
    if (any(path_parts %in% allowed_dirs)) {
      return(list())
    }

    definitions <- xml2::xml_find_all(
      source_expression$full_xml_parsed_content,
      xpath
    )

    lintr::xml_nodes_to_lints(
      definitions,
      source_expression = source_expression,
      lint_message = paste(
        "Define named functions in the package's `R/` directory (one per",
        "file), not in this file; see",
        "coding-practices/complete-package-development-workflow.qmd."
      ),
      type = "warning"
    )
  })
}

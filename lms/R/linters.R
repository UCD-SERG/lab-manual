#' Undesirable functions for UCD-SERG repositories
#'
#' The default lintr undesirable-function map, extended with the UCD-SERG
#' conventions: base and rlang messaging functions are steered toward their
#' `cli::` equivalents, `library()` is discouraged inside package code, and a
#' few of lintr's defaults (`structure()`, `browser()`) are dropped.
#'
#' Exported so a downstream repository can further `lintr::modify_defaults()`
#' it if a single repo needs to diverge, without copy-pasting the whole map.
#'
#' @return A named character vector suitable for
#'   [lintr::undesirable_function_linter()]'s `fun` argument.
#' @export
undesirable_functions <- function() {
  lintr::modify_defaults(
    defaults = lintr::default_undesirable_functions,

    # following https://github.com/r-lib/devtools/blob/2aa51ef/.lintr.R:
    # Base messaging
    "message" = "use cli::cli_inform()",
    "warning" = "use cli::cli_warn()",
    "stop" = "use cli::cli_abort()",
    # rlang messaging
    "inform" = "use cli::cli_inform()",
    "warn" = "use cli::cli_warn()",
    "abort" = "use cli::cli_abort()",
    # older cli
    "cli_alert_danger" = "use cli::cli_inform()",
    "cli_alert_info" = "use cli::cli_inform()",
    "cli_alert_success" = "use cli::cli_inform()",
    "cli_alert_warning" = "use cli::cli_inform()",

    library = paste(
      "\nuse `::`, `usethis::use_import_from()`, or `withr::local_package()`",
      "instead of modifying the global search path.",
      "\nSee:\n",
      "<https://r-pkgs.org/code.html#sec-code-r-landscape> and\n",
      "<https://r-pkgs.org/testing-design.html#sec-testing-design-self-contained>", # nolint: line_length_linter.
      "\nfor more details."
    ),

    structure = NULL,
    browser = NULL
    # see https://github.com/r-lib/lintr/pull/2227 and
    # rebuttal https://github.com/r-lib/lintr/pull/2227#issuecomment-1800302675
  )
}

#' snake_case object-name regex (uppercase acronyms allowed)
#'
#' Builds the regex used by the object-name linter so that names like
#' `snake_case_ACROs1` (uppercase acronyms, optional trailing digits) are
#' accepted. See <https://github.com/r-lib/lintr/issues/2844> for background.
#'
#' Constructed with `rex::rex()`, which evaluates its arguments in an
#' environment that registers the rex shortcuts (`start`, `upper`, `digit`,
#' `%or%`, ...), so the package does **not** need to attach rex.
#'
#' @return A single regular-expression string.
#' @noRd
snake_case_acros_regex <- function() {
  rex::rex(
    start,
    maybe("."),
    list(some_of(upper), maybe("s"), zero_or_more(digit)) %or%
      list(some_of(lower), zero_or_more(digit)),
    zero_or_more(
      "_",
      list(some_of(upper), maybe("s"), zero_or_more(digit)) %or%
        list(some_of(lower), zero_or_more(digit))
    ),
    end
  )
}

#' Default UCD-SERG lintr linters
#'
#' The canonical linter set for UCD-SERG repositories, matching the style
#' guide in the lab manual. Applied repositories consume this from a thin
#' `.lintr.R`:
#'
#' ```r
#' linters <- lms::default_linters()
#' exclusions <- list(...)   # repo-specific, stays local
#' ```
#'
#' @return A list of linters, as produced by
#'   [lintr::linters_with_defaults()].
#' @export
default_linters <- function() {
  lintr::linters_with_defaults(
    return_linter = NULL,
    trailing_whitespace_linter = NULL,
    lintr::redundant_equals_linter(),
    lintr::pipe_consistency_linter(pipe = "|>"),
    lintr::object_name_linter(
      regexes = c(snake_case_ACROs1 = snake_case_acros_regex())
    ),
    lintr::undesirable_function_linter(
      fun = undesirable_functions(),
      symbol_is_undesirable = TRUE
    )
  )
}

#' Condition-class linter for testthat expectations
#'
#' Flags `expect_error()`, `expect_warning()`, and `expect_message()` calls
#' that assert on message text (`regexp =` or positional `regexp`) without
#' also asserting on a condition `class =`.
#'
#' Matching only condition or message text is brittle:
#' wording can change while the underlying condition type stays correct.
#' Prefer asserting the class,
#' and optionally add `regexp =` for extra precision.
#'
#' @return A [lintr::Linter()] object.
#' @noRd
condition_class_linter <- function() {
  target_functions <- c("expect_error", "expect_warning", "expect_message")
  calls_xpath <- paste(
    "//SYMBOL_FUNCTION_CALL[text() = ",
    paste(sprintf("'%s'", target_functions), collapse = " or text() = "),
    "]/ancestor::expr[OP-LEFT-PAREN][1]",
    sep = ""
  )

  lintr::Linter(linter_level = "expression", function(source_expression) {
    if (!lintr::is_lint_level(source_expression, "expression")) {
      return(list())
    }

    calls <- xml2::xml_find_all(
      source_expression$xml_parsed_content,
      calls_xpath
    )
    if (!length(calls)) {
      return(list())
    }

    needs_class <- vapply(calls, function(call) {
      arg_names <- xml2::xml_text(xml2::xml_find_all(call, "./SYMBOL_SUB"))
      has_class <- "class" %in% arg_names
      has_named_regexp <- "regexp" %in% arg_names

      # The second positional argument is the third direct `expr` child:
      # function call, first argument, then unnamed `regexp`.
      positional_regexp <- xml2::xml_find_first(
        call,
        "./expr[3][preceding-sibling::*[1][self::OP-COMMA]]"
      )
      has_positional_regexp <- !inherits(positional_regexp, "xml_missing")

      !has_class && (has_named_regexp || has_positional_regexp)
    }, logical(1))

    lintr::xml_nodes_to_lints(
      calls[needs_class],
      source_expression = source_expression,
      lint_message = paste(
        "When matching a condition message in `expect_error()`,",
        "`expect_warning()`, or `expect_message()`, include a `class =`",
        "assertion instead of relying on `regexp` alone."
      ),
      type = "warning"
    )
  })
}

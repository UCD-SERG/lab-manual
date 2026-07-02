test_that("short functions produce no lint", {
  lintr::expect_no_lint(
    "f <- function(x) x + 1",
    function_length_linter()
  )
})

test_that("functions at the limit produce no lint", {
  short_body <- paste(rep("x", 5), collapse = "\n  ")
  code <- sprintf("f <- function(x) {\n  %s\n}", short_body)
  lintr::expect_no_lint(code, function_length_linter(length_limit = 10L))
})

test_that("functions over the limit are flagged", {
  long_body <- paste(rep("x", 10), collapse = "\n  ")
  code <- sprintf("f <- function(x) {\n  %s\n}", long_body)
  lintr::expect_lint(
    code,
    "Function spans more than 5 lines",
    function_length_linter(length_limit = 5L)
  )
})

test_that("lambda functions over the limit are flagged", {
  long_body <- paste(rep("x", 10), collapse = "\n  ")
  code <- sprintf("f <- \\(x) {\n  %s\n}", long_body)
  lintr::expect_lint(
    code,
    "Function spans more than 5 lines",
    function_length_linter(length_limit = 5L)
  )
})

test_that("default length_limit is 150", {
  lintr::expect_no_lint(
    "f <- function(x) x + 1",
    function_length_linter()
  )
})

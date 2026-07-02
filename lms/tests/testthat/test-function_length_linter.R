test_that("short functions produce no lint", {
  lintr::expect_no_lint(
    "f <- function(x) x + 1",
    function_length_linter()
  )
})

test_that("functions at the limit produce no lint", {
  at_limit_body <- paste(rep("x", 8), collapse = "\n  ")
  code <- sprintf("f <- function(x) {\n  %s\n}", at_limit_body)
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
  body150 <- paste(rep("x", 148), collapse = "\n  ")
  lintr::expect_no_lint(
    sprintf("f <- function(x) {\n  %s\n}", body150),
    function_length_linter()
  )

  body151 <- paste(rep("x", 149), collapse = "\n  ")
  lintr::expect_lint(
    sprintf("f <- function(x) {\n  %s\n}", body151),
    "Function spans more than 150 lines",
    function_length_linter()
  )
})

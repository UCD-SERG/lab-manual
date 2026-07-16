# Lint `text` as though it lived at `relpath` under a throwaway directory, so
# the path-based exemption can be exercised without polluting the package.
lint_as_path <- function(text, relpath, ...) {
  root <- tempfile()
  path <- file.path(root, relpath)
  dir.create(dirname(path), recursive = TRUE)
  writeLines(text, path)
  on.exit(unlink(root, recursive = TRUE), add = TRUE)
  lintr::lint(path, ...)
}

test_that("a top-level named function definition is flagged", {
  lintr::expect_lint(
    "f <- function(x) x + 1",
    "Define named functions in the package's `R/` directory",
    function_location_linter()
  )
})

test_that("the `=` and lambda definition forms are flagged", {
  lintr::expect_lint(
    "g = function(x) x",
    "Define named functions",
    function_location_linter()
  )
  lintr::expect_lint(
    "h <- \\(x) x",
    "Define named functions",
    function_location_linter()
  )
})

test_that("anonymous callbacks and lambdas are not flagged", {
  lintr::expect_no_lint(
    "purrr::map(seq_len(3), function(z) z * 2)",
    function_location_linter()
  )
  lintr::expect_no_lint(
    "purrr::map(seq_len(3), \\(z) z + 1)",
    function_location_linter()
  )
})

test_that("nested/local function definitions are not flagged", {
  code <- "res <- lapply(1:3, function(i) {\n  helper <- function() i\n  helper()\n})" # nolint: line_length_linter.
  lintr::expect_no_lint(code, function_location_linter())
})

test_that("a top-level def with a nested def is flagged exactly once", {
  code <- "outer <- function() {\n  inner <- function() 1\n  inner()\n}"
  lints <- lint_as_path(
    code,
    file.path("data-raw", "scratch.R"),
    linters = function_location_linter()
  )
  expect_length(lints, 1L)
})

test_that("definitions in R/ are exempt", {
  lints <- lint_as_path(
    "f <- function(x) x",
    file.path("R", "f.R"),
    linters = function_location_linter()
  )
  expect_length(lints, 0L)
})

test_that("definitions under tests/ are exempt", {
  lints <- lint_as_path(
    "make_fixture <- function() 1",
    file.path("tests", "testthat", "helper-fixture.R"),
    linters = function_location_linter()
  )
  expect_length(lints, 0L)
})

test_that("definitions outside allowed dirs are flagged", {
  lints <- lint_as_path(
    "build_thing <- function() 1",
    file.path("data-raw", "build.R"),
    linters = function_location_linter()
  )
  expect_length(lints, 1L)
})

test_that("allowed_dirs can be widened", {
  lints <- lint_as_path(
    "build_thing <- function() 1",
    file.path("data-raw", "build.R"),
    linters = function_location_linter(allowed_dirs = c("R", "tests", "data-raw")) # nolint: line_length_linter.
  )
  expect_length(lints, 0L)
})

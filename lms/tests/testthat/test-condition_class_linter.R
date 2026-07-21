test_that("expect_error with positional regexp and no class is flagged", {
  lintr::expect_lint(
    'expect_error(f(), "bad input")',
    "include a `class =` assertion",
    lms:::condition_class_linter()
  )
})

test_that("expect_error with named regexp and no class is flagged", {
  lintr::expect_lint(
    'expect_error(f(), regexp = "bad input")',
    "include a `class =` assertion",
    lms:::condition_class_linter()
  )
})

test_that("expect_warning with regexp and no class is flagged", {
  lintr::expect_lint(
    'expect_warning(f(), regexp = "deprecated")',
    "include a `class =` assertion",
    lms:::condition_class_linter()
  )
})

test_that("regexp with class is allowed", {
  lintr::expect_no_lint(
    'expect_error(f(), regexp = "bad input", class = "my_pkg_error")',
    lms:::condition_class_linter()
  )
})

test_that("calls that do not match on regexp are not flagged", {
  lintr::expect_no_lint("expect_error(f())", lms:::condition_class_linter())
  lintr::expect_no_lint(
    'expect_error(f(), class = "my_pkg_error")',
    lms:::condition_class_linter()
  )
})

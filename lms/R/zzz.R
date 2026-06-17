.onLoad <- function(libname, pkgname) {
  # Register rex's shortcut tokens (start, upper, digit, %or%, ...) as known
  # globals so R CMD check and lintr::object_usage_linter don't flag them
  # where snake_case_acros_regex() uses the rex DSL. See the rex vignette
  # "Using rex in a package".
  rex::register_shortcuts(pkgname)
}

# lms has moved

The `lms` linter package now lives in the `lms/` subdirectory of
[`Morrison-Lab/psc`](https://github.com/Morrison-Lab/psc/tree/main/lms),
the repository behind
[Principles of Scientific Computing](https://morrison-lab.github.io/psc/).
It moved there with its history in October 2026.

Install the version this manual lints with (lms 0.1.1),
as CI installs it (CI also passes `dependencies = FALSE`):

```r
remotes::install_github(
  "Morrison-Lab/psc/lms@3d92ab2bb1115231ebee5ef071e2f4669b160945",
  upgrade = "never",
  build = FALSE
)
```

`upgrade = "never"` leaves alone the packages that `renv::restore()` installed.
The `v0.1.0` tag on this repository still installs lms 0.1.0,
an earlier version than the 0.1.1 that moved
(`remotes::install_github("UCD-SERG/lab-manual/lms@v0.1.0")`).

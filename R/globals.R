# Global variables declaration to avoid R CMD check NOTEs
# These variables are used in ggplot2 aes() calls and other non-standard evaluation contexts

utils::globalVariables(c(
  # ggplot2 aes() variables
  "category",
  "component",
  "contrast",
  "count",
  "estimate",
  "family",
  "fitted",
  "fraction",
  "level",
  "lower",
  "observed",
  "outcome",
  "prediction",
  "probability",
  "residual",
  "root_difference",
  "upper",
  "value",
  "source",
  "bin",
  "y",
  "group",
  "term",
  "trend",
  ".cld",
  # data.table / dplyr variables
  ".",
  # R CMD check false positives
  "x",
  "yintercept"
))

# Regression tests for the `family = "auto"` path.
#
# WHY THIS FILE EXISTS: `test-workflow-contract.R` only exercised
# `agri_workflow()` with an *explicit* family. With an explicit family the
# workflow fits a single model and never reaches `agri_compare_models()`.
# The automatic path is the package default and the one users actually hit,
# so it must be covered directly.
#
# The bug these tests pin down: `agri_compare_models()` built a design
# signature with `paste(design, formula, sep = "::")`. Because `paste()`
# coerces a formula through `as.character()`, which yields one element per
# term (`"~"`, LHS, RHS), the `vapply(..., character(1))` wrapper failed with
# "values must be length 1, but FUN(X[[1]]) result is length 3". The effect
# was that `agri_workflow(family = "auto")` - the flagship entry point -
# aborted before producing any result.

test_that("agri_compare_models accepts models fitted with a formula object", {
  skip_if_not_installed("glmmTMB")
  data(agri_insects)

  des <- agri_design(agri_insects, design = "crd", treatment = "treatment")
  resp <- agri_response(agri_insects, response = "insects")

  m1 <- agri_model(data = agri_insects, response = resp, design = des,
                   family = "poisson", engine = "stats")
  m2 <- agri_model(data = agri_insects, response = resp, design = des,
                   family = "quasipoisson", engine = "stats")

  # The comparison must return a table, not abort while building signatures.
  cmp <- agri_compare_models(m1, m2)
  expect_s3_class(cmp, "agri_model_set")
  expect_true(is.data.frame(cmp$table))
  expect_equal(nrow(cmp$table), 2L)
  expect_true(all(c("model", "family", "engine", "admissible", "delta_AIC") %in%
                    names(cmp$table)))
})

test_that("agri_compare_models warns when designs differ", {
  skip_if_not_installed("glmmTMB")
  data(agri_insects)

  des_crd  <- agri_design(agri_insects, design = "crd", treatment = "treatment")
  des_rcbd <- agri_design(agri_insects, design = "rcbd",
                          treatment = "treatment", block = "block")
  resp <- agri_response(agri_insects, response = "insects")

  m_crd  <- agri_model(data = agri_insects, response = resp, design = des_crd,
                       family = "poisson", engine = "stats")
  m_rcbd <- agri_model(data = agri_insects, response = resp, design = des_rcbd,
                       family = "nbinom2")

  # Information criteria are not comparable across experimental-unit
  # structures because the design changes the likelihood itself. Changing the
  # design also changes the formula here, so both guards fire; capture every
  # warning and assert that the design guard is among them.
  w <- testthat::capture_warnings(cmp <- agri_compare_models(m_crd, m_rcbd))
  expect_true(any(grepl("different experimental designs", w, fixed = TRUE)))
  expect_s3_class(cmp, "agri_model_set")
})

test_that("agri_workflow completes with family = 'auto'", {
  skip_if_not_installed("glmmTMB")
  data(agri_insects)

  # This is the package default and the entry point documented in the README.
  w <- agri_workflow(agri_insects, response = "insects", treatment = "treatment",
                     design = "crd", family = "auto", deep_scan = FALSE)

  expect_s3_class(w, "agri_workflow")
  expect_true(all(c("design", "response", "models", "diagnostics", "anova",
                    "means", "contrasts", "trends", "predictions", "figures",
                    "report", "audit") %in% names(w)))
  expect_true(length(w$models) >= 1L)
})

test_that("agri_workflow completes with family = 'auto' under a blocked design", {
  skip_if_not_installed("glmmTMB")
  data(agri_insects)

  w <- agri_workflow(agri_insects, response = "insects", treatment = "treatment",
                     design = "rcbd", design_args = list(block = "block"),
                     family = "auto", deep_scan = FALSE)

  expect_s3_class(w, "agri_workflow")
  expect_true(length(w$models) >= 1L)

  # The declared random experimental-unit term must survive the whole
  # automatic pipeline; this is the central promise of the package.
  expect_match(paste(deparse(w$selected$formula), collapse = ""), "block")
})

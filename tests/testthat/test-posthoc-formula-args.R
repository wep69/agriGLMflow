# Regression tests for formula-argument handling in post-hoc inference.
#
# WHY THIS FILE EXISTS: `agri_cld()` and the Dunnett branch of
# `agri_contrasts()` derived the predictor name with `as.character(specs)`.
# For a formula such as `~ treatment`, `as.character()` returns one element
# per deparsed term - `c("~", "treatment")` - so:
#   * `agri_cld()` indexed the result with a length-2 vector and aborted with
#     "subscript out of bounds";
#   * the Dunnett branch read `"~"` instead of `"treatment"`, so the control
#     level could not be resolved.
# `agri_cld()` additionally fed emmeans pair labels ("A - B") straight into
# `multcompView::multcompLetters()`, which splits on "-" and keeps the
# surrounding spaces, so the letters never matched the factor levels and every
# value came back NA. The tests below pin all three behaviours.

test_that("agri_cld returns letters matched to factor levels", {
  skip_if_not_installed("emmeans")
  skip_if_not_installed("multcompView")
  skip_if_not_installed("glmmTMB")
  data(agri_insects)

  des  <- agri_design(agri_insects, design = "rcbd",
                      treatment = "treatment", block = "block")
  resp <- agri_response(agri_insects, response = "insects")
  fit  <- agri_model(data = agri_insects, response = resp,
                     design = des, family = "nbinom2")

  out <- agri_cld(fit, specs = ~ treatment)

  expect_true(".cld" %in% names(out))
  # Every level must receive a letter; NA means the label/level match failed.
  expect_false(anyNA(out$.cld))
  expect_equal(nrow(out), nlevels(agri_insects$treatment))
  expect_true(all(nzchar(out$.cld)))
})

test_that("agri_cld keeps level names that contain spaces", {
  skip_if_not_installed("emmeans")
  skip_if_not_installed("multcompView")
  data(agri_insects)

  # "AA Algae" style levels must survive the contrast-label normalisation:
  # only the " - " separator is collapsed, not the spaces inside a level.
  # A CRD is used so the stats engine is admissible (a blocked design would
  # require random experimental-unit terms that stats cannot preserve).
  dat <- agri_insects
  levels(dat$treatment) <- c("Bio A", "Bio B", "Control", "Standard")
  des  <- agri_design(dat, design = "crd", treatment = "treatment")
  resp <- agri_response(dat, response = "insects")
  fit  <- agri_model(data = dat, response = resp, design = des,
                     family = "poisson", engine = "stats")

  out <- agri_cld(fit, specs = ~ treatment)
  expect_false(anyNA(out$.cld))
  expect_setequal(as.character(out$treatment), levels(dat$treatment))
})

test_that("Dunnett contrasts resolve the declared control level", {
  skip_if_not_installed("emmeans")
  skip_if_not_installed("glmmTMB")
  data(agri_insects)

  des  <- agri_design(agri_insects, design = "rcbd",
                      treatment = "treatment", block = "block")
  resp <- agri_response(agri_insects, response = "insects")
  fit  <- agri_model(data = agri_insects, response = resp,
                     design = des, family = "nbinom2")

  ct <- agri_contrasts(fit, specs = ~ treatment, method = "dunnett",
                       control = "Control", scale = "response")

  expect_s3_class(ct, "agri_posthoc")
  expect_equal(ct$method, "dunnett")
  expect_equal(ct$control, "Control")
  # Exactly one comparison per non-control level, all against the control.
  expect_equal(nrow(ct$table), nlevels(agri_insects$treatment) - 1L)
  expect_true(all(grepl("Control", as.character(ct$table[[1L]]), fixed = TRUE)))
})

test_that("pairwise contrasts keep one row per treatment pair", {
  skip_if_not_installed("emmeans")
  skip_if_not_installed("glmmTMB")
  data(agri_insects)

  des  <- agri_design(agri_insects, design = "rcbd",
                      treatment = "treatment", block = "block")
  resp <- agri_response(agri_insects, response = "insects")
  fit  <- agri_model(data = agri_insects, response = resp,
                     design = des, family = "nbinom2")

  ct <- agri_contrasts(fit, specs = ~ treatment, method = "pairwise",
                       adjust = "tukey", scale = "response")
  k <- nlevels(agri_insects$treatment)
  expect_equal(nrow(ct$table), k * (k - 1L) / 2L)
})

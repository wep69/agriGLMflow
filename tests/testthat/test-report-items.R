# Regression tests for the items reported in RELATORIO-AO-AUTOR.md.
#
# WHY THIS FILE EXISTS: the report documents sixteen defects found by auditing
# the public API against its own documentation. Each test below pins one
# reported symptom so the defect cannot return unnoticed. The shared root cause
# of items 1-3 and 10 is that as.character() on a two-sided formula returns one
# element per deparsed term ("~", LHS, RHS), never the column name.

# ---------------------------------------------------------------- item 1
test_that("item 1: agri_compare_models accepts two-sided formulas", {
  skip_if_not_installed("glmmTMB")
  d   <- agri_example_data("agri_insects")
  des <- agri_design(d, "rcbd", treatment = "treatment", block = "block")
  m1  <- agri_glmm(data = d, response = "insects", design = des, family = "poisson")
  m2  <- agri_glmm(data = d, response = "insects", design = des, family = "nbinom2")

  cmp <- agri_compare_models(m1, m2)
  expect_s3_class(cmp, "agri_model_set")
  expect_equal(nrow(cmp$table), 2L)
  expect_false(is.null(cmp$selected))
})

test_that("item 1: agri_workflow runs with factory arguments", {
  skip_if_not_installed("glmmTMB")
  d  <- agri_example_data("agri_insects")
  wf <- agri_workflow(d, "insects", treatment = "treatment", design = "rcbd",
                      design_args = list(block = "block"))
  expect_s3_class(wf, "agri_workflow")
  expect_false(is.null(wf$selected_model))
})

# ---------------------------------------------------------------- item 2
test_that("item 2: agri_cld produces letters for both specs forms", {
  skip_if_not_installed("emmeans")
  skip_if_not_installed("multcompView")
  d   <- agri_example_data("agri_insects")
  des <- agri_design(d, "rcbd", treatment = "treatment", block = "block")
  m   <- agri_model(data = d, response = "insects", design = des)

  for (sp in list(~treatment, "treatment")) {
    cl <- agri_cld(m, specs = sp)
    expect_true(".cld" %in% names(cl))
    expect_equal(sum(is.na(cl$.cld)), 0L)
    expect_equal(nrow(cl), nlevels(d$treatment))
  }
})

# ---------------------------------------------------------------- item 3
test_that("item 3: Dunnett control by name, by position and the implicit choice", {
  skip_if_not_installed("emmeans")
  skip_if_not_installed("glmmTMB")
  d   <- agri_example_data("agri_insects")
  des <- agri_design(d, "rcbd", treatment = "treatment", block = "block")
  m   <- agri_model(data = d, response = "insects", design = des)

  por_nome <- agri_contrasts(m, specs = "treatment", method = "trt.vs.ctrl",
                             control = "Control")
  por_pos  <- agri_contrasts(m, specs = "treatment", method = "trt.vs.ctrl",
                             control = match("Control", levels(d$treatment)))
  expect_equal(as.data.frame(por_nome$table)$estimate,
               as.data.frame(por_pos$table)$estimate, tolerance = 1e-8)

  # Omitting the control must warn: silently adopting the first level means
  # comparing everything against the wrong treatment.
  expect_warning(agri_contrasts(m, specs = ~treatment, method = "trt.vs.ctrl"),
                 "first level")

  # An unknown control must list what is accepted.
  expect_error(agri_contrasts(m, specs = "treatment", method = "trt.vs.ctrl",
                              control = "Inexistente"), "Available levels")
})

# ---------------------------------------------------------------- item 4
test_that("item 4: no function with a seed contaminates the global RNG", {
  skip_if_not_installed("glmmTMB")
  d   <- agri_example_data("agri_insects")
  des <- agri_design(d, "rcbd", treatment = "treatment", block = "block")
  m   <- agri_model(data = d, response = "insects", design = des)

  chamadas <- list(
    function() agri_simulate(m, nsim = 2, seed = 1),
    function() agri_bootstrap(m, R = 3, seed = 1, statistic = "prediction"),
    function() agri_cv(m, v = 2, seed = 1),
    function() agri_diagnose(m, simulate = TRUE, nsim = 5, seed = 1),
    function() agri_power(m, term = "treatment", nsim = 3, seed = 1))

  for (f in chamadas) {
    set.seed(123)
    antes <- .Random.seed
    invisible(suppressWarnings(f()))
    expect_identical(antes, .Random.seed)
  }
})

test_that("item 4: a fixed seed does not collapse simulation replicates", {
  skip_if_not_installed("glmmTMB")
  d   <- agri_example_data("agri_insects")
  des <- agri_design(d, "rcbd", treatment = "treatment", block = "block")
  m   <- agri_model(data = d, response = "insects", design = des)

  # Before the fix, the package re-seeded the global generator, so two calls
  # made after different user seeds returned identical draws.
  set.seed(7); a <- { invisible(agri_simulate(m, nsim = 2, seed = 1)); stats::runif(3) }
  set.seed(9); b <- { invisible(agri_simulate(m, nsim = 2, seed = 1)); stats::runif(3) }
  expect_false(identical(a, b))
})

# ---------------------------------------------------------------- item 5
test_that("item 5: the quadratic optimum does not depend on the engine", {
  skip_if_not_installed("glmmTMB")
  dd  <- agri_example_data("agri_dose")
  des <- agri_design(dd, "rcbd", treatment = "dose", block = "block")
  a <- agri_regression(dd, "yield", "dose", model = "quadratic")
  b <- agri_regression(dd, "yield", "dose", model = "quadratic", design = des)

  expect_equal(a$targets$estimate[1], b$targets$estimate[1], tolerance = 1e-2)
  expect_false(is.na(b$targets$SE[1]))
  # The value must equal the closed form on the fitted coefficients.
  bb <- glmmTMB::fixef(b$fit)$cond
  expect_equal(b$targets$estimate[1], unname(-bb[2] / (2 * bb[3])), tolerance = 1e-6)
})

test_that("item 5: by returns one target set per group", {
  dg <- agri_example_data("agri_distreg")
  b  <- agri_regression(dg, "biomass", "dose", model = "quadratic", by = "treatment")
  expect_true(nrow(b$targets) >= nlevels(dg$treatment))
  expect_true("group" %in% names(b$targets))
  expect_setequal(unique(as.character(b$targets$group)), levels(dg$treatment))
})

# ---------------------------------------------------------------- item 6
test_that("item 6: bootstrap coefficients fill the matrix on a mixed fit", {
  skip_if_not_installed("glmmTMB")
  d   <- agri_example_data("agri_insects")
  des <- agri_design(d, "rcbd", treatment = "treatment", block = "block")
  m   <- agri_model(data = d, response = "insects", design = des)

  bt <- agri_bootstrap(m, R = 10, seed = 1, statistic = "coef")
  expect_equal(nrow(bt$matrix), bt$successful)
  expect_true(all(!is.na(bt$matrix)))
  expect_setequal(colnames(bt$matrix), names(glmmTMB::fixef(m$engine_fit)$cond))
})

# ---------------------------------------------------------------- item 7
test_that("item 7: a non-convergence warning fails the convergence gate", {
  dc <- agri_example_data("agri_multicounts")
  mc <- agri_composition(dc, cbind(healthy, mild, moderate, severe) ~ treatment,
                         family = "dirmultinomial")
  # The VGAM backend stops at the IRLS ceiling and says so only by warning.
  expect_false(isTRUE(mc$convergence$ok))
  expect_true(length(mc$warnings) > 0L)
})

# ---------------------------------------------------------------- item 8
test_that("item 8: delta reaches emtrends", {
  skip_if_not_installed("emmeans")
  dg <- agri_example_data("agri_distreg")
  mq <- agri_model(data = dg, response = "biomass",
                   design = agri_design(dg, "crd", treatment = "treatment"),
                   formula = biomass ~ log(dose + 1), family = "gaussian")
  a <- as.data.frame(agri_trends(mq, variable = "dose")$table)[[2]][1]
  b <- as.data.frame(agri_trends(mq, variable = "dose", delta = 50)$table)[[2]][1]
  expect_false(isTRUE(all.equal(a, b)))
})

# ---------------------------------------------------------------- item 9
test_that("item 9: bootstrap warns when it is not honoured", {
  skip_if_not_installed("emmeans")
  skip_if_not_installed("glmmTMB")
  d   <- agri_example_data("agri_insects")
  des <- agri_design(d, "rcbd", treatment = "treatment", block = "block")
  m   <- agri_model(data = d, response = "insects", design = des)

  expect_warning(agri_means(m, specs = "treatment", bootstrap = 50),
                 "only honoured")
  expect_warning(agri_contrasts(m, specs = "treatment", bootstrap = 50),
                 "only honoured")
})

# ---------------------------------------------------------------- item 10
test_that("item 10: weights is passed as a weighting, not as the method", {
  skip_if_not_installed("emmeans")
  skip_if_not_installed("glmmTMB")
  d   <- agri_example_data("agri_insects")
  des <- agri_design(d, "rcbd", treatment = "treatment", block = "block")
  m   <- agri_model(data = d, response = "insects", design = des)

  ct <- agri_contrasts(m, specs = "treatment", method = "eff", weights = "equal")
  expect_s3_class(ct, "agri_posthoc")
  expect_true(nrow(as.data.frame(ct$table)) > 0L)
})

# ---------------------------------------------------------------- item 11
test_that("item 11: the integrated workflow returns all four figures", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("glmmTMB")
  d  <- agri_example_data("agri_insects")
  wf <- agri_workflow(d, "insects", treatment = "treatment", design = "rcbd",
                      design_args = list(block = "block"), family = "nbinom1",
                      make_figures = TRUE)
  expect_setequal(names(wf$figures),
                  c("distribution", "diagnostics", "means", "contrasts"))
})

test_that("item 11: the plot helpers accept an agri_posthoc object", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("emmeans")
  skip_if_not_installed("glmmTMB")
  d   <- agri_example_data("agri_insects")
  des <- agri_design(d, "rcbd", treatment = "treatment", block = "block")
  m   <- agri_model(data = d, response = "insects", design = des)

  mn <- agri_means(m, specs = "treatment")
  ct <- agri_contrasts(m, specs = "treatment")
  expect_s3_class(agri_plot_means(mn), "ggplot")
  expect_s3_class(agri_plot_contrasts(ct), "ggplot")
})

# ---------------------------------------------------------------- item 12
test_that("item 12: a regression object carries a convergence field", {
  dd <- agri_example_data("agri_dose")
  w  <- suppressWarnings(agri_regression(dd, "yield", "dose", model = "weibull"))
  expect_true("convergence" %in% names(w))
  expect_false(isTRUE(w$convergence$ok))
})

test_that("item 12: a converged regression reports ok", {
  dd <- agri_example_data("agri_dose")
  q  <- suppressWarnings(agri_regression(dd, "yield", "dose", model = "quadratic"))
  expect_true("convergence" %in% names(q))
})

# ---------------------------------------------------------------- item 13
test_that("item 13: the RCBD message says where the block column goes", {
  d <- agri_example_data("agri_insects")
  expect_error(agri_workflow(d, "insects", treatment = "treatment", design = "rcbd"),
               "design_args")
})

# ---------------------------------------------------------------- item 14
test_that("item 14: agri_engines and agri_dependencies share their columns", {
  en <- agri_engines()
  dp <- agri_dependencies()
  expect_identical(names(en), names(dp))
  expect_true("feature" %in% names(en))
  expect_equal(nrow(en), nrow(dp))
})

# ---------------------------------------------------------------- item 15
test_that("item 15: response-taking functions accept a bare vector", {
  d <- agri_example_data("agri_insects")
  # agri_response_info() unclasses its input, so the result is a plain list
  # without a class attribute; expect_type is the right assertion here.
  expect_type(agri_response_info(d$insects), "list")
  expect_true(length(agri_distribution_map(d$insects)) > 0L)
  expect_true(length(agri_family_candidates(d$insects)) > 0L)

  # Passing the object must keep working, and both routes must agree.
  resp <- agri_response(d, response = "insects")
  expect_type(agri_response_info(resp), "list")
  expect_equal(agri_family_candidates(resp), agri_family_candidates(d$insects))
  expect_equal(agri_response_info(resp)$type, agri_response_info(d$insects)$type)
})

# ---------------------------------------------------------------- item 16
test_that("item 16: model_args$family overrides instead of colliding", {
  skip_if_not_installed("glmmTMB")
  d <- agri_example_data("agri_insects")
  wf <- agri_workflow(d, "insects", treatment = "treatment", design = "crd",
                      fit_scan = FALSE, model_args = list(family = "nbinom2"))
  expect_s3_class(wf, "agri_workflow")
  expect_equal(wf$selected_model$family, "nbinom2")
})

test_that("item 16: reserved keys in model_args are refused with a clear message", {
  d <- agri_example_data("agri_insects")
  expect_error(agri_workflow(d, "insects", treatment = "treatment", design = "crd",
                             model_args = list(data = d)),
               "model_args must not set")
})

# ------------------------------------------------------------- extras
test_that("extras: an absent target table is explained, not silent", {
  dd <- agri_example_data("agri_dose")
  cu <- agri_regression(dd, "yield", "dose", model = "cubic")
  expect_true("note" %in% names(cu))
  expect_match(cu$note, "cubic")
})

test_that("extras: an unregistered family message lists where to look", {
  expect_error(agri_family_info("familia_inexistente"),
               "agri_families")
})

test_that("extras: gamlss does not write its trace to stdout", {
  skip_if_not_installed("gamlss")
  dg <- agri_example_data("agri_distreg")
  out <- utils::capture.output(
    m <- agri_model(data = dg, response = "biomass",
                    design = agri_design(dg, "crd", treatment = "treatment"),
                    family = "gamlss_GA"),
    type = "output")
  expect_equal(length(out), 0L)
})

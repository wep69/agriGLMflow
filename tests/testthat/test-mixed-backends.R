test_that("lme4 adapter preserves a random-block Poisson model", {
  skip_if_not_installed("lme4")
  d <- agri_insects
  des <- agri_design(d, design = "rcbd", treatment = "treatment", block = "block")
  fit <- agri_model(data = d, response = "insects", design = des,
                    family = "poisson", engine = "lme4")
  expect_s3_class(fit, "agri_model")
  expect_identical(fit$engine, "lme4")
  expect_true(grepl("\\|", paste(deparse(fit$formula), collapse = "")))
})

test_that("GLMMadaptive adapter accepts one grouping factor and rejects multiple", {
  skip_if_not_installed("GLMMadaptive")
  d <- agri_insects
  fit <- agri_model(data = d, formula = insects ~ treatment + (1 | block),
                    family = "poisson", engine = "GLMMadaptive")
  expect_s3_class(fit, "agri_model")
  expect_identical(fit$engine, "GLMMadaptive")

  expect_error(
    agri_model(data = agri_splitplot,
               formula = tillers ~ irrigation * nitrogen + (1 | block) + (1 | whole_plot_id),
               family = "poisson", engine = "GLMMadaptive"),
    "exactly one random-effects term"
  )
})

test_that("hurdle count families are registered and design-compatible", {
  reg <- agri_families()
  expect_true(all(c("hurdle_poisson", "hurdle_nbinom2") %in% reg$id))
  expect_true(all(reg$hurdle[match(c("hurdle_poisson", "hurdle_nbinom2"), reg$id)]))
})

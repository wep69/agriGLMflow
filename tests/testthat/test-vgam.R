test_that("VGAM multinomial wrapper returns vglm", {
  skip_if_not_installed("VGAM")
  data(agri_multiclass)
  m <- agri_multinomial(agri_multiclass, status ~ treatment)
  expect_s4_class(m$engine_fit, "vglm")
})

test_that("VGAM composition wrapper returns vglm", {
  skip_if_not_installed("VGAM")
  .e <- new.env(parent = globalenv())
  data("agri_composition", package = "agriGLMflow", envir = .e)
  m <- agri_composition(.e$agri_composition, cbind(root,stem,leaf) ~ treatment)
  expect_s4_class(m$engine_fit, "vglm")
})


test_that("VGAM ordinal parallelism checker returns a nested comparison", {
  skip_if_not_installed("VGAM")
  data(agri_ordstage)
  m <- agri_ordinal(agri_ordstage, stage ~ treatment, model="cumulative", parallel=TRUE)
  ch <- agri_check_parallel(m)
  expect_equal(ch$status, "tested")
  expect_true(all(c("statistic", "df", "p.value") %in% names(ch$test)))
})

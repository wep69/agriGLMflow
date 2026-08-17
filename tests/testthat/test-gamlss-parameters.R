test_that("GAMLSS parameter formulas are passed explicitly", {
  data(agri_distreg)
  skip_if_not_installed("gamlss")
  skip_if_not_installed("gamlss.dist")
  z <- agri_gamlss(data = agri_distreg, formula = biomass ~ treatment + dose,
                   sigma = ~ dose, family = "gamlss_GA")
  expect_s3_class(z, "agri_model")
  expect_equal(z$engine, "gamlss")
})

test_that("GAMLSS wrapper fits a location-scale model", {
  skip_if_not_installed("gamlss")
  skip_if_not_installed("gamlss.dist")
  data(agri_distreg)
  m <- agri_gamlss(data=agri_distreg, formula=biomass ~ dose + treatment,
                   family="gamlss_GA", engine_args=list(sigma.formula=~dose))
  expect_s3_class(m$engine_fit, "gamlss")
})

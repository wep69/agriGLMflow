test_that("glmmTMB wrapper preserves coefficients", {
  skip_if_not_installed("glmmTMB")
  data(agri_insects)
  d <- agri_design(agri_insects, "rcbd", treatment="treatment", block="block")
  f <- insects ~ treatment + (1|block)
  m1 <- glmmTMB::glmmTMB(f, data=agri_insects, family=glmmTMB::nbinom2())
  m2 <- agri_model(agri_insects, response="insects", design=d,
                   formula=f, family="nbinom2", engine="glmmTMB")
  expect_equal(unname(glmmTMB::fixef(m1)$cond), unname(glmmTMB::fixef(m2$engine_fit)$cond), tolerance=1e-7)
})

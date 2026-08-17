test_that("base GLM wrapper agrees with glm", {
  data(agri_germination)
  f <- cbind(germinated, total-germinated) ~ treatment
  m1 <- glm(f, data=agri_germination, family=binomial())
  m2 <- agri_model(agri_germination, formula=f, family="binomial", engine="stats")
  expect_equal(unname(coef(m2$engine_fit)), unname(coef(m1)), tolerance=1e-10)
})

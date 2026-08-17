test_that("quadratic regression returns agronomic optimum", {
  data(agri_dose)
  r <- agri_regression(agri_dose, "yield", "dose", model="quadratic")
  expect_s3_class(r, "agri_regression")
  expect_true("x_optimum" %in% r$targets$target)
})

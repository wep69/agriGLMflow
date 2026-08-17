test_that("polynomial group curves can be compared", {
  set.seed(1)
  d <- expand.grid(group = factor(c("A", "B")), dose = seq(0, 4, length.out = 6), rep = 1:4)
  d$y <- 4 + 1.2 * d$dose - .15 * d$dose^2 + ifelse(d$group == "B", .4 * d$dose, 0) + rnorm(nrow(d), 0, .2)
  z <- agri_compare_curves(d, "y", "dose", "group", model = "quadratic")
  expect_s3_class(z, "agri_curve_comparison")
  expect_true(all(c("level_difference", "shape_difference", "overall_curve_difference") %in% names(z$tests)))
})

test_that("logistic targets include ED10 ED50 ED90", {
  set.seed(2)
  d <- data.frame(dose = seq(0, 10, length.out = 40))
  d$y <- 8 / (1 + exp((5 - d$dose) / 1.5)) + rnorm(40, 0, .08)
  z <- agri_regression(d, "y", "dose", model = "logistic")
  expect_true(all(c("ED10", "ED50", "ED90", "asymptote") %in% z$targets$target))
})

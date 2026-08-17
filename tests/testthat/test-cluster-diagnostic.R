test_that("cluster residual diagnostic detects strong grouping", {
  set.seed(1)
  g <- factor(rep(1:8, each = 5))
  r <- rep(rnorm(8, 0, 2), each = 5) + rnorm(40, 0, .2)
  z <- agriGLMflow:::.cluster_residual_diagnostic(r, g)
  expect_equal(z$status, "available")
  expect_true(is.finite(z$ICC_moment))
  expect_true(z$ICC_moment > 0.2)
})

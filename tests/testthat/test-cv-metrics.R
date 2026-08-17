test_that("multiclass CV metrics are proper probability scores", {
  y <- factor(c("A", "B", "C"), levels = c("A", "B", "C"))
  p <- matrix(c(.8,.1,.1, .1,.8,.1, .1,.2,.7), nrow = 3, byrow = TRUE,
              dimnames = list(NULL, c("A","B","C")))
  m <- agriGLMflow:::.cv_metric(y, p)
  expect_true(is.finite(m["log_loss"]))
  expect_true(is.finite(m["Brier"]))
  expect_equal(unname(m["accuracy"]), 1)
})

test_that("compositional CV metrics use cross-entropy", {
  y <- matrix(c(.2,.3,.5, .5,.2,.3), nrow = 2, byrow = TRUE)
  p <- matrix(c(.25,.25,.5, .45,.25,.3), nrow = 2, byrow = TRUE)
  m <- agriGLMflow:::.cv_metric(y, p)
  expect_true(is.finite(m["log_loss"]))
  expect_true(is.finite(m["Brier"]))
  expect_true(is.na(m["accuracy"]))
})

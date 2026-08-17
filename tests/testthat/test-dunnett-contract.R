test_that("standardized Dunnett contrasts compare each treatment with control", {
  tab <- data.frame(treatment = c("Control", "T1", "T2"), estimate = c(1, 2, 3))
  out <- agriGLMflow:::.standardized_pairwise(tab, "treatment", method = "dunnett", control = "Control")
  expect_equal(nrow(out), 2)
  expect_true(all(grepl("Control", out$contrast, fixed = TRUE)))
})

test_that("workflow exposes the complete public result contract", {
  data(agri_insects)
  skip_if_not_installed("glmmTMB")
  w <- agri_workflow(agri_insects, response = "insects", treatment = "treatment",
                     design = "rcbd", design_args = list(block = "block"),
                     family = "nbinom2", deep_scan = FALSE)
  expect_s3_class(w, "agri_workflow")
  expect_true(all(c("models", "diagnostics", "anova", "means", "contrasts", "trends",
                    "predictions", "figures", "report", "audit") %in% names(w)))
})

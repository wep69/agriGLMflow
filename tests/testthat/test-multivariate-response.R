test_that("composition and categorical-count matrices are characterized", {
  # Load datasets into isolated envs to avoid name collision with exported functions
  .e <- new.env(parent = globalenv())
  data("agri_composition", package = "agriGLMflow", envir = .e)
  data("agri_multicounts", package = "agriGLMflow", envir = .e)
  d1 <- agri_response(.e$agri_composition, response = c("root", "stem", "leaf"))
  expect_s3_class(d1, "agri_response")
  expect_equal(d1$type, "composition")
  expect_equal(length(d1$name), 3L)

  d2 <- agri_response(.e$agri_multicounts, response = c("healthy", "mild", "moderate", "severe"))
  expect_equal(d2$type, "categorical_counts")
  expect_true("vgam_dirmultinomial" %in% agri_family_candidates(d2, tier = 1L))
})

test_that("boundary compositions are not silently treated as ordinary Dirichlet", {
  x <- data.frame(a = c(0, .2), b = c(.5, .4), c = c(.5, .4))
  r <- agri_response(x, response = c("a", "b", "c"))
  expect_equal(r$type, "composition_boundary")
  expect_length(agri_family_candidates(r), 0L)
})

test_that("simple cbind formula response names are preserved", {
  f <- cbind(a, b, c) ~ x
  expect_equal(agriGLMflow:::.simple_cbind_response_names(f), c("a", "b", "c"))
  f2 <- cbind(y, n - y) ~ x
  expect_null(agriGLMflow:::.simple_cbind_response_names(f2))
})

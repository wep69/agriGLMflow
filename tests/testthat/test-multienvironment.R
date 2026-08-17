test_that("multi-environment requires environment", {
  data(agri_multienv)
  expect_error(
    agri_design(agri_multienv, "multi_environment", genotype="genotype", block="block"),
    "environment"
  )
})

test_that("multi-environment nests blocks within environment", {
  data(agri_multienv)
  d <- agri_design(agri_multienv, "multi_environment", genotype="genotype",
                   environment="environment", block="block")
  expect_true(any(grepl("environment.*block", d$random_terms)))
  expect_true(agri_validate_design(d)$valid)
})

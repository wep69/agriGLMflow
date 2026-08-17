test_that("family scan can operate without optional engines", {
  data(agri_insects)
  d <- agri_design(agri_insects, "rcbd", treatment="treatment", block="block")
  s <- agri_family_scan(agri_insects, "insects", d, fit=FALSE)
  expect_s3_class(s, "agri_family_scan")
  expect_true(all(agri_family_info(s$candidates[1])$random_effects))
})

test_that("VGAM is blocked when random effects are required", {
  data(agri_insects)
  d <- agri_design(agri_insects, "rcbd", treatment="treatment", block="block")
  expect_error(
    agri_model(agri_insects, response="insects", design=d,
               family="vgam_genpoisson1", engine="VGAM"),
    "VGAM"
  )
})

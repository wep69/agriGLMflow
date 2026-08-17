test_that("count response is identified", {
  data(agri_insects)
  r <- agri_response(agri_insects, "insects")
  expect_equal(r$type, "count")
  expect_true(r$zero_fraction >= 0)
})

test_that("closed proportions include boundary-aware families", {
  data(agri_cover)
  r <- agri_response(agri_cover, "cover")
  expect_equal(r$type, "proportion_closed")
  cands <- agri_family_candidates(r, tier=1)
  expect_true("ordbeta" %in% cands)
})

test_that("VGAM Tier 1 families are registered", {
  ids <- agri_families(tier=1, engine="VGAM")$id
  expect_true(all(c("vgam_multinomial", "vgam_cumulative", "vgam_dirichlet",
                    "vgam_dirmultinomial", "vgam_simplex", "vgam_genpoisson1",
                    "vgam_genpoisson2", "vgam_zapoisson") %in% ids))
})

test_that("expert families do not enter automatic registry", {
  sp <- agri_family_spec("VGAM", "cauchitlink", response_type="expert")
  expect_s3_class(sp, "agri_family_spec")
  expect_false(sp$id %in% agri_families()$id)
  expect_equal(agri_family_info(sp)$tier, 3L)
})

test_that("closed-proportion boundary pattern filters one-sided GAMLSS families", {
  d0 <- data.frame(y = c(0, .1, .3, .8))
  r0 <- agri_response(d0, "y")
  expect_equal(r0$boundary_pattern, "zero_only")
  c0 <- agri_family_candidates(r0, tier = 2)
  expect_true("gamlss_BEZI" %in% c0)
  expect_false("gamlss_BEOI" %in% c0)

  d1 <- data.frame(y = c(.1, .3, .8, 1))
  r1 <- agri_response(d1, "y")
  expect_equal(r1$boundary_pattern, "one_only")
  c1 <- agri_family_candidates(r1, tier = 2)
  expect_true("gamlss_BEOI" %in% c1)
  expect_false("gamlss_BEZI" %in% c1)
})

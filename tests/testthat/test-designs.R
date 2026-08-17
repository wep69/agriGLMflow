test_that("RCBD preserves random block", {
  data(agri_insects)
  d <- agri_design(agri_insects, "rcbd", treatment="treatment", block="block")
  expect_s3_class(d, "agri_design")
  expect_true(any(grepl("block", d$random_terms)))
})

test_that("split-plot includes whole-plot stratum", {
  data(agri_splitplot)
  d <- agri_design(agri_splitplot, "split_plot", block="block",
                   whole_plot_factor="irrigation", subplot_factor="nitrogen",
                   whole_plot_id="whole_plot_id")
  expect_length(d$random_terms, 2)
  expect_true(any(grepl("whole_plot_id", d$random_terms)))
})

test_that("split-split includes all experimental strata", {
  data(agri_split_split)
  d <- agri_design(agri_split_split, "split_split", block="block",
                   whole_plot_factor="irrigation", subplot_factor="nitrogen",
                   subsubplot_factor="biostimulant", whole_plot_id="whole_plot_id",
                   subplot_id="subplot_id")
  expect_length(d$random_terms, 3)
  expect_true(any(grepl("subplot_id", d$random_terms)))
})

test_that("strip-plot is not reduced to ordinary factorial RCBD", {
  data(agri_stripplot)
  d <- agri_design(agri_stripplot, "strip_plot", block="block",
                   strip_A="tillage", strip_B="cultivar",
                   strip_A_id="strip_A_id", strip_B_id="strip_B_id")
  expect_length(d$random_terms, 3)
  expect_true(any(grepl("strip_A_id", d$random_terms)))
  expect_true(any(grepl("strip_B_id", d$random_terms)))
})

test_that("repeated-measures covariance syntax is explicit", {
  data(agri_repeated)
  d <- agri_design(agri_repeated, "repeated", treatment="treatment",
                   subject="plot", time="time", block="block", covariance="ar1")
  expect_true(any(grepl("ar1", d$random_terms)))
})

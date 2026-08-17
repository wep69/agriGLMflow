agri_dose <- local({
  .had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (.had_seed) .old_seed <- get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  on.exit({
    if (.had_seed) assign(".Random.seed", .old_seed, envir = .GlobalEnv)
    else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) rm(".Random.seed", envir = .GlobalEnv)
  }, add = TRUE)
  set.seed(1007)
  agri_dose <- expand.grid(block = factor(1:5), dose = c(0, 40, 80, 120, 160, 200))
  block_eff <- stats::rnorm(5, 0, 3)[agri_dose$block]
  agri_dose$yield <- 55 + 0.34*agri_dose$dose - 0.00125*agri_dose$dose^2 + block_eff + stats::rnorm(nrow(agri_dose),0,4)
  agri_dose
})

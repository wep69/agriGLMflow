agri_disease <- local({
  .had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (.had_seed) .old_seed <- get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  on.exit({
    if (.had_seed) assign(".Random.seed", .old_seed, envir = .GlobalEnv)
    else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) rm(".Random.seed", envir = .GlobalEnv)
  }, add = TRUE)
  set.seed(1002)
  agri_disease <- expand.grid(block = factor(1:6), treatment = factor(c("Control", "T1", "T2", "T3")))
  agri_disease$total <- 30L
  eta <- c(Control = 0.5, T1 = 0.0, T2 = -0.6, T3 = -1.0)[agri_disease$treatment] + stats::rnorm(6, 0, 0.35)[agri_disease$block]
  p <- stats::plogis(eta)
  agri_disease$diseased <- stats::rbinom(nrow(agri_disease), agri_disease$total, p)
  agri_disease$healthy <- agri_disease$total - agri_disease$diseased
  agri_disease
})

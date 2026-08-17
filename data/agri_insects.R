agri_insects <- local({
  .had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (.had_seed) .old_seed <- get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  on.exit({
    if (.had_seed) assign(".Random.seed", .old_seed, envir = .GlobalEnv)
    else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) rm(".Random.seed", envir = .GlobalEnv)
  }, add = TRUE)
  set.seed(1001)
  agri_insects <- expand.grid(block = factor(1:6), treatment = factor(c("Control", "BioA", "BioB", "Standard")))
  mu <- c(Control = 12, BioA = 7, BioB = 5, Standard = 4)[agri_insects$treatment] * exp(stats::rnorm(6, 0, 0.15))[agri_insects$block]
  agri_insects$insects <- stats::rnbinom(nrow(agri_insects), mu = mu, size = 1.8)
  z <- stats::runif(nrow(agri_insects)) < 0.12
  agri_insects$insects[z] <- 0L
  agri_insects
})

agri_cover <- local({
  .had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (.had_seed) .old_seed <- get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  on.exit({
    if (.had_seed) assign(".Random.seed", .old_seed, envir = .GlobalEnv)
    else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) rm(".Random.seed", envir = .GlobalEnv)
  }, add = TRUE)
  set.seed(1004)
  agri_cover <- expand.grid(block = factor(1:6), treatment = factor(c("Control", "Mulch", "CoverCrop", "Herbicide")), rep = 1:3)
  mu <- c(Control=.58, Mulch=.23, CoverCrop=.35, Herbicide=.08)[agri_cover$treatment]
  phi <- 8
  shape1 <- pmax(mu * phi, .1); shape2 <- pmax((1-mu)*phi, .1)
  agri_cover$cover <- stats::rbeta(nrow(agri_cover), shape1, shape2)
  agri_cover$cover[sample(seq_len(nrow(agri_cover)), 5)] <- 0
  agri_cover$cover[sample(seq_len(nrow(agri_cover)), 2)] <- 1
  agri_cover
})

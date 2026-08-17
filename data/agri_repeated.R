agri_repeated <- local({
  .had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (.had_seed) .old_seed <- get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  on.exit({
    if (.had_seed) assign(".Random.seed", .old_seed, envir = .GlobalEnv)
    else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) rm(".Random.seed", envir = .GlobalEnv)
  }, add = TRUE)
  set.seed(1011)
  agri_repeated <- expand.grid(block=factor(1:5), treatment=factor(c("Control","AA","Algae")), time=factor(1:5))
  agri_repeated$plot <- interaction(agri_repeated$block, agri_repeated$treatment, drop=TRUE)
  base <- c(Control=3.0,AA=3.2,Algae=3.35)[agri_repeated$treatment]
  tm <- as.numeric(agri_repeated$time)
  re <- stats::rnorm(nlevels(agri_repeated$plot),0,.18)[agri_repeated$plot]
  agri_repeated$leaf_count <- stats::rpois(nrow(agri_repeated), exp(base + .10*tm + re))
  agri_repeated
})

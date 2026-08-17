agri_biomass <- local({
  .had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (.had_seed) .old_seed <- get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  on.exit({
    if (.had_seed) assign(".Random.seed", .old_seed, envir = .GlobalEnv)
    else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) rm(".Random.seed", envir = .GlobalEnv)
  }, add = TRUE)
  set.seed(1005)
  agri_biomass <- expand.grid(block = factor(1:6), treatment = factor(c("Control", "AA", "Algae", "AA_Algae")))
  mu <- c(Control=42, AA=51, Algae=56, AA_Algae=63)[agri_biomass$treatment]
  agri_biomass$biomass <- stats::rgamma(nrow(agri_biomass), shape = 7, scale = mu/7)
  agri_biomass
})

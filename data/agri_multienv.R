agri_multienv <- local({
  .had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (.had_seed) .old_seed <- get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  on.exit({
    if (.had_seed) assign(".Random.seed", .old_seed, envir = .GlobalEnv)
    else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) rm(".Random.seed", envir = .GlobalEnv)
  }, add = TRUE)
  set.seed(1012)
  agri_multienv <- expand.grid(environment=factor(paste0("E",1:4)), genotype=factor(paste0("G",1:5)), block=factor(1:3))
  g <- c(G1=0,G2=.15,G3=.30,G4=.22,G5=.38)[agri_multienv$genotype]
  e <- c(E1=0,E2=.25,E3=-.15,E4=.12)[agri_multienv$environment]
  ge <- stats::rnorm(20,0,.12)[interaction(agri_multienv$genotype,agri_multienv$environment)]
  agri_multienv$fruit_count <- stats::rnbinom(nrow(agri_multienv), mu=exp(2.4+g+e+ge), size=4)
  agri_multienv
})

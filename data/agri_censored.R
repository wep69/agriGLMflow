agri_censored <- local({
  .had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (.had_seed) .old_seed <- get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  on.exit({
    if (.had_seed) assign(".Random.seed", .old_seed, envir = .GlobalEnv)
    else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) rm(".Random.seed", envir = .GlobalEnv)
  }, add = TRUE)
  set.seed(1017)
  agri_censored <- expand.grid(treatment=factor(c("Control","T1","T2")), replicate=1:40)
  true <- stats::rlnorm(nrow(agri_censored), meanlog=c(Control=-1.8,T1=-1.5,T2=-1.2)[agri_censored$treatment], sdlog=.5)
  LOD <- .15
  agri_censored$concentration <- pmax(true, LOD)
  agri_censored$left_censored <- true < LOD
  agri_censored$LOD <- LOD
  agri_censored
})

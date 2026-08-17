agri_ordstage <- local({
  .had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (.had_seed) .old_seed <- get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  on.exit({
    if (.had_seed) assign(".Random.seed", .old_seed, envir = .GlobalEnv)
    else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) rm(".Random.seed", envir = .GlobalEnv)
  }, add = TRUE)
  set.seed(1016)
  agri_ordstage <- expand.grid(treatment=factor(c("Control","Bio","Standard")), replicate=1:70)
  latent <- c(Control=-.3,Bio=.35,Standard=.65)[agri_ordstage$treatment] + stats::rlogis(nrow(agri_ordstage), scale=.8)
  agri_ordstage$stage <- cut(latent,c(-Inf,-.8,0,.8,Inf),labels=c("vegetative","flowering","fruiting","maturity"),ordered_result=TRUE)
  agri_ordstage
})

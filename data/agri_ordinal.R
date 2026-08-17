agri_ordinal <- local({
  .had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (.had_seed) .old_seed <- get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  on.exit({
    if (.had_seed) assign(".Random.seed", .old_seed, envir = .GlobalEnv)
    else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) rm(".Random.seed", envir = .GlobalEnv)
  }, add = TRUE)
  set.seed(1006)
  agri_ordinal <- expand.grid(block = factor(1:8), treatment = factor(c("Control", "Low", "Medium", "High")), rep = 1:3)
  eta <- c(Control=1.2, Low=.4, Medium=-.3, High=-1.0)[agri_ordinal$treatment]
  latent <- eta + stats::rlogis(nrow(agri_ordinal))
  agri_ordinal$injury <- cut(latent, breaks=c(-Inf,-1,0,1,2,Inf), labels=c("none","slight","moderate","high","very_high"), ordered_result=TRUE)
  agri_ordinal
})

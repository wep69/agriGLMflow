agri_multiclass <- local({
  .had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (.had_seed) .old_seed <- get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  on.exit({
    if (.had_seed) assign(".Random.seed", .old_seed, envir = .GlobalEnv)
    else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) rm(".Random.seed", envir = .GlobalEnv)
  }, add = TRUE)
  set.seed(1014)
  agri_multiclass <- expand.grid(treatment=factor(c("Control","Bio","Standard")), replicate=1:80)
  prob <- list(Control=c(.45,.28,.18,.09), Bio=c(.65,.22,.09,.04), Standard=c(.76,.16,.06,.02))
  lev <- c("healthy","mild","moderate","severe")
  agri_multiclass$status <- factor(vapply(seq_len(nrow(agri_multiclass)), function(i) sample(lev,1,prob=prob[[as.character(agri_multiclass$treatment[i])]]), character(1)), levels=lev)
  agri_multiclass
})

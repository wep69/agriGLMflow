agri_multicounts <- local({
  .had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (.had_seed) .old_seed <- get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  on.exit({
    if (.had_seed) assign(".Random.seed", .old_seed, envir = .GlobalEnv)
    else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) rm(".Random.seed", envir = .GlobalEnv)
  }, add = TRUE)
  set.seed(1018)
  agri_multicounts <- expand.grid(treatment=factor(c("Control","Bio","Standard")), replicate=1:30)
  pp <- list(Control=c(.45,.28,.18,.09), Bio=c(.65,.22,.09,.04), Standard=c(.76,.16,.06,.02))
  mat <- t(vapply(seq_len(nrow(agri_multicounts)), function(i) {
    as.numeric(stats::rmultinom(1, size=30, prob=pp[[as.character(agri_multicounts$treatment[i])]]))
  }, numeric(4)))
  colnames(mat) <- c("healthy","mild","moderate","severe")
  agri_multicounts <- cbind(agri_multicounts, as.data.frame(mat))
  agri_multicounts
})

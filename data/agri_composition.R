agri_composition <- local({
  .had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (.had_seed) .old_seed <- get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  on.exit({
    if (.had_seed) assign(".Random.seed", .old_seed, envir = .GlobalEnv)
    else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) rm(".Random.seed", envir = .GlobalEnv)
  }, add = TRUE)
  set.seed(1015)
  agri_composition <- expand.grid(treatment=factor(c("Control","AA","Algae","Mix")), replicate=1:30)
  base <- rbind(Control=c(.30,.42,.28),AA=c(.27,.43,.30),Algae=c(.25,.40,.35),Mix=c(.22,.39,.39))
  raw <- t(vapply(seq_len(nrow(agri_composition)), function(i) stats::rgamma(3, shape=base[as.character(agri_composition$treatment[i]),]*40, rate=1), numeric(3)))
  raw <- raw/rowSums(raw)
  agri_composition$root <- raw[,1]; agri_composition$stem <- raw[,2]; agri_composition$leaf <- raw[,3]
  agri_composition
})

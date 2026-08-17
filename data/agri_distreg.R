agri_distreg <- local({
  .had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (.had_seed) .old_seed <- get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  on.exit({
    if (.had_seed) assign(".Random.seed", .old_seed, envir = .GlobalEnv)
    else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) rm(".Random.seed", envir = .GlobalEnv)
  }, add = TRUE)
  set.seed(1013)
  agri_distreg <- data.frame(dose=rep(seq(0,200,length.out=20),4), treatment=factor(rep(c("Control","AA","Algae","Mix"), each=20)))
  mu <- 35 + .12*agri_distreg$dose + c(Control=0,AA=4,Algae=6,Mix=9)[agri_distreg$treatment]
  sigma <- 2 + .025*agri_distreg$dose
  agri_distreg$biomass <- pmax(stats::rnorm(nrow(agri_distreg), mu, sigma), .1)
  agri_distreg
})

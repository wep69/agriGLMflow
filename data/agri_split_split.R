agri_split_split <- local({
  .had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (.had_seed) .old_seed <- get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  on.exit({
    if (.had_seed) assign(".Random.seed", .old_seed, envir = .GlobalEnv)
    else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) rm(".Random.seed", envir = .GlobalEnv)
  }, add = TRUE)
  set.seed(1009)
  agri_split_split <- expand.grid(block=factor(1:4), irrigation=factor(c("Low","High")), nitrogen=factor(c("N0","N1")), biostimulant=factor(c("Control","AA","Algae")))
  agri_split_split$whole_plot_id <- interaction(agri_split_split$block, agri_split_split$irrigation, drop=TRUE)
  agri_split_split$subplot_id <- interaction(agri_split_split$block, agri_split_split$irrigation, agri_split_split$nitrogen, drop=TRUE)
  mu <- 8 + 2*(agri_split_split$irrigation=="High") + 1.2*(agri_split_split$nitrogen=="N1") + c(Control=0,AA=1,Algae=1.5)[agri_split_split$biostimulant]
  agri_split_split$stalks <- stats::rnbinom(nrow(agri_split_split), mu=mu, size=3)
  agri_split_split
})

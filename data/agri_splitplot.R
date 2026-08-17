agri_splitplot <- local({
  .had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (.had_seed) .old_seed <- get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  on.exit({
    if (.had_seed) assign(".Random.seed", .old_seed, envir = .GlobalEnv)
    else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) rm(".Random.seed", envir = .GlobalEnv)
  }, add = TRUE)
  set.seed(1008)
  agri_splitplot <- expand.grid(block=factor(1:4), irrigation=factor(c("Low","High")), nitrogen=factor(c("N0","N1","N2")))
  agri_splitplot$whole_plot_id <- interaction(agri_splitplot$block, agri_splitplot$irrigation, drop=TRUE)
  eta <- 2.2 + .25*(agri_splitplot$irrigation=="High") + .18*as.numeric(agri_splitplot$nitrogen) + stats::rnorm(nlevels(agri_splitplot$whole_plot_id),0,.2)[agri_splitplot$whole_plot_id]
  agri_splitplot$tillers <- stats::rpois(nrow(agri_splitplot), exp(eta))
  agri_splitplot
})

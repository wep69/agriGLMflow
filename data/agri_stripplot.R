agri_stripplot <- local({
  .had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (.had_seed) .old_seed <- get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  on.exit({
    if (.had_seed) assign(".Random.seed", .old_seed, envir = .GlobalEnv)
    else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) rm(".Random.seed", envir = .GlobalEnv)
  }, add = TRUE)
  set.seed(1010)
  agri_stripplot <- expand.grid(block=factor(1:5), tillage=factor(c("NoTill","Minimum","Conventional")), cultivar=factor(c("C1","C2","C3")))
  agri_stripplot$strip_A_id <- interaction(agri_stripplot$block, agri_stripplot$tillage, drop=TRUE)
  agri_stripplot$strip_B_id <- interaction(agri_stripplot$block, agri_stripplot$cultivar, drop=TRUE)
  mu <- 45 + c(NoTill=6,Minimum=3,Conventional=0)[agri_stripplot$tillage] + c(C1=0,C2=4,C3=7)[agri_stripplot$cultivar]
  agri_stripplot$yield <- stats::rgamma(nrow(agri_stripplot), shape=12, scale=mu/12)
  agri_stripplot
})

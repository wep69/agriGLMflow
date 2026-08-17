agri_germination <- local({
  .had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (.had_seed) .old_seed <- get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  on.exit({
    if (.had_seed) assign(".Random.seed", .old_seed, envir = .GlobalEnv)
    else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) rm(".Random.seed", envir = .GlobalEnv)
  }, add = TRUE)
  set.seed(1003)
  agri_germination <- expand.grid(block = factor(1:5), treatment = factor(c("Control", "Priming", "Bio", "Chemical")))
  agri_germination$total <- 50L
  p <- c(Control = .64, Priming = .78, Bio = .73, Chemical = .84)[agri_germination$treatment]
  agri_germination$germinated <- stats::rbinom(nrow(agri_germination), 50, p)
  agri_germination
})

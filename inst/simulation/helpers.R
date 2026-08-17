`%||%` <- function(x, y) if (is.null(x)) y else x

agri_mc_summary <- function(est, truth, covered = NULL, rejected = NULL) {
  est <- est[is.finite(est)]
  out <- data.frame(
    bias = if (length(est)) mean(est - truth) else NA_real_,
    rmse = if (length(est)) sqrt(mean((est - truth)^2)) else NA_real_,
    n_success = length(est)
  )
  if (!is.null(covered)) out$coverage <- mean(covered, na.rm = TRUE)
  if (!is.null(rejected)) out$rejection_rate <- mean(rejected, na.rm = TRUE)
  out
}

agri_get_seed <- function(i, path = system.file("simulation", "seeds.csv", package = "agriGLMflow")) {
  x <- utils::read.csv(path)
  if (i > nrow(x)) stop("Seed index exceeds frozen registry.")
  x$seed[i]
}

agri_freeze_binary <- function() {
  simdir <- system.file("simulation", package = "agriGLMflow")
  seeds <- utils::read.csv(file.path(simdir, "seeds.csv"))
  scenarios <- utils::read.csv(file.path(simdir, "scenario_grid.csv"), stringsAsFactors = FALSE)
  saveRDS(seeds, file.path(simdir, "seeds.rds"))
  saveRDS(scenarios, file.path(simdir, "scenarios.rds"))
  invisible(list(seeds = seeds, scenarios = scenarios))
}

sim_rcbd <- function(blocks = 6L, trt = 4L, eta = c(2.2, .3, .15, -.1), sigma_b = .25) {
  d <- expand.grid(block = factor(seq_len(blocks)), treatment = factor(seq_len(trt)))
  b <- stats::rnorm(blocks, 0, sigma_b)
  d$eta <- eta[d$treatment] + b[d$block]
  d
}

extract_first_treatment <- function(model) {
  sm <- summary(model$engine_fit)
  cf <- try(stats::coef(sm), silent = TRUE)
  if (inherits(cf, "try-error") || is.null(dim(cf))) return(c(est = NA, se = NA, p = NA))
  hit <- grep("treatment", rownames(cf))[1L]
  if (is.na(hit)) return(c(est = NA, se = NA, p = NA))
  pcol <- grep("Pr\\(", colnames(cf))[1L]
  c(est = cf[hit,1], se = cf[hit,2], p = if (is.na(pcol)) NA else cf[hit,pcol])
}

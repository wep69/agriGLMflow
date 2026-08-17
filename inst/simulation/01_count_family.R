# Experiment A: count-family screening.
run_count_scenario <- function(scenario, seed, reps = 1000L) {
  set.seed(seed)
  out <- vector("list", reps)
  for (r in seq_len(reps)) {
    d <- sim_rcbd(blocks = as.integer(scenario$blocks), eta = c(2.2, 2.2 + scenario$effect, 2.1, 2.0))
    mu <- exp(d$eta)
    d$y <- switch(scenario$dgp,
      poisson = rpois(nrow(d), mu),
      nb1 = rnbinom(nrow(d), mu = mu, size = pmax(mu / as.numeric(scenario$dispersion), .1)),
      nb2 = rnbinom(nrow(d), mu = mu, size = pmax(as.numeric(scenario$dispersion), .1)),
      zip = {y <- rpois(nrow(d),mu); y[runif(nrow(d)) < as.numeric(scenario$zero_probability)] <- 0; y},
      zinb2 = {y <- rnbinom(nrow(d),mu=mu,size=pmax(as.numeric(scenario$dispersion),.1)); y[runif(nrow(d)) < as.numeric(scenario$zero_probability)] <- 0; y},
      hurdle_nb2 = {z <- runif(nrow(d)) < as.numeric(scenario$zero_probability); y <- rnbinom(nrow(d),mu=mu,size=pmax(as.numeric(scenario$dispersion),.1)); while(any(!z & y==0)) y[!z & y==0] <- rnbinom(sum(!z & y==0),mu=mu[!z & y==0],size=pmax(as.numeric(scenario$dispersion),.1)); y[z] <- 0; y}
    )
    des <- agriGLMflow::agri_design(d,"rcbd",treatment="treatment",block="block")
    sc <- try(agriGLMflow::agri_family_scan(d,"y",des,tier=1,fit=TRUE),silent=TRUE)
    out[[r]] <- if (inherits(sc,"try-error")) NULL else sc$table
  }
  out
}

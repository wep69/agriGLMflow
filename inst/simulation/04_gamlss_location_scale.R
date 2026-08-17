# Experiment D: location-scale regression.
run_location_scale_scenario <- function(scenario, seed, reps = 1000L) {
  set.seed(seed)
  lapply(seq_len(reps), function(r) {
    n <- as.integer(scenario$n); x <- runif(n,-1,1)
    mu <- 2 + .4*x; sigma <- exp(-.2 + as.numeric(scenario$dispersion)*x)
    data.frame(x=x,y=rnorm(n,mu,sigma),mu=mu,sigma=sigma)
  })
}

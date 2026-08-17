# Experiment F: recovery of quantitative-treatment curves and agronomic targets.
run_regression_scenario <- function(scenario, seed, reps = 1000L) {
  set.seed(seed)
  xgrid <- seq(0,200,length.out=as.integer(scenario$n))
  lapply(seq_len(reps), function(r) {
    mu <- switch(scenario$dgp,
      linear=40+.25*xgrid, quadratic=40+.45*xgrid-.0015*xgrid^2,
      mitscherlich=80-45*exp(-.02*xgrid), linear_plateau=40+.3*pmin(xgrid,120),
      logistic=85/(1+exp((90-xgrid)/25)), gompertz=85*exp(-3*exp(-.025*xgrid)))
    data.frame(dose=xgrid,y=mu+rnorm(length(mu),0,4),mu=mu)
  })
}

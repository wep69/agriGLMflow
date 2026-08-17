# Experiment C: positive continuous response families.
run_positive_scenario <- function(scenario, seed, reps = 1000L) {
  set.seed(seed)
  lapply(seq_len(reps), function(r) {
    n <- as.integer(scenario$n); x <- rep(c(0,1),length.out=n); mu <- exp(3 + scenario$effect*x)
    y <- switch(scenario$dgp,
      gaussian = rnorm(n,mu,5), gamma = rgamma(n,shape=8,scale=mu/8),
      lognormal = rlnorm(n,log(mu)-.5*.25^2,.25),
      inverse_gaussian = {if(!requireNamespace("statmod",quietly=TRUE)) return(NULL); statmod::rinvgauss(n,mean=mu,shape=20)})
    data.frame(x=x,y=y)
  })
}

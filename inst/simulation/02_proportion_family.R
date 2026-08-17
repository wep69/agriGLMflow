# Experiment B: binomial, beta-binomial and continuous proportion scenarios.
run_proportion_scenario <- function(scenario, seed, reps = 1000L) {
  set.seed(seed)
  lapply(seq_len(reps), function(r) {
    n <- as.integer(scenario$n)
    x <- factor(rep(c("Control","Treatment"), length.out=n))
    p <- plogis(-.3 + scenario$effect*(x=="Treatment"))
    if (scenario$dgp == "binomial") return(data.frame(x=x,total=20,y=rbinom(n,20,p)))
    if (scenario$dgp == "betabinomial") {
      rho <- as.numeric(scenario$dispersion); phi <- pmax(1/rho-1,2)
      pp <- rbeta(n,p*phi,(1-p)*phi); return(data.frame(x=x,total=20,y=rbinom(n,20,pp)))
    }
    phi <- 15
    y <- rbeta(n,p*phi,(1-p)*phi)
    if (scenario$dgp == "closed_proportion") {y[sample.int(n,max(1,round(.08*n)))] <- 0; y[sample.int(n,max(1,round(.04*n)))] <- 1}
    data.frame(x=x,y=y)
  })
}

# Experiment J: multinomial probability calibration with rare-category stress tests.
run_multinomial_scenario <- function(scenario, seed, reps = 1000L) {
  set.seed(seed); K <- as.integer(sub("_categories","",scenario$dgp)); n <- as.integer(scenario$n)
  lapply(seq_len(reps), function(r) {
    x <- rbinom(n,1,.5); base <- seq(.2,-.2,length.out=K); eta <- outer(x,seq_len(K),function(xx,k) base[k]+scenario$effect*xx*(k==1))
    ex <- exp(eta); pr <- ex/rowSums(ex)
    y <- factor(vapply(seq_len(n),function(i) sample(seq_len(K),1,prob=pr[i,]),integer(1)),levels=seq_len(K))
    data.frame(x=x,y=y)
  })
}

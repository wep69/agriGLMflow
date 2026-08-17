# Experiment G: family-wise error, coverage and power for Tukey, Dunnett and Holm.
# Each frozen scenario is evaluated under a global null (FWER) and a sparse
# alternative in which T2 differs from the control T1 (targeted power).

run_multiplicity_scenario <- function(scenario, seed, reps = 2000L, alpha = 0.05) {
  set.seed(seed)
  ntrt <- as.integer(scenario$dispersion); blocks <- as.integer(scenario$blocks)
  dgp <- as.character(scenario$dgp); effect <- as.numeric(scenario$effect)
  rows <- vector("list", reps * 2L * 3L); kk <- 0L
  for (condition in c("null","alternative")) for (r in seq_len(reps)) {
    d <- expand.grid(block=factor(seq_len(blocks)), treatment=factor(paste0("T",seq_len(ntrt))))
    b <- stats::rnorm(blocks,0,.25); eta <- 1 + b[d$block]
    if (condition == "alternative") eta <- eta + effect*(d$treatment=="T2")
    if (dgp == "poisson") y <- stats::rpois(nrow(d),exp(eta))
    if (dgp == "nb2") y <- stats::rnbinom(nrow(d),mu=exp(eta),size=1.2)
    if (dgp == "binomial") y <- stats::rbinom(nrow(d),1,stats::plogis(eta-1))
    if (dgp == "gamma") y <- stats::rgamma(nrow(d),shape=6,scale=exp(eta)/6)
    d$y <- y
    des <- agriGLMflow::agri_design(d,"rcbd",treatment="treatment",block="block")
    fam <- switch(dgp,poisson="poisson",nb2="nbinom2",binomial="binomial",gamma="Gamma")
    fit <- try(agriGLMflow::agri_model(d,response="y",design=des,family=fam),silent=TRUE)
    for (method in c("tukey","dunnett","holm")) {
      kk <- kk + 1L
      if (inherits(fit,"try-error") || !requireNamespace("emmeans",quietly=TRUE)) {
        rows[[kk]] <- data.frame(rep=r,condition=condition,method=method,success=FALSE,any_reject=NA,target_reject=NA)
        next
      }
      ct <- try(if(method=="dunnett") {
        agriGLMflow::agri_contrasts(fit,"treatment",method="dunnett",control="T1")
      } else {
        agriGLMflow::agri_contrasts(fit,"treatment",method="pairwise",adjust=method)
      },silent=TRUE)
      if(inherits(ct,"try-error")) {
        rows[[kk]] <- data.frame(rep=r,condition=condition,method=method,success=FALSE,any_reject=NA,target_reject=NA)
        next
      }
      tab <- ct$table; pcol <- if("p.value" %in% names(tab)) "p.value" else grep("p",names(tab),value=TRUE)[1L]
      pv <- if(length(pcol) && !is.na(pcol)) tab[[pcol]] else rep(NA_real_,nrow(tab))
      target <- grepl("T2",tab$contrast,fixed=TRUE) & grepl("T1",tab$contrast,fixed=TRUE)
      rows[[kk]] <- data.frame(rep=r,condition=condition,method=method,success=TRUE,
                               any_reject=any(pv<alpha,na.rm=TRUE),
                               target_reject=if(any(target)) any(pv[target]<alpha,na.rm=TRUE) else NA)
    }
  }
  do.call(rbind,rows[seq_len(kk)])
}

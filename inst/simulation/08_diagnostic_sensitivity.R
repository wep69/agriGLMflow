# Experiment H: sensitivity/specificity of diagnostic warnings under injected faults.

run_diagnostic_scenario <- function(scenario, seed, reps = 1000L) {
  set.seed(seed); fault <- as.character(scenario$dgp); n <- as.integer(scenario$n)
  rows <- vector("list", reps)
  for (r in seq_len(reps)) {
    x <- factor(rep(c("C","T"), length.out=n))
    fit <- dg <- NULL
    if (fault %in% c("overdispersion","underdispersion","zero_inflation","omitted_random")) {
      mu <- exp(1 + .25*(x=="T"))
      if (fault == "overdispersion") y <- stats::rnbinom(n,mu=mu,size=.5)
      if (fault == "underdispersion") y <- stats::rbinom(n,size=4,prob=pmin(.9,mu/4))
      if (fault == "zero_inflation") {y <- stats::rpois(n,mu); y[stats::runif(n)<.35] <- 0}
      if (fault == "omitted_random") {
        block <- factor(rep(seq_len(max(4,as.integer(scenario$blocks))),length.out=n))
        mu <- exp(1 + .25*(x=="T") + rep(stats::rnorm(nlevels(block),0,.8),length.out=n))
        y <- stats::rpois(n,mu)
      }
      d <- data.frame(y=y,treatment=x)
      if (fault=="omitted_random") d$block <- block
      fit <- try(agriGLMflow::agri_model(d,formula=y~treatment,family="poisson",engine="stats"),silent=TRUE)
      if (!inherits(fit,"try-error")) dg <- agriGLMflow::agri_diagnose(fit,simulate=FALSE,cluster=if (fault=="omitted_random") "block" else NULL)
    } else if (fault == "wrong_family") {
      d <- data.frame(y=stats::rgamma(n,shape=.7,scale=8),treatment=x)
      fit <- try(agriGLMflow::agri_model(d,formula=y~treatment,family="gaussian",engine="stats"),silent=TRUE)
      if (!inherits(fit,"try-error")) dg <- agriGLMflow::agri_diagnose(fit)
    } else if (fault == "ar1") {
      e <- numeric(n); e[1] <- stats::rnorm(1)
      for (i in 2:n) e[i] <- .75*e[i-1]+stats::rnorm(1,0,sqrt(1-.75^2))
      d <- data.frame(y=.3*(x=="T")+e,treatment=x,time=seq_len(n))
      fit <- try(agriGLMflow::agri_model(d,formula=y~treatment,family="gaussian",engine="stats"),silent=TRUE)
      if (!inherits(fit,"try-error")) dg <- agriGLMflow::agri_diagnose(fit,time="time")
    } else if (fault == "outlier") {
      d <- data.frame(y=stats::rnorm(n,.3*(x=="T"),1),treatment=x); d$y[1] <- d$y[1]+12
      fit <- try(agriGLMflow::agri_model(d,formula=y~treatment,family="gaussian",engine="stats"),silent=TRUE)
      if (!inherits(fit,"try-error")) dg <- agriGLMflow::agri_diagnose(fit)
    }
    detected <- if (is.null(dg)) NA else switch(fault,
      overdispersion=identical(dg$dispersion$status,"possible_overdispersion"),
      underdispersion=identical(dg$dispersion$status,"possible_underdispersion"),
      zero_inflation=grepl("more_zeros",dg$zeros$status),
      omitted_random=identical(dg$dependence$cluster$status,"available") && is.finite(dg$dependence$cluster$p.value) && dg$dependence$cluster$p.value<.05,
      wrong_family=identical(dg$residuals$shape_status,"review_shape"),
      ar1=identical(dg$dependence$temporal$status,"available") && is.finite(dg$dependence$temporal$lag1) && abs(dg$dependence$temporal$lag1)>dg$dependence$temporal$approximate_95_bound,
      outlier=length(dg$influence$flagged %||% integer())>0,
      NA)
    rows[[r]] <- data.frame(rep=r,fault=fault,fit_success=!inherits(fit,"try-error"),detected=detected)
  }
  do.call(rbind,rows)
}

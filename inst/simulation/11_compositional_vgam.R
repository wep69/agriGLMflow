# Experiment K: Dirichlet and Dirichlet-multinomial calibration.
run_composition_scenario <- function(scenario, seed, reps = 1000L) {
  set.seed(seed); n <- as.integer(scenario$n); dgp <- as.character(scenario$dgp)
  rows <- vector("list", reps)
  for (r in seq_len(reps)) {
    x <- stats::rbinom(n,1,.5); center <- cbind(.3-.05*x,.4,.3+.05*x); concentration <- as.numeric(scenario$dispersion)
    raw <- t(vapply(seq_len(n),function(i) stats::rgamma(3,shape=pmax(center[i,]*concentration,.1)),numeric(3)))
    comp <- raw/rowSums(raw)
    if (dgp == "dirichlet_multinomial") {
      total <- 30L
      cnt <- t(vapply(seq_len(n),function(i) stats::rmultinom(1,total,comp[i,])[,1],integer(3)))
      d <- data.frame(x=factor(x),c1=cnt[,1],c2=cnt[,2],c3=cnt[,3])
      fit <- try(agriGLMflow::agri_composition(d,cbind(c1,c2,c3)~x,family="dirmultinomial"),silent=TRUE)
      yy <- as.matrix(d[c("c1","c2","c3")])
    } else {
      d <- data.frame(x=factor(x),c1=comp[,1],c2=comp[,2],c3=comp[,3])
      fit <- try(agriGLMflow::agri_composition(d,cbind(c1,c2,c3)~x,family="dirichlet"),silent=TRUE)
      yy <- as.matrix(d[c("c1","c2","c3")])
    }
    if(inherits(fit,"try-error")) {rows[[r]]<-data.frame(rep=r,success=FALSE,log_loss=NA,Brier=NA); next}
    pr <- try(agriGLMflow::agri_predict(fit,type="response"),silent=TRUE)
    met <- if(inherits(pr,"try-error")) c(log_loss=NA,Brier=NA) else agriGLMflow:::.cv_metric(yy,pr)
    rows[[r]] <- data.frame(rep=r,success=TRUE,log_loss=met["log_loss"],Brier=met["Brier"])
  }
  do.call(rbind,rows)
}

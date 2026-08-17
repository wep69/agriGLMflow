# Experiment I: proportional, partial-proportional, non-proportional and continuation-ratio ordinal DGPs.

.ordinal_draw_cumulative <- function(x, beta, thresholds=c(-1.4,-.4,.5,1.4)) {
  n <- length(x); K <- length(thresholds)+1L
  B <- if (length(beta)==1L) rep(beta,length(thresholds)) else beta
  cp <- vapply(seq_along(thresholds),function(j) stats::plogis(thresholds[j]-B[j]*x),numeric(n))
  cp <- t(apply(cp,1,cummax)); cp <- pmin(.999999,pmax(.000001,cp))
  pr <- cbind(cp[,1], cp[,2]-cp[,1], cp[,3]-cp[,2], cp[,4]-cp[,3], 1-cp[,4])
  apply(pr,1,function(p) sample.int(K,1,prob=p))
}

.ordinal_draw_continuation <- function(x,beta=.5,alpha=c(.7,.3,-.2,-.8)) {
  n<-length(x); K<-length(alpha)+1L; out<-integer(n)
  for(i in seq_len(n)) {
    remaining<-1; pr<-numeric(K)
    for(j in seq_along(alpha)) {q<-stats::plogis(alpha[j]-beta*x[i]); pr[j]<-remaining*q; remaining<-remaining*(1-q)}
    pr[K]<-remaining; out[i]<-sample.int(K,1,prob=pr)
  }
  out
}

run_ordinal_scenario <- function(scenario, seed, reps = 1000L) {
  set.seed(seed); n<-as.integer(scenario$n); dgp<-as.character(scenario$dgp); eff<-as.numeric(scenario$effect)
  rows<-vector("list",reps)
  for(r in seq_len(reps)) {
    x<-stats::rbinom(n,1,.5)
    yi<-switch(dgp,
      proportional_odds=.ordinal_draw_cumulative(x,eff),
      partial_proportional=.ordinal_draw_cumulative(x,c(eff,eff,.15,.15)),
      nonproportional=.ordinal_draw_cumulative(x,c(.1,.3,.5,.7)),
      continuation=.ordinal_draw_continuation(x,eff))
    d<-data.frame(x=factor(x),y=ordered(yi,levels=1:5))
    fit<-try(if(dgp=="continuation") agriGLMflow::agri_ordinal(d,y~x,model="continuation") else if(dgp=="partial_proportional") agriGLMflow::agri_ordinal(d,y~x,model="partial_proportional",parallel=TRUE ~ -1 + x) else agriGLMflow::agri_ordinal(d,y~x,model="cumulative",parallel=(dgp=="proportional_odds")),silent=TRUE)
    if(inherits(fit,"try-error")) {rows[[r]]<-data.frame(rep=r,success=FALSE,log_loss=NA,Brier=NA); next}
    pr<-try(agriGLMflow::agri_predict(fit,newdata=transform(d,y=NULL),type="response"),silent=TRUE)
    met<-if(inherits(pr,"try-error")) c(log_loss=NA,Brier=NA) else agriGLMflow:::.cv_metric(d$y,pr)
    rows[[r]]<-data.frame(rep=r,success=TRUE,log_loss=met["log_loss"],Brier=met["Brier"])
  }
  do.call(rbind,rows)
}

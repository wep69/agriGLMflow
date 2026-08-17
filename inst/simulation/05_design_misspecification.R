# Experiment E: correct versus misspecified experimental-unit structures.
# The agriGLMflow branch always preserves the declared design. The simplified
# comparator is deliberately wrong and exists only to quantify the inferential
# consequences of ignoring experimental strata.

.sim_re <- function(f, sd) {
  lev <- levels(factor(f))
  z <- stats::rnorm(length(lev), 0, sd); names(z) <- lev
  unname(z[as.character(factor(f, levels = lev))])
}

.sim_design_case <- function(kind, effect = 0.4, blocks = 4L) {
  if (kind == "rcbd") {
    d <- expand.grid(block = factor(seq_len(blocks)), treatment = factor(c("C","T")))
    d$eta <- effect * (d$treatment == "T") + .sim_re(d$block, .8)
    d$y <- d$eta + stats::rnorm(nrow(d))
    des <- agriGLMflow::agri_design(d, "rcbd", treatment = "treatment", block = "block")
    return(list(data=d, design=des, focal="treatment", truth=effect, miss=y ~ treatment))
  }
  if (kind == "split_plot") {
    d <- expand.grid(block=factor(seq_len(blocks)), A=factor(c("C","T")), B=factor(1:3))
    d$whole_id <- interaction(d$block,d$A,drop=TRUE)
    d$eta <- effect*(d$A=="T") + .sim_re(d$block,.5) + .sim_re(d$whole_id,.8)
    d$y <- d$eta + stats::rnorm(nrow(d))
    des <- agriGLMflow::agri_design(d,"split_plot",block="block",whole_plot_factor="A",subplot_factor="B",whole_plot_id="whole_id")
    return(list(data=d,design=des,focal="A",truth=effect,miss=y ~ A * B))
  }
  if (kind == "split_split") {
    d <- expand.grid(block=factor(seq_len(blocks)), A=factor(c("C","T")), B=factor(1:2), C=factor(1:2))
    d$whole_id <- interaction(d$block,d$A,drop=TRUE)
    d$subplot_id <- interaction(d$block,d$A,d$B,drop=TRUE)
    d$eta <- effect*(d$A=="T") + .sim_re(d$block,.4) + .sim_re(d$whole_id,.8) + .sim_re(d$subplot_id,.5)
    d$y <- d$eta + stats::rnorm(nrow(d))
    des <- agriGLMflow::agri_design(d,"split_split",block="block",whole_plot_factor="A",subplot_factor="B",subsubplot_factor="C",whole_plot_id="whole_id",subplot_id="subplot_id")
    return(list(data=d,design=des,focal="A",truth=effect,miss=y ~ A * B * C))
  }
  if (kind == "strip_plot") {
    d <- expand.grid(block=factor(seq_len(blocks)), A=factor(c("C","T","A3")), B=factor(1:3))
    d$stripA_id <- interaction(d$block,d$A,drop=TRUE)
    d$stripB_id <- interaction(d$block,d$B,drop=TRUE)
    d$eta <- effect*(d$A=="T") + .sim_re(d$block,.4) + .sim_re(d$stripA_id,.7) + .sim_re(d$stripB_id,.7)
    d$y <- d$eta + stats::rnorm(nrow(d))
    des <- agriGLMflow::agri_design(d,"strip_plot",block="block",strip_A="A",strip_B="B",strip_A_id="stripA_id",strip_B_id="stripB_id")
    return(list(data=d,design=des,focal="A",truth=effect,miss=y ~ A * B))
  }
  if (kind == "repeated") {
    d <- expand.grid(block=factor(seq_len(blocks)), treatment=factor(c("C","T")), time=factor(1:4))
    d$subject <- interaction(d$block,d$treatment,drop=TRUE)
    u <- .sim_re(d$subject,.9)
    d$eta <- effect*(d$treatment=="T") + .15*(as.integer(d$time)-1) + u
    d$y <- d$eta + stats::rnorm(nrow(d),0,.7)
    des <- agriGLMflow::agri_design(d,"repeated",treatment="treatment",block="block",subject="subject",time="time",covariance="independence")
    return(list(data=d,design=des,focal="treatment",truth=effect,miss=y ~ treatment * time))
  }
  if (kind == "multi_environment") {
    d <- expand.grid(environment=factor(1:3), block=factor(seq_len(blocks)), genotype=factor(c("G1","G2","G3","G4")))
    d$env_block <- interaction(d$environment,d$block,drop=TRUE)
    d$eta <- effect*(d$genotype=="G2") + .sim_re(d$environment,.8) + .sim_re(d$env_block,.5)
    d$y <- d$eta + stats::rnorm(nrow(d))
    des <- agriGLMflow::agri_design(d,"multi_environment",genotype="genotype",environment="environment",replication="block",genotype_effect="fixed",environment_effect="random",interaction_effect="random")
    return(list(data=d,design=des,focal="genotype",truth=effect,miss=y ~ genotype))
  }
  stop("Unknown design scenario: ", kind)
}

.extract_effect <- function(tab, focal, truth) {
  if (is.null(tab) || !is.matrix(tab)) return(c(est=NA,se=NA,p=NA,covered=NA))
  hit <- grep(focal, rownames(tab), fixed=TRUE)[1L]
  if (is.na(hit)) return(c(est=NA,se=NA,p=NA,covered=NA))
  est <- tab[hit,1L]; se <- tab[hit,2L]
  pcol <- grep("Pr\\(", colnames(tab))[1L]
  p <- if (is.na(pcol)) NA_real_ else tab[hit,pcol]
  c(est=est,se=se,p=p,covered=if (is.finite(se)) abs(est-truth) <= 1.96*se else NA)
}

run_design_scenario <- function(scenario, seed, reps = 2000L) {
  set.seed(seed)
  out <- vector("list", reps)
  for (r in seq_len(reps)) {
    z <- .sim_design_case(as.character(scenario$dgp), effect=as.numeric(scenario$effect), blocks=as.integer(scenario$blocks))
    good <- try(agriGLMflow::agri_model(z$data,response="y",design=z$design,family="gaussian"),silent=TRUE)
    bad <- try(stats::lm(z$miss,data=z$data),silent=TRUE)
    cg <- if (inherits(good,"try-error")) c(est=NA,se=NA,p=NA,covered=NA) else .extract_effect(agriGLMflow:::.agri_coef_table(good),z$focal,z$truth)
    cb <- if (inherits(bad,"try-error")) c(est=NA,se=NA,p=NA,covered=NA) else .extract_effect(as.matrix(stats::coef(summary(bad))),z$focal,z$truth)
    out[[r]] <- data.frame(rep=r,correct_est=cg["est"],correct_se=cg["se"],correct_p=cg["p"],correct_covered=cg["covered"],
                           miss_est=cb["est"],miss_se=cb["se"],miss_p=cb["p"],miss_covered=cb["covered"])
  }
  do.call(rbind,out)
}

# Experiment L: backend agreement after explicit parameterization harmonization.
# Never compare coefficients from identically named distributions until mean/dispersion/
# zero-process parameterizations have been mapped to a common estimand.
backend_harmonization_targets <- data.frame(
  comparison=c("VGAM NB vs glmmTMB NB","VGAM beta-binomial vs glmmTMB beta-binomial","VGAM ZINB vs glmmTMB ZINB"),
  common_estimand=c("mean and variance at fixed covariates","mean probability and intraclass/dispersion measure","overall mean, structural-zero probability, parent-count variance"),
  stringsAsFactors=FALSE
)

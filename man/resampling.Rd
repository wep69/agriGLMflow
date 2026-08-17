\name{agri_simulate}
\alias{agri_simulate}
\alias{agri_bootstrap}
\alias{agri_cv}
\alias{agri_power}
\title{Simulation, bootstrap, design-aware cross-validation and power}
\usage{
agri_simulate(object, nsim = 1L, seed = NULL, ...)
agri_bootstrap(object, R = 500L, unit = NULL, type = c("cluster", "parametric"), seed = 123, statistic = c("coef", "prediction"), newdata = NULL, ...)
agri_cv(object, v = 5L, unit = NULL, scheme = c("grouped_kfold", "leave_one_environment_out"), seed = 123, ...)
agri_power(object, term, nsim = 500L, alpha = 0.05, seed = 123, ...)
}
\description{Resampling and simulation utilities that preserve experimental units and avoid random observation-level leakage when clustered validation is required. Cluster bootstrap replicates are relabelled as distinct resampled units. Leave-one-environment-out validation requires environment to be modelled as random because a fixed unseen environment level cannot be extrapolated. Cross-validation reports RMSE and MAE for numeric responses, adds log-loss, Brier score and accuracy for categorical probability predictions, and uses cross-entropy/Brier summaries for compositional or multivariate-count probability matrices.}
\arguments{
  \item{object}{An object of class \code{agri_model}.}
  \item{nsim}{An integer specifying the number of simulations.}
  \item{seed}{An integer specifying the random seed for reproducibility.}
  \item{R}{An integer specifying the number of bootstrap replicates.}
  \item{unit}{An optional character string specifying the unit for cluster bootstrap.}
  \item{type}{A character string specifying the bootstrap type ("cluster" or "parametric").}
  \item{statistic}{A character string specifying the statistic to bootstrap ("coef" or "prediction").}
  \item{newdata}{An optional data frame for predictions.}
  \item{v}{An integer specifying the number of cross-validation folds.}
  \item{scheme}{A character string specifying the cross-validation scheme.}
  \item{term}{A character string specifying the term for power analysis.}
  \item{alpha}{A numeric value specifying the significance level.}
  \item{...}{Additional arguments passed to methods.}
}

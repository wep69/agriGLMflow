\name{agri_diagnose}
\alias{agri_diagnose}
\alias{agri_check_convergence}
\alias{agri_check_dispersion}
\alias{agri_check_zeros}
\alias{agri_check_residuals}
\alias{agri_check_random}
\alias{agri_check_influence}
\alias{agri_check_dependence}
\title{Unified diagnostics for generalized agricultural models}
\usage{
agri_diagnose(object, simulate = FALSE, nsim = 250L, time = NULL, cluster = NULL, seed = 123, ...)
agri_check_convergence(object, ...)
agri_check_dispersion(object, ...)
agri_check_zeros(object, ...)
agri_check_residuals(object, ...)
agri_check_random(object, ...)
agri_check_influence(object, ...)
agri_check_dependence(object, ...)
}
\description{Checks convergence, residual dispersion, zeros, random-effect boundaries, influence and dependence, with optional simulation-based diagnostics.}
\details{Excess zeros and overdispersion are evaluated as distinct phenomena. DHARMa is used when requested, installed and supported by the fitted model. VGAM and GAMLSS retain engine-specific diagnostic information.}
\arguments{
  \item{object}{An object of class \code{agri_model}.}
  \item{simulate}{Logical; if \code{TRUE}, use simulation-based diagnostics.}
  \item{nsim}{An integer specifying the number of simulations.}
  \item{time}{An optional character string specifying the time variable for repeated measures.}
  \item{cluster}{An optional character string specifying the cluster variable.}
  \item{seed}{An integer specifying the random seed for reproducibility.}
  \item{...}{Additional arguments passed to methods.}
}

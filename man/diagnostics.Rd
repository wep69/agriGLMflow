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
\value{
An object of class \code{agri_diagnostics}, a list with the following
components:

\item{overall}{Character status of the whole diagnostic set: \code{"acceptable"},
\code{"review"} or \code{"problem"}. This is the component to report; it is
\emph{not} named \code{status}.}
\item{convergence}{List with \code{status} (\code{"acceptable"} or
\code{"problem"}) and engine-specific \code{details}.}
\item{dispersion}{List with \code{status} (\code{"acceptable"},
\code{"possible_overdispersion"}, \code{"possible_underdispersion"} or
\code{"not_available"}), \code{ratio} (Pearson dispersion) and
\code{pearson_residuals}.}
\item{zeros}{List with \code{status}, \code{observed_fraction},
\code{expected_fraction} and the simulated \code{simulated_interval} when
available.}
\item{residuals}{List with \code{pearson}, \code{skewness},
\code{excess_kurtosis} and \code{shape_status}.}
\item{random}{Random-effect variance components and near-boundary flags, or
\code{status = "not_applicable"} when the model has no random effects.}
\item{influence}{Influence measures and flagged observations, or
\code{status = "not_available"}.}
\item{dependence}{List with \code{temporal} (autocorrelation) and
\code{cluster} (intra-class correlation) sub-diagnostics.}
\item{DHARMa}{Simulated quantile residual diagnostics when \code{simulate = TRUE}
and the backend is supported; otherwise \code{NULL}.}
\item{VGAM, GAMLSS}{Engine-specific residual information, or \code{NULL}.}
\item{messages}{Character vector of human-readable notes explaining any
non-acceptable component.}
\item{model}{The fitted \code{agri_model} object.}

The extractor functions \code{agri_check_*} return the corresponding single
component.
}

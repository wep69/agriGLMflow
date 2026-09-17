\name{agri_model}
\alias{agri_model}
\alias{agri_glm}
\alias{agri_glmm}
\alias{agri_gamlss}
\alias{agri_vglm}
\alias{agri_multinomial}
\alias{agri_composition}
\alias{agri_censored}
\alias{agri_ordinal}
\alias{agri_check_parallel}
\alias{agri_refit}
\alias{agri_sensitivity}
\title{Fit generalized, mixed, distributional, vector and ordinal models}
\usage{
agri_model(data = NULL, response = NULL, denominator = NULL, design = NULL,
  formula = NULL, family = "auto", engine = "auto", link = NULL,
  ziformula = NULL, dispformula = NULL, family_args = list(),
  engine_args = list(), additive = FALSE, ...)
agri_glm(..., family = "gaussian", engine = "stats")
agri_glmm(..., family = "nbinom2", engine = "glmmTMB")
agri_gamlss(..., family = "gamlss_GA", sigma = NULL,
  nu = NULL, tau = NULL, engine_args = list())
agri_vglm(..., family, additive = FALSE)
agri_multinomial(data, formula, ref_level = NULL,
  parallel = FALSE, additive = FALSE, engine_args = list())
agri_composition(data, formula,
  family = c("dirichlet", "dirmultinomial"),
  additive = FALSE, family_args = list(),
  engine_args = list())
agri_censored(data, formula,
  family = c("normal", "poisson"),
  family_args = list(), engine_args = list())
agri_check_parallel(object, refit_nonparallel = TRUE)
agri_ordinal(data, formula, design = NULL,
  model = c("auto", "cumulative", "partial_proportional",
    "adjacent", "continuation", "stopping"),
  link = "logit", parallel = NULL, family_args = list(), ...)
agri_refit(object, family = object$family_spec \%||\% object$family,
  engine = "auto", formula = object$formula, data = object$data, ...)
agri_sensitivity(object, families = NULL, deep = FALSE, ...)
}
\description{Unified model-fitting interface that routes a design-compatible statistical problem to a registered engine.}
\details{VGAM requests are rejected when random effects are
required. lme4 supports the conventional mixed-model subset
without changing family definitions. GLMMadaptive is restricted
to models that can be represented with one grouping factor in
this workflow. For GAMLSS, \code{sigma}, \code{nu} and \code{tau}
accept parameter-specific formulas directly; additional backend
settings remain available through \code{engine_args}. For VGAM
multi-parameter families, family-specific constraints and options
are passed explicitly through \code{family_args}. The original
backend fit is retained in \code{engine_fit}. The backend call is
wrapped in a warning collector: the messages the backend emits are
captured in \code{warnings} and inspected by the convergence gate, so
a fit that stopped early through a warning is not reported as
converged, and a failure is recorded in the audit trail rather than
passing silently.}
\arguments{
  \item{data}{A data frame containing the response and predictor variables.}
  \item{response}{A character string or expression specifying the response column name.}
  \item{denominator}{Optional character string or expression specifying the denominator column for binomial responses.}
  \item{design}{An agri_design object or character string specifying the experimental design.}
  \item{formula}{A formula specifying the model.}
  \item{family}{A character string or family object specifying the distribution family.}
  \item{engine}{A character string specifying the statistical engine.}
  \item{link}{A character string specifying the link function.}
  \item{ziformula}{A formula for the zero-inflation component.}
  \item{dispformula}{A formula for the dispersion component.}
  \item{family_args}{A list of additional arguments passed to the family constructor.}
  \item{engine_args}{A list of additional arguments passed to the engine.}
  \item{additive}{Logical; if \code{TRUE}, use additive model formulation.}
  \item{object}{An object of class \code{agri_model}.}
  \item{refit_nonparallel}{Logical; if \code{TRUE}, refit non-parallel model.}
  \item{ref_level}{Reference level for multinomial model.}
  \item{parallel}{Logical; if \code{TRUE}, fit parallel model.}
  \item{sigma}{Formula for the sigma parameter in GAMLSS.}
  \item{nu}{Formula for the nu parameter in GAMLSS.}
  \item{tau}{Formula for the tau parameter in GAMLSS.}
  \item{model}{Character string specifying the ordinal model type.}
  \item{families}{A character vector of family names for sensitivity analysis.}
  \item{deep}{Logical; if \code{TRUE}, perform deep sensitivity analysis.}
  \item{...}{Additional arguments passed to methods.}
}
\value{
The fitting functions in this topic return a list of class
\code{agri_model} with components:
\describe{
  \item{\code{call}}{The matched call.}
  \item{\code{data}}{The data frame used for fitting.}
  \item{\code{design}}{The \code{agri_design} object used.}
  \item{\code{response}}{The \code{agri_response} object used.}
  \item{\code{formula}}{The fitted model formula.}
  \item{\code{family}}{Character string naming the fitted family.}
  \item{\code{family_spec}}{Expert family specification, or \code{NULL}.}
  \item{\code{family_info}}{One-row data frame of family capability
    metadata; see \code{agri_families()}.}
  \item{\code{link}}{Link function used, or \code{NULL} when the family
    implies it.}
  \item{\code{engine}}{Character string naming the engine that fitted the
    model.}
  \item{\code{engine_fit}}{The original backend fit object.}
  \item{\code{convergence}}{List recording the outcome of the convergence
    gate: \code{ok} (logical verdict), \code{code} and \code{messages}.
    The gate fails, with \code{ok = FALSE}, when the backend signalled a
    premature stop. That signal may be an exit code, a warning the fit
    emitted about non-convergence, iterations, \code{maxiter}, a singular
    or non-positive-definite fit, or the VGAM iteration counter reaching
    its ceiling, which VGAM reports through the fit rather than through a
    non-zero code. Backend fits are run inside a warning collector so that
    these messages reach the gate.}
  \item{\code{ziformula}}{Zero-inflation formula, or \code{NULL}.}
  \item{\code{dispformula}}{Dispersion formula, or \code{NULL}.}
  \item{\code{family_args}}{List of family-constructor arguments used.}
  \item{\code{engine_args}}{List of engine arguments used.}
  \item{\code{diagnostics}}{Diagnostics object, or \code{NULL} until
    computed by \code{agri_diagnose()}.}
  \item{\code{inference}}{Stored post-hoc inference results, or
    \code{NULL}.}
  \item{\code{predictions}}{Stored predictions, or \code{NULL}.}
  \item{\code{model_metrics}}{List of model fit metrics.}
  \item{\code{warnings}}{Character vector of the warnings captured from
    the backend fit, combined with the messages recorded by the
    convergence gate.}
  \item{\code{audit}}{Data frame with columns \code{time}, \code{step},
    \code{decision}, \code{reason} and \code{status}.}
  \item{\code{session}}{List recording session and package version
    information.}
}
}

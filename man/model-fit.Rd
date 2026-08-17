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
backend fit is retained in \code{engine_fit}.}
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

\name{agri_response}
\alias{agri_response}
\alias{agri_response_info}
\alias{agri_distribution_map}
\alias{agri_families}
\alias{agri_family_info}
\alias{agri_family_spec}
\alias{agri_family_candidates}
\alias{agri_family_scan}
\title{Characterize responses and screen admissible distribution families}
\usage{
agri_response(data, response, process = NULL, denominator = NULL, lower = NULL, upper = NULL)
agri_response_info(response)
agri_distribution_map(response)
agri_families(tier = NULL, engine = NULL, response_type = NULL)
agri_family_info(family)
agri_family_spec(engine = c("gamlss", "VGAM"), family,
  response_type = "expert", random_effects = FALSE,
  multivariate = FALSE, multiparameter = TRUE, smooth = TRUE,
  posthoc_mode = "unsupported",
  notes = "Expert backend family; automatic recommendation disabled.")
agri_family_candidates(response, design = NULL, tier = 1L, include_sensitivity = TRUE)
agri_family_scan(data, response, design = NULL, candidates = "auto", tier = 1L,
  fit = TRUE, deep = FALSE, formula = NULL, engine_args = list(), ...)
}
\description{Classifies the mathematical support of univariate or supported multivariate agricultural responses and constructs a capability-aware set of candidate distributions.}
\details{The count registry includes Poisson, negative-binomial, COM-Poisson, generalized-Poisson, zero-inflated and hurdle variants. Family screening first applies support and design-compatibility gates. Model convergence and diagnostics are then considered. Information criteria rank only structurally admissible candidates and never override experimental-design incompatibility. Multivariate response vectors can be recognized as positive compositions or categorical-count matrices for VGAM Dirichlet and Dirichlet-multinomial workflows. Compositions containing boundary zeros are flagged separately rather than being forced into an ordinary Dirichlet model. Families are divided into validated, advanced and expert tiers.}
\arguments{
  \item{data}{A data frame containing the experimental data.}
  \item{response}{A character string, expression, or agri_response object specifying the response variable.}
  \item{process}{An optional character string specifying the response process type.}
  \item{denominator}{An optional character string or expression specifying the denominator for binomial responses.}
  \item{lower}{An optional numeric value specifying the lower bound.}
  \item{upper}{An optional numeric value specifying the upper bound.}
  \item{tier}{An integer specifying the family tier (1-3).}
  \item{engine}{An optional character string specifying the statistical engine.}
  \item{response_type}{An optional character string specifying the response type.}
  \item{family}{A character string or agri_family_spec object specifying the distribution family.}
  \item{random_effects}{Logical; if \code{TRUE}, consider random effects.}
  \item{multivariate}{Logical; if \code{TRUE}, consider multivariate families.}
  \item{multiparameter}{Logical; if \code{TRUE}, consider multi-parameter families.}
  \item{smooth}{Logical; if \code{TRUE}, consider smooth terms.}
  \item{posthoc_mode}{A character string specifying the post-hoc mode.}
  \item{notes}{A character string specifying additional notes.}
  \item{design}{An optional agri_design object.}
  \item{include_sensitivity}{Logical; if \code{TRUE}, include sensitivity analysis.}
  \item{candidates}{A character vector of candidate family names.}
  \item{fit}{Logical; if \code{TRUE}, fit models during scanning.}
  \item{deep}{Logical; if \code{TRUE}, perform deep analysis.}
  \item{formula}{An optional formula for model fitting.}
  \item{engine_args}{A list of additional arguments passed to the engine.}
  \item{...}{Additional arguments passed to methods.}
}

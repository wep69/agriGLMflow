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
\value{
\code{agri_response()} returns a list of class \code{agri_response} with
components:
\describe{
  \item{\code{name}}{Name of the response variable.}
  \item{\code{denominator}}{Denominator for proportion or binomial-count
    responses, or \code{NULL}.}
  \item{\code{type}}{Character string giving the characterized response
    type, for example \code{"count"}.}
  \item{\code{process}}{Declared response process, or \code{NULL}.}
  \item{\code{multivariate}}{Logical; \code{TRUE} for multivariate
    responses.}
  \item{\code{n}}{Number of observations.}
  \item{\code{n_missing}}{Number of missing observations.}
  \item{\code{mean}}{Observed mean.}
  \item{\code{variance}}{Observed variance.}
  \item{\code{variance_mean_ratio}}{Variance-to-mean ratio, used to signal
    over- or under-dispersion.}
  \item{\code{sd}}{Observed standard deviation.}
  \item{\code{min}}{Observed minimum.}
  \item{\code{max}}{Observed maximum.}
  \item{\code{zero_fraction}}{Observed fraction of zeros.}
  \item{\code{one_fraction}}{Observed fraction of ones.}
  \item{\code{boundary_pattern}}{Character string describing boundary
    behaviour such as zero or one inflation, or \code{NA}.}
  \item{\code{poisson_zero_expected}}{Expected zero fraction under a
    Poisson model with the observed mean.}
  \item{\code{zero_excess_ratio}}{Ratio of observed to expected zeros.}
  \item{\code{skewness}}{Observed skewness.}
  \item{\code{excess_kurtosis}}{Observed excess kurtosis.}
  \item{\code{n_unique}}{Number of distinct observed values.}
  \item{\code{levels}}{Declared levels of a categorical response, or
    \code{NULL}.}
  \item{\code{ordered}}{Logical; \code{TRUE} for ordered categorical
    responses.}
  \item{\code{bounds}}{Named numeric vector of length two giving the
    declared support bounds.}
  \item{\code{audit}}{Data frame with columns \code{time}, \code{step},
    \code{decision}, \code{reason} and \code{status}.}
}

\code{agri_response_info()} returns the same response metadata as a plain
list. \code{agri_distribution_map()} returns a character vector of the
distribution domains admissible for the characterized response.

\code{agri_families()} and \code{agri_family_info()} return a data frame
with one row per family and columns \code{id}, \code{label},
\code{response_type}, \code{domain}, \code{engine}, \code{engine_family},
\code{random_effects}, \code{multivariate}, \code{multiparameter},
\code{smooth}, \code{zero_inflation}, \code{hurdle}, \code{truncation},
\code{censoring}, \code{simulation}, \code{posthoc_mode}, \code{tier} and
\code{notes}.

\code{agri_family_candidates()} returns a character vector of admissible
family identifiers. \code{agri_family_spec()} returns an expert family
specification object for the requested backend.

\code{agri_family_scan()} returns a list of class \code{agri_family_scan}
with components \code{response}, \code{design}, \code{candidates},
\code{table}, \code{models}, \code{recommended} and \code{audit}. The
\code{table} element is a data frame with columns \code{family},
\code{engine}, \code{status}, \code{converged}, \code{AIC}, \code{BIC},
\code{logLik}, \code{note}, \code{delta_AIC} and \code{role}.
}

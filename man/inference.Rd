\name{agri_means}
\alias{agri_anova}
\alias{agri_means}
\alias{agri_contrasts}
\alias{agri_trends}
\alias{agri_simple_effects}
\alias{agri_interaction_contrast}
\alias{agri_effects}
\alias{agri_predict}
\alias{agri_cld}
\title{Post-model inference, contrasts, trends and predictions}
\usage{
agri_anova(object, ...)
agri_means(object, specs, scale = c("response", "link"),
  adjust = "tukey", at = list(), level = 0.95,
  bootstrap = 0L, ...)
agri_contrasts(object, specs = NULL, method = "pairwise",
  adjust = "tukey", scale = c("response", "link"),
  weights = NULL, control = NULL, bootstrap = 0L, ...)
agri_trends(object, variable, by = NULL, delta = NULL, ...)
agri_simple_effects(object, focal, by, adjust = "tukey",
  scale = c("response", "link"), bootstrap = 0L, ...)
agri_interaction_contrast(object, factors,
  interaction = "pairwise", adjust = "holm",
  scale = c("response", "link"), ...)
agri_effects(object, variables = NULL, ...)
agri_predict(object, newdata = NULL,
  type = c("response", "link", "conditional", "marginal"), ...)
agri_cld(object, specs, adjust = "tukey", ...)
}
\description{Provides adjusted means, planned contrasts, trends, marginal effects and predictions while recording the interpretation scale.}
\details{For model classes natively supported by emmeans,
agriGLMflow delegates reference-grid inference to that package.
For VGAM multi-outcome models, the package computes standardized
response or category probabilities. GLMMadaptive objects use
explicit standardized predictions rather than assuming native
emmeans support. For zero-inflated or hurdle GLMMadaptive fits,
mean-subject response predictions are labelled as such because
population-marginal prediction of the extra-zero process is not
silently approximated. Optional bootstrap intervals and bootstrap
multiplicity adjustments are available for standardized summaries.
Dunnett treatment-versus-control contrasts are requested with
\code{method = "dunnett"} and an optional \code{control} level;
emmeans-supported engines use the \code{trt.vs.ctrl} contrast
family and standardized VGAM/GLMMadaptive summaries use a
bootstrap simultaneous max-|t| procedure when bootstrap draws
are requested. Compact-letter displays are intentionally not
used for VGAM or GLMMadaptive standardized predictions. Ordinal
predictions are returned as category probabilities on the
response scale.}
\arguments{
  \item{object}{An object of class \code{agri_model}.}
  \item{specs}{A character string or formula specifying the variables for which to compute means or contrasts.}
  \item{scale}{A character string specifying the scale for predictions ("response" or "link").}
  \item{adjust}{A character string specifying the p-value adjustment method.}
  \item{at}{A list of values at which to evaluate the predictions.}
  \item{level}{A numeric value specifying the confidence level.}
  \item{bootstrap}{An integer specifying the number of bootstrap samples.}
  \item{method}{A character string specifying the contrast method.}
  \item{weights}{Optional weights for contrasts.}
  \item{control}{Optional control level for Dunnett contrasts.}
  \item{variable}{A character string specifying the variable for trends.}
  \item{by}{An optional character string specifying the grouping variable.}
  \item{delta}{An optional numeric value for finite-difference step size.}
  \item{focal}{A character string specifying the focal variable for simple effects.}
  \item{factors}{A character vector specifying factors for interaction contrasts.}
  \item{interaction}{A character string specifying the interaction contrast method.}
  \item{variables}{An optional character vector specifying variables for marginal effects.}
  \item{newdata}{An optional data frame for predictions.}
  \item{type}{A character string specifying the prediction type ("response", "link", "conditional", "marginal").}
  \item{...}{Additional arguments passed to methods.}
}

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
response scale. \code{agri_anova()} requires an engine able to
produce a deviance or ANOVA table; this is verified for engine
\code{"stats"}. Engines without that capability, for example
\code{"glmmTMB"}, raise an informative error instead of returning a
table. A Dunnett \code{control} that is omitted warns that the first
level was adopted; a \code{control} that is not found raises an error
that lists the available levels. \code{weights} is a weighting
specification passed to \code{emmeans::contrast()} alongside
\code{method}, not a contrast family. \code{delta} is forwarded to
\code{emmeans::emtrends()} as \code{delta.var}. For
\code{agri_means()} and \code{agri_contrasts()}, bootstrap intervals
are implemented only for the VGAM and GLMMadaptive engines; requesting
\code{bootstrap} for any other engine warns that the engine returns
analytic intervals and points to \code{agri_bootstrap()}.
\code{agri_cld()} accepts \code{specs} as a formula or a character
string, and warns when the resulting letters cannot be matched to the
levels of the predictor, returning the means without letters instead
of an all-\code{NA} column.}
\arguments{
  \item{object}{An object of class \code{agri_model}.}
  \item{specs}{A character string or formula specifying the variables for
which to compute means or contrasts. Both forms are accepted by
\code{agri_cld()}.}
  \item{scale}{A character string specifying the scale for predictions ("response" or "link").}
  \item{adjust}{A character string specifying the p-value adjustment method.}
  \item{at}{A list of values at which to evaluate the predictions.}
  \item{level}{A numeric value specifying the confidence level.}
  \item{bootstrap}{An integer specifying the number of bootstrap samples. Intervals
are computed by resampling only for the VGAM and GLMMadaptive engines; other
engines return analytic intervals and warn when \code{bootstrap} is requested.}
  \item{method}{A character string specifying the contrast method.}
  \item{weights}{A weighting specification for contrasts, passed to
\code{emmeans::contrast()} alongside \code{method}.}
  \item{control}{Optional control level for Dunnett contrasts. When omitted,
the first level is used and a warning names it; a control level that is
not present in the predictor raises an error listing the available levels.}
  \item{variable}{A character string specifying the variable for trends.}
  \item{by}{An optional character string specifying the grouping variable.}
  \item{delta}{An optional numeric value for the finite-difference step size. On
the \code{emmeans} branch of \code{agri_trends()} it is forwarded to
\code{emmeans::emtrends()} as \code{delta.var}.}
  \item{focal}{A character string specifying the focal variable for simple effects.}
  \item{factors}{A character vector specifying factors for interaction contrasts.}
  \item{interaction}{A character string specifying the interaction contrast method.}
  \item{variables}{An optional character vector specifying variables for marginal effects.}
  \item{newdata}{An optional data frame for predictions.}
  \item{type}{A character string specifying the prediction type ("response", "link", "conditional", "marginal").}
  \item{...}{Additional arguments passed to methods.}
}
\value{
\code{agri_anova()} returns an \code{anova} table (a data frame) for
engines that support a deviance or ANOVA table. Engine \code{"stats"} is
verified to support this. For engines that cannot produce such a table the
function raises an informative error; engine \code{"glmmTMB"} fails with
the message \code{"ANOVA/deviance table is not available for
engine 'glmmTMB' with these arguments."}.

\code{agri_means()} returns a list of class \code{agri_posthoc} with
components \code{method}, \code{table}, \code{emmeans}, \code{scale},
\code{adjust} and \code{object}.

\code{agri_contrasts()} returns a list of class \code{agri_posthoc} with
components \code{method}, \code{table}, \code{contrasts}, \code{scale},
\code{adjust}, \code{control} and \code{object}.

\code{agri_predict()} returns a numeric vector of predictions.

\code{agri_trends()} returns a list of class \code{agri_posthoc} with
components \code{method}, \code{table}, \code{trends} and \code{object}.
That structure is produced by the \code{emmeans::emtrends()} branch,
which serves the stats, glmmTMB, gamlss and ordinal engines; the VGAM
and GLMMadaptive finite-difference branches return \code{method},
\code{table} and \code{object}. \code{agri_simple_effects()} and
\code{agri_interaction_contrast()} return post-hoc summaries for trends,
simple effects and interaction contrasts respectively.
\code{agri_effects()} returns marginal-effect summaries, or model
predictions with a warning when the \pkg{marginaleffects} package is
unavailable. \code{agri_cld()} returns a compact-letter display and is not
available for VGAM models. It resolves the predictor from \code{specs}
whether that is a formula or a character string, and warns when the letters
cannot be matched to the levels of the predictor; in that case the means are
returned with the \code{.cld} column left as \code{NA}.
}

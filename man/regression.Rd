\name{agri_regression}
\alias{agri_regression}
\alias{agri_compare_curves}
\title{Quantitative-treatment and dose-response regression}
\usage{
agri_regression(data, response, x,
  model = c("linear", "quadratic", "cubic", "linear_plateau",
    "quadratic_plateau", "mitscherlich", "michaelis_menten",
    "logistic", "gompertz", "weibull", "gam", "vgam"),
  design = NULL, family = "gaussian", engine = "auto",
  by = NULL, start = NULL, weights = NULL, ...)
agri_compare_curves(data, response, x, group,
  model = c("linear", "quadratic", "cubic", "linear_plateau",
    "quadratic_plateau", "mitscherlich", "michaelis_menten",
    "logistic", "gompertz", "weibull"),
  design = NULL, family = "gaussian", engine = "auto", ...)
}
\description{Fits quantitative-treatment regressions without silently converting doses to factors.}
\details{Polynomial regressions can be embedded directly in GLM or GLMM
structures. Fixed-effects nonlinear curves include plateau, Mitscherlich,
Michaelis-Menten, logistic, Gompertz and Weibull models. Dose-response
targets include uncertainty for quadratic optima, plateaus and, where
defined, ED10/ED50/ED90. \code{agri_compare_curves()} compares common and
group-specific polynomial curves, including level and shape tests; for
nonlinear Gaussian curves it compares a common curve with separately fitted
group curves. Nonlinear mixed models are not silently approximated; users
must specify an appropriate mixed nonlinear framework when scientifically
required. Terms are located by name rather than by position, so a \code{by}
interaction or a block term does not displace the quadratic target, and
\code{by} yields one target set per group. Convergence, the warnings the
fit emitted and the reason an absent target table is absent are reported on
the returned object, because a nonlinear fit that stopped at the iteration
ceiling still returns a plausible-looking parameter vector.}
\arguments{
  \item{data}{A data frame containing the experimental data.}
  \item{response}{A character string or expression specifying the response variable.}
  \item{x}{A character string or expression specifying the quantitative predictor.}
  \item{model}{A character string specifying the regression model type.}
  \item{design}{An optional agri_design object.}
  \item{family}{A character string specifying the distribution family.}
  \item{engine}{A character string specifying the statistical engine.}
  \item{by}{An optional character string specifying the grouping variable. The
target table then contains one row set per group and a \code{group} column
naming it.}
  \item{start}{An optional list of starting values for nonlinear models.}
  \item{weights}{An optional numeric vector of weights.}
  \item{group}{A character string or expression specifying the group variable for curve comparison.}
  \item{...}{Additional arguments passed to methods.}
}
\value{
\code{agri_regression()} returns a list of class \code{agri_regression}
with components:
\describe{
  \item{\code{model}}{Character string naming the fitted regression
    model.}
  \item{\code{engine}}{Character string naming the engine used.}
  \item{\code{fit}}{The backend fit object.}
  \item{\code{data}}{The data frame used for fitting.}
  \item{\code{response}}{Character string naming the response variable.}
  \item{\code{x}}{Character string naming the quantitative predictor.}
  \item{\code{targets}}{Data frame of dose-response targets, including
    uncertainty where these are defined. With \code{by}, the table holds
    one row set per group of that variable and carries an additional
    \code{group} column identifying the group each target belongs to.}
  \item{\code{family}}{Character string naming the distribution family.}
  \item{\code{convergence}}{List recording the convergence verdict of the
    underlying fit. Fits made here by \code{lm()}, \code{nls()} or
    \code{minpack.lm::nlsLM()} report \code{ok} (logical), \code{code},
    \code{engine} and, when \code{ok} is \code{FALSE}, a \code{message}
    giving the reason. When the fit came through \code{agri_model()}, the
    verdict is that model's convergence record and reports its reasons in
    \code{messages}. A failed nonlinear fit also raises a warning.}
  \item{\code{warnings}}{Character vector of the warnings captured from
    the fit. The convergence verdict is derived from these as well, so an
    optimiser that stopped early is visible here even when it returned a
    parameter vector.}
  \item{\code{note}}{Character string, or \code{NULL}. An absent target
    table is explained here instead of being returned in silence: a cubic
    curve has no unique notable point, a straight line has no optimum,
    breakpoint or plateau, and targets are reported only for Gaussian
    fits. \code{NULL} when a target table was returned.}
}

\code{agri_compare_curves()} returns the common and group-specific curves
together with the level, shape and overall curve-difference tests.
}

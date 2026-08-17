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
\details{Polynomial regressions can be embedded directly in GLM or GLMM structures. Fixed-effects nonlinear curves include plateau, Mitscherlich, Michaelis-Menten, logistic, Gompertz and Weibull models. Dose-response targets include uncertainty for quadratic optima, plateaus and, where defined, ED10/ED50/ED90. \code{agri_compare_curves()} compares common and group-specific polynomial curves, including level and shape tests; for nonlinear Gaussian curves it compares a common curve with separately fitted group curves. Nonlinear mixed models are not silently approximated; users must specify an appropriate mixed nonlinear framework when scientifically required.}
\arguments{
  \item{data}{A data frame containing the experimental data.}
  \item{response}{A character string or expression specifying the response variable.}
  \item{x}{A character string or expression specifying the quantitative predictor.}
  \item{model}{A character string specifying the regression model type.}
  \item{design}{An optional agri_design object.}
  \item{family}{A character string specifying the distribution family.}
  \item{engine}{A character string specifying the statistical engine.}
  \item{by}{An optional character string specifying the grouping variable.}
  \item{start}{An optional list of starting values for nonlinear models.}
  \item{weights}{An optional numeric vector of weights.}
  \item{group}{A character string or expression specifying the group variable for curve comparison.}
  \item{...}{Additional arguments passed to methods.}
}

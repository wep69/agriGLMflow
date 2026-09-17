\name{agri_engines}
\alias{agri_engines}
\alias{agri_dependencies}
\title{Inspect modelling engines and optional dependencies}
\usage{
agri_engines()
agri_dependencies()
}
\description{Reports availability and versions of statistical engines used by agriGLMflow.}
\details{VGAM is treated as a fixed-effects engine. glmmTMB
is the primary advanced GLMM backend. lme4 is a reference and
fallback backend for conventional mixed models, and GLMMadaptive
is available for compatible single-grouping-factor models fitted
by adaptive quadrature. GAMLSS provides distributional regression.
Optional engines remain isolated so missing packages cause
informative feature-level errors rather than namespace failures.}
\value{
\code{agri_engines()} and \code{agri_dependencies()} return the same
registry with the same columns, a data frame with one row per engine:
\describe{
  \item{\code{engine}}{Character string naming the engine.}
  \item{\code{package}}{Character string naming the package that provides
    it.}
  \item{\code{available}}{Logical; \code{TRUE} when the package can be
    loaded in the current session.}
  \item{\code{version}}{Character string giving the installed package
    version, or an empty string when the package is absent.}
  \item{\code{feature}}{Character string naming the modelling feature the
    engine provides, for example \code{"base GLM"} for \code{"stats"}.}
}
The two functions differ only in emphasis, not in content: columns such as
\code{feature} are available from either.
}

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

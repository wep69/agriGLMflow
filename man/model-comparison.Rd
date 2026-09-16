\name{agri_compare_models}
\alias{agri_compare_models}
\title{Compare structurally compatible models}
\usage{
agri_compare_models(..., models = NULL, strategy = c("admissibility", "AIC", "BIC"), diagnostics = FALSE)
}
\description{Compares candidate agriGLMflow models after convergence and optional diagnostic gates.}
\details{The default strategy prioritizes admissibility and only then information criteria. A warning is issued when formulas differ because family and structural changes would then be confounded.}
\arguments{
  \item{...}{An optional sequence of agri_model objects to compare.}
  \item{models}{An optional list of agri_model objects to compare.}
  \item{strategy}{A character string specifying the comparison strategy ("admissibility", "AIC", "BIC").}
  \item{diagnostics}{Logical; if \code{TRUE}, include diagnostic information in comparison.}
}
\value{
\code{agri_compare_models()} returns the result of the comparison: the
compared models ranked according to \code{strategy}, with the selected
model identified. Under the default admissibility strategy, admissible
models are ranked first and information criteria are used only to order
admissible candidates. A warning is issued when the compared models use
different formulas, and when they were fitted under different experimental
designs the information criteria are reported as not comparable.
}

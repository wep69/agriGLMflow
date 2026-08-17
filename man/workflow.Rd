\name{agri_workflow}
\alias{agri_workflow}
\alias{agri_example_data}
\title{Run the unified agronomic modelling workflow}
\usage{
agri_workflow(data, response, denominator = NULL, treatment = NULL,
  design = c("crd", "rcbd", "factorial", "split_plot", "split_split",
    "strip_plot", "repeated", "multi_environment"),
  family = "auto", tier = 1L, deep_scan = FALSE, fit_scan = TRUE,
  select = TRUE, design_args = list(), model_args = list(),
  posthoc = TRUE, make_figures = FALSE, report_file = NULL,
  report_format = "markdown", ...)
agri_example_data(name = c("agri_insects", "agri_disease",
  "agri_germination", "agri_cover", "agri_biomass", "agri_ordinal",
  "agri_dose", "agri_splitplot", "agri_split_split", "agri_stripplot",
  "agri_repeated", "agri_multienv", "agri_distreg", "agri_multiclass",
  "agri_multicounts", "agri_composition", "agri_ordstage", "agri_censored"))
}
\description{Orchestrates design declaration, response characterization, family screening, compatible fitting, diagnostics, post-model inference, optional graphics/reporting and auditing.}
\arguments{
  \item{data}{A data frame containing the experimental data.}
  \item{response}{A character string, expression, or vector specifying the response variable(s).}
  \item{denominator}{An optional character string or expression specifying the denominator for binomial responses.}
  \item{treatment}{An optional character string or expression specifying the treatment factor(s).}
  \item{design}{A character string specifying the experimental design type.}
  \item{family}{A character string specifying the distribution family ("auto" for automatic selection).}
  \item{tier}{An integer specifying the family tier (1-3).}
  \item{deep_scan}{Logical; if \code{TRUE}, perform deep family scanning with diagnostics.}
  \item{fit_scan}{Logical; if \code{TRUE}, fit models during family scanning.}
  \item{select}{Logical; if \code{TRUE}, select the best model.}
  \item{design_args}{A list of additional arguments passed to \code{agri_design}.}
  \item{model_args}{A list of additional arguments passed to \code{agri_model}.}
  \item{posthoc}{Logical; if \code{TRUE}, perform post-hoc inference.}
  \item{make_figures}{Logical; if \code{TRUE}, generate figures.}
  \item{report_file}{An optional character string specifying the report file path.}
  \item{report_format}{A character string specifying the report format.}
  \item{name}{A character string specifying the example dataset name.}
  \item{...}{Additional arguments passed to methods.}
}

\name{agri_design}
\alias{agri_design}
\alias{agri_validate_design}
\alias{agri_design_formula}
\alias{agri_design_info}
\title{Define and validate agricultural experimental designs}
\usage{
agri_design(data,
  design = c("crd", "rcbd", "latin_square", "factorial",
    "split_plot", "split_split", "strip_plot", "repeated",
    "multi_environment", "generic"),
  treatment = NULL, block = NULL, row = NULL, column = NULL,
  whole_plot_factor = NULL, subplot_factor = NULL,
  subsubplot_factor = NULL, whole_plot_id = NULL,
  subplot_id = NULL, strip_A = NULL, strip_B = NULL,
  strip_A_id = NULL, strip_B_id = NULL, subject = NULL,
  time = NULL, environment = NULL, genotype = NULL,
  replication = NULL, block_effect = c("random", "fixed"),
  genotype_effect = c("fixed", "random"),
  environment_effect = c("fixed", "random"),
  interaction_effect = c("fixed", "random"),
  covariance = c("independence", "ar1", "cs", "toeplitz",
    "unstructured"),
  random = NULL, fixed = NULL, ...)
agri_validate_design(design, strict = TRUE)
agri_design_formula(design, response)
agri_design_info(design)
}
\description{Creates an \code{agri_design} object that explicitly records treatment factors, blocks, experimental units, fixed terms and required random terms.}
\details{Split-plot, split-split and strip-plot structures are represented by separate experimental-unit strata. A multi-environment design requires an explicit environment variable. Block effects can be explicitly declared fixed or random; hierarchical whole-plot/subplot experimental-unit strata remain represented even when block itself is fixed. Experimental-unit identifiers are checked against their required parent treatment/block combinations. The package will not silently remove required random terms to accommodate an incompatible backend.}
\arguments{
  \item{data}{A data frame containing the experimental data.}
  \item{design}{A character string specifying the experimental design type.}
  \item{treatment}{A character string or expression specifying the treatment factor(s).}
  \item{block}{A character string or expression specifying the block factor.}
  \item{row}{A character string or expression specifying the row factor (for Latin square).}
  \item{column}{A character string or expression specifying the column factor (for Latin square).}
  \item{whole_plot_factor}{A character string or expression specifying the whole-plot factor (for split-plot).}
  \item{subplot_factor}{A character string or expression specifying the subplot factor (for split-plot).}
  \item{subsubplot_factor}{A character string or expression specifying the sub-subplot factor (for split-split).}
  \item{whole_plot_id}{A character string or expression specifying the whole-plot identifier.}
  \item{subplot_id}{A character string or expression specifying the subplot identifier.}
  \item{strip_A}{A character string or expression specifying the first strip factor (for strip-plot).}
  \item{strip_B}{A character string or expression specifying the second strip factor (for strip-plot).}
  \item{strip_A_id}{A character string or expression specifying the first strip identifier.}
  \item{strip_B_id}{A character string or expression specifying the second strip identifier.}
  \item{subject}{A character string or expression specifying the subject factor (for repeated measures).}
  \item{time}{A character string or expression specifying the time factor (for repeated measures).}
  \item{environment}{A character string or expression specifying the environment factor (for multi-environment).}
  \item{genotype}{A character string or expression specifying the genotype factor.}
  \item{replication}{A character string or expression specifying the replication factor.}
  \item{block_effect}{A character string specifying whether block effect is "random" or "fixed".}
  \item{genotype_effect}{A character string specifying whether genotype effect is "fixed" or "random".}
  \item{environment_effect}{A character string specifying whether environment effect is "fixed" or "random".}
  \item{interaction_effect}{A character string specifying whether interaction effect is "fixed" or "random".}
  \item{covariance}{A character string specifying the covariance structure.}
  \item{random}{An optional formula specifying additional random effects.}
  \item{fixed}{An optional formula specifying additional fixed effects.}
  \item{...}{Additional arguments passed to methods.}
  \item{strict}{Logical; if \code{TRUE}, perform strict validation.}
  \item{response}{A character string specifying the response variable name.}
}
\examples{
\dontrun{
data(agri_insects)
d <- agri_design(agri_insects, "rcbd", treatment = "treatment", block = "block")
agri_design_formula(d, "insects")
}
}

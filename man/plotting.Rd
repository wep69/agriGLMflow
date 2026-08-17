\name{agri_plot}
\alias{agri_plot}
\alias{agri_plot_data}
\alias{agri_plot_fit}
\alias{agri_plot_diagnostics}
\alias{agri_plot_means}
\alias{agri_plot_contrasts}
\alias{agri_plot_regression}
\alias{agri_plot_interaction}
\alias{agri_plot_distribution}
\alias{agri_plot_random}
\alias{agri_plot_family_scan}
\title{Scientific graphics for agriGLMflow analyses}
\description{Creates ggplot2 objects for observed data, fitted values, residual diagnostics, means, contrasts, regressions, interactions, distributions, random effects and family comparisons.}
\details{The graphical philosophy is to show observed data together with model estimates and uncertainty whenever the response and model class make that scientifically meaningful. Bar charts of continuous means are not the default.}
\arguments{
  \item{object}{An object of class \code{agri_model}, \code{agri_regression}, or \code{agri_family_scan}.}
  \item{data}{A data frame containing the data to plot.}
  \item{response}{A character string or expression specifying the response variable.}
  \item{treatment}{An optional character string or expression specifying the treatment variable.}
  \item{type}{A character string specifying the plot type.}
  \item{time}{An optional character string or expression specifying the time variable.}
  \item{group}{An optional character string or expression specifying the grouping variable.}
  \item{specs}{A character string or formula specifying the variables for means or contrasts.}
  \item{panel}{A character string specifying the diagnostic panel type.}
  \item{n}{An integer specifying the number of prediction points.}
  \item{x}{A character string or expression specifying the x-axis variable.}
  \item{trace}{A character string or expression specifying the trace variable for interactions.}
  \item{metric}{A character string specifying the metric for family scan plots.}
  \item{...}{Additional arguments passed to methods.}
}

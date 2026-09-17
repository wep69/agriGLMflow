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
\details{The graphical philosophy is to show observed data together with
model estimates and uncertainty whenever the response and model class make
that scientifically meaningful. Bar charts of continuous means are not the
default. \code{agri_plot_means()} and \code{agri_plot_contrasts()} accept
either an \code{agri_model}, from which they compute the means or the
contrasts, or the \code{agri_posthoc} object returned by
\code{agri_means()} and \code{agri_contrasts()}, which already carries the
table and the fitted model. When an \code{agri_posthoc} object is supplied,
\code{specs} may be omitted; \code{agri_plot_means()} then reads the
grouping column from the stored table. The figure step of the integrated
workflow relies on this, because the workflow holds \code{agri_posthoc}
objects.}
\arguments{
  \item{object}{An object of class \code{agri_model},
\code{agri_regression}, \code{agri_family_scan}, or an \code{agri_posthoc}
object for \code{agri_plot_means()} and \code{agri_plot_contrasts()}.}
  \item{data}{A data frame containing the data to plot.}
  \item{response}{A character string or expression specifying the response variable.}
  \item{treatment}{An optional character string or expression specifying the treatment variable.}
  \item{type}{A character string specifying the plot type.}
  \item{time}{An optional character string or expression specifying the time variable.}
  \item{group}{An optional character string or expression specifying the grouping variable.}
  \item{specs}{A character string or formula specifying the variables for
means or contrasts. Required when an \code{agri_model} is supplied; may be
omitted when an \code{agri_posthoc} object is supplied.}
  \item{panel}{A character string specifying the diagnostic panel type.}
  \item{n}{An integer specifying the number of prediction points.}
  \item{x}{A character string or expression specifying the x-axis variable.}
  \item{trace}{A character string or expression specifying the trace variable for interactions.}
  \item{metric}{A character string specifying the metric for family scan plots.}
  \item{...}{Additional arguments passed to methods.}
}
\value{
Every plotting function documented here returns an object of class
\code{ggplot}, which is drawn when it is printed. Creating these objects
requires the \pkg{ggplot2} package. Because the returned value is a
\code{ggplot} object, it can be extended with further \pkg{ggplot2} layers
before it is printed.
}

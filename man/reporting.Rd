\name{agri_report}
\alias{agri_report}
\alias{agri_audit}
\alias{agri_export}
\title{Audit and export reproducible analyses}
\usage{
agri_report(object, file = NULL, format = c("markdown", "quarto", "html", "docx", "pdf"), title = "agriGLMflow statistical report", ...)
agri_audit(object)
agri_export(object, path, what = c("audit", "model_table", "report"), ...)
}
\description{Generates a human-readable audit trail and reproducible model report.}
\details{Markdown and Quarto-source output require no rendering package. HTML, Word and PDF rendering use rmarkdown when installed. Reports state the experimental design, response type, distribution, engine, convergence status, diagnostics and model-selection caveats.}
\arguments{
  \item{object}{An object of class \code{agri_workflow} or \code{agri_model}.}
  \item{file}{An optional character string specifying the output file path.}
  \item{format}{A character string specifying the output format ("markdown", "quarto", "html", "docx", "pdf").}
  \item{title}{A character string specifying the report title.}
  \item{path}{A character string specifying the export directory path.}
  \item{what}{A character string specifying what to export ("audit", "model_table", "report").}
  \item{...}{Additional arguments passed to methods.}
}
\value{
\code{agri_report()} returns a character string giving the path to the
generated report file.

\code{agri_audit()} returns a data frame with columns \code{time},
\code{step}, \code{decision}, \code{reason} and \code{status}.

\code{agri_export()} returns the path to the exported file.
}

print.agri_design <- function(x, ...) {
  cat("<agri_design>\n")
  cat(" Design:", x$design, "\n")
  cat(" Treatments:", paste(x$treatment %||% character(), collapse = ", "), "\n")
  if (length(x$blocking)) cat(" Blocking:", paste(x$blocking, collapse = ", "), "\n")
  if (length(x$experimental_units)) cat(" Experimental units:", paste(x$experimental_units, collapse = ", "), "\n")
  if (length(x$random_terms)) cat(" Random structure:", paste(x$random_terms, collapse = " + "), "\n")
  invisible(x)
}

print.agri_response <- function(x, ...) {
  cat("<agri_response>\n")
  cat(" Response:", paste(x$name, collapse = ", "), "\n")
  cat(" Type:", x$type, "\n")
  cat(" N:", x$n, "\n")
  if (length(x$mean) == 1L && is.finite(x$mean)) cat(" Mean:", format(x$mean, digits = 5), "\n")
  if (length(x$mean) > 1L) cat(" Component means:", paste(format(x$mean, digits = 5), collapse = ", "), "\n")
  if (length(x$variance) == 1L && is.finite(x$variance)) cat(" Variance:", format(x$variance, digits = 5), "\n")
  if (length(x$zero_fraction) == 1L && is.finite(x$zero_fraction)) cat(" Zero fraction:", format(x$zero_fraction, digits = 4), "\n")
  invisible(x)
}

print.agri_family_scan <- function(x, ...) {
  cat("<agri_family_scan>\n")
  cat(" Response type:", x$response$type, "\n")
  cat(" Candidate families:", paste(x$candidates, collapse = ", "), "\n")
  if (!is.null(x$table) && nrow(x$table)) {
    print(x$table, row.names = FALSE)
  }
  if (length(x$recommended)) cat(" Recommended:", paste(x$recommended, collapse = ", "), "\n")
  invisible(x)
}

print.agri_model <- function(x, ...) {
  cat("<agri_model>\n")
  cat(" Engine:", x$engine, "\n")
  cat(" Family:", x$family, "\n")
  cat(" Formula:", paste(deparse(x$formula), collapse = " "), "\n")
  cat(" Converged:", ifelse(isTRUE(x$convergence$ok), "yes", "no/uncertain"), "\n")
  invisible(x)
}

summary.agri_model <- function(object, ...) {
  cat("agriGLMflow model summary\n")
  cat("=========================\n")
  print(object)
  cat("\nBackend summary:\n")
  out <- try(summary(object$engine_fit), silent = TRUE)
  if (inherits(out, "try-error")) print(object$engine_fit) else print(out)
  invisible(object)
}

print.agri_model_set <- function(x, ...) {
  cat("<agri_model_set>\n")
  print(x$table, row.names = FALSE)
  invisible(x)
}

print.agri_diagnostics <- function(x, ...) {
  cat("<agri_diagnostics>\n")
  cat(" Overall:", x$overall, "\n")
  cat(" Convergence:", x$convergence$status, "\n")
  if (!is.null(x$dispersion$ratio) && is.finite(x$dispersion$ratio)) {
    cat(" Dispersion ratio:", format(x$dispersion$ratio, digits = 4), "\n")
  }
  if (length(x$messages)) cat(" Notes:\n -", paste(x$messages, collapse = "\n - "), "\n")
  invisible(x)
}

print.agri_posthoc <- function(x, ...) {
  cat("<agri_posthoc>\n")
  cat(" Method:", x$method, "\n")
  if (!is.null(x$table)) print(x$table, row.names = FALSE)
  invisible(x)
}

print.agri_regression <- function(x, ...) {
  cat("<agri_regression>\n")
  cat(" Model:", x$model, "\n")
  cat(" Engine:", x$engine, "\n")
  if (!is.null(x$targets)) print(x$targets, row.names = FALSE)
  invisible(x)
}

summary.agri_regression <- function(object, ...) {
  print(object)
  cat("\nBackend summary:\n")
  print(summary(object$fit))
  invisible(object)
}

print.agri_workflow <- function(x, ...) {
  cat("<agri_workflow>\n")
  cat(" Design:", x$design$design, "\n")
  cat(" Response:", paste(x$response$name, collapse = ", "), " (", x$response$type, ")\n", sep = "")
  if (!is.null(x$selected_model)) {
    cat(" Selected model:", x$selected_model$family, "via", x$selected_model$engine, "\n")
  }
  invisible(x)
}

plot.agri_model <- function(x, ...) agri_plot(x, ...)
predict.agri_model <- function(object, ...) agri_predict(object, ...)

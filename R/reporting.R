#' Return the model decision audit trail
#' @export
agri_audit <- function(object) {
  if (inherits(object, "agri_workflow")) {
    audits <- list(object$design$audit, object$response$audit,
                   object$family_scan$audit %||% NULL,
                   object$selected_model$audit %||% NULL)
    audits <- Filter(Negate(is.null), audits)
    return(if (length(audits)) do.call(rbind, audits) else data.frame())
  }
  if (!is.null(object$audit)) return(object$audit)
  .agri_abort("No audit trail is available for this object.")
}

.report_table_md <- function(x, max_rows = 50L) {
  if (is.null(x)) return(character())
  x <- try(as.data.frame(x), silent = TRUE)
  if (inherits(x, "try-error") || !nrow(x)) return(character())
  if (nrow(x) > max_rows) x <- x[seq_len(max_rows), , drop = FALSE]
  vals <- lapply(x, function(z) {
    if (is.numeric(z)) format(signif(z, 5), trim = TRUE, scientific = FALSE) else as.character(z)
  })
  x <- as.data.frame(vals, stringsAsFactors = FALSE)
  hdr <- paste0("| ", paste(names(x), collapse = " | "), " |")
  sep <- paste0("|", paste(rep("---", ncol(x)), collapse = "|"), "|")
  rows <- apply(x, 1L, function(r) paste0("| ", paste(gsub("\\|", "/", r), collapse = " | "), " |"))
  c(hdr, sep, rows)
}

.report_markdown <- function(object) {
  if (inherits(object, "agri_workflow")) model <- object$selected_model else model <- object
  if (!inherits(model, "agri_model")) .agri_abort("agri_report requires an agri_model or agri_workflow.")
  dg <- try(agri_diagnose(model), silent = TRUE)
  au <- if (inherits(object, "agri_workflow")) agri_audit(object) else agri_audit(model)
  design <- model$design
  lines <- c(
    "# agriGLMflow statistical report", "",
    "## Dataset and experimental design", "",
    sprintf("- Observations: %d", nrow(model$data)),
    sprintf("- Design: %s", design$design %||% "formula-only"),
    sprintf("- Response: `%s`", paste(model$response$name, collapse = ", ")),
    sprintf("- Response type: %s", model$response$type),
    sprintf("- Formula: `%s`", paste(deparse(model$formula), collapse = " ")), "",
    "## Distribution and engine", "",
    sprintf("- Family: %s", model$family),
    sprintf("- Engine: %s", model$engine),
    sprintf("- Convergence gate: %s", ifelse(isTRUE(model$convergence$ok), "passed", "requires review")),
    sprintf("- AIC: %s", format(model$model_metrics$AIC, digits = 6)),
    sprintf("- BIC: %s", format(model$model_metrics$BIC, digits = 6)), ""
  )
  if (inherits(object, "agri_workflow") && !is.null(object$family_scan$table)) {
    lines <- c(lines, "## Family screening", "", .report_table_md(object$family_scan$table), "")
  }
  cf <- try(.agri_coef_table(model), silent = TRUE)
  if (!inherits(cf, "try-error") && !is.null(cf)) {
    cfd <- as.data.frame(cf); cfd$term <- rownames(cf); rownames(cfd) <- NULL
    cfd <- cfd[c("term", setdiff(names(cfd), "term"))]
    lines <- c(lines, "## Model coefficients", "", .report_table_md(cfd), "")
  }
  lines <- c(lines, "## Diagnostics", "")
  if (!inherits(dg, "try-error")) {
    lines <- c(lines,
      sprintf("- Overall diagnostic status: %s", dg$overall),
      sprintf("- Dispersion status: %s", dg$dispersion$status),
      sprintf("- Dispersion ratio: %s", format(dg$dispersion$ratio, digits = 5)),
      sprintf("- Zero diagnostic: %s", dg$zeros$status), ""
    )
  } else lines <- c(lines, "Diagnostics could not be generated for this engine in the current environment.", "")
  if (inherits(object, "agri_workflow")) {
    if (!is.null(object$means$table)) lines <- c(lines, "## Estimated means / standardized predictions", "", .report_table_md(object$means$table), "")
    if (!is.null(object$contrasts$table)) lines <- c(lines, "## Contrasts", "", .report_table_md(object$contrasts$table), "")
    if (!is.null(object$trends$table)) lines <- c(lines, "## Trends", "", .report_table_md(object$trends$table), "")
    if (!is.null(object$posthoc_note)) lines <- c(lines, "### Post-model inference note", "", object$posthoc_note, "")
  }
  lines <- c(lines, "## Audit trail", "")
  if (nrow(au)) {
    lines <- c(lines, "| Step | Decision | Reason | Status |", "|---|---|---|---|")
    for (i in seq_len(nrow(au))) {
      lines <- c(lines, sprintf("| %s | %s | %s | %s |", au$step[i], au$decision[i], gsub("\\|", "/", au$reason[i]), au$status[i]))
    }
  }
  lines <- c(lines, "", "## Interpretation guidance", "",
             "Interpret effects on the scale explicitly requested for inference. Family selection must remain conditional on the response support, experimental design, diagnostics, scientific plausibility and sensitivity analyses; the smallest information criterion alone is not treated as definitive evidence.")
  lines
}

#' Generate a reproducible model report
#' @export
agri_report <- function(object, file = NULL,
                        format = c("markdown", "quarto", "html", "docx", "pdf"),
                        title = "agriGLMflow statistical report", ...) {
  format <- match.arg(format)
  if (is.null(file)) {
    ext <- switch(format, markdown = "md", quarto = "qmd", html = "html", docx = "docx", pdf = "pdf")
    file <- tempfile("agriGLMflow-report-", fileext = paste0(".", ext))
  }
  md <- .report_markdown(object)
  if (format == "markdown") {
    writeLines(md, file, useBytes = TRUE)
    return(normalizePath(file, mustWork = FALSE))
  }
  if (format == "quarto") {
    yaml <- c("---", sprintf("title: \"%s\"", title), "format: html", "---", "")
    writeLines(c(yaml, md), file, useBytes = TRUE)
    return(normalizePath(file, mustWork = FALSE))
  }
  .require_pkg("rmarkdown", sprintf("%s report rendering", format))
  rmd <- tempfile(fileext = ".Rmd")
  yaml <- c("---", sprintf("title: \"%s\"", title),
            sprintf("output: %s", switch(format, html = "html_document", docx = "word_document", pdf = "pdf_document")), "---", "")
  writeLines(c(yaml, md), rmd, useBytes = TRUE)
  out <- rmarkdown::render(rmd, output_file = basename(file), output_dir = dirname(file), quiet = TRUE, ...)
  normalizePath(out, mustWork = FALSE)
}

#' Export model tables, audit trails, or reports
#' @export
agri_export <- function(object, path, what = c("audit", "model_table", "report"), ...) {
  what <- match.arg(what)
  if (what == "audit") {
    utils::write.csv(agri_audit(object), path, row.names = FALSE)
  } else if (what == "report") {
    return(agri_report(object, file = path, ...))
  } else {
    model <- if (inherits(object, "agri_workflow")) object$selected_model else object
    tab <- data.frame(family = model$family, engine = model$engine,
                      AIC = model$model_metrics$AIC, BIC = model$model_metrics$BIC,
                      logLik = model$model_metrics$logLik, stringsAsFactors = FALSE)
    utils::write.csv(tab, path, row.names = FALSE)
  }
  normalizePath(path, mustWork = FALSE)
}

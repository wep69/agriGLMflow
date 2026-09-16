#' Compare structurally compatible candidate models
#' @export
agri_compare_models <- function(..., models = NULL, strategy = c("admissibility", "AIC", "BIC"),
                                diagnostics = FALSE) {
  strategy <- match.arg(strategy)
  dots <- list(...)
  if (is.null(models)) models <- dots
  if (inherits(models, "agri_family_scan")) models <- models$models
  if (inherits(models, "agri_model")) models <- list(models)
  if (!is.list(models) || !length(models)) .agri_abort("Provide one or more agri_model objects.")
  okcls <- vapply(models, inherits, logical(1), what = "agri_model")
  if (!all(okcls)) .agri_abort("All compared objects must be agri_model objects.")
  model_names <- names(models)
  if (is.null(model_names)) model_names <- rep("", length(models))
  blank <- is.na(model_names) | !nzchar(model_names)
  model_names[blank] <- paste0("model", which(blank))
  names(models) <- model_names

  # `paste()` on a formula object returns one element per deparsed term
  # (e.g. "~", "y", "x"), so the formula must be collapsed before pasting.
  design_sig <- vapply(models, function(m) {
    paste(m$design$design %||% "formula",
          paste(deparse(m$formula), collapse = ""), sep = "::")
  }, character(1))
  # Families may differ but fixed/random structures must be the same. Normalize the formula text.
  form_sig <- vapply(models, function(m) paste(deparse(m$formula), collapse = ""), character(1))
  if (length(unique(form_sig)) > 1L) {
    .agri_warn("Compared models use different formulas. Interpret information criteria cautiously because family and structural changes are confounded.")
  }
  # Information criteria are only comparable when the experimental-unit
  # structure is identical: a different design changes the likelihood itself.
  if (length(unique(design_sig)) > 1L) {
    .agri_warn("Compared models were fitted under different experimental designs. Information criteria are not comparable across designs because the experimental-unit structure changes the likelihood.")
  }

  tab <- do.call(rbind, lapply(seq_along(models), function(i) {
    m <- models[[i]]
    dg <- if (diagnostics) try(agri_diagnose(m), silent = TRUE) else NULL
    diag_ok <- if (is.null(dg) || inherits(dg, "try-error")) NA else dg$overall != "problem"
    data.frame(
      model = model_names[i],
      family = m$family, engine = m$engine,
      converged = isTRUE(m$convergence$ok), diagnostic_ok = diag_ok,
      logLik = .safe_logLik(m$engine_fit), AIC = .safe_AIC(m$engine_fit),
      BIC = .safe_BIC(m$engine_fit), stringsAsFactors = FALSE
    )
  }))
  admissible <- tab$converged & (is.na(tab$diagnostic_ok) | tab$diagnostic_ok)
  tab$admissible <- admissible
  tab$delta_AIC <- NA_real_
  if (any(admissible & is.finite(tab$AIC))) {
    amin <- min(tab$AIC[admissible & is.finite(tab$AIC)])
    tab$delta_AIC <- tab$AIC - amin
  }
  if (strategy == "admissibility") {
    ord <- order(!tab$admissible, tab$delta_AIC, tab$BIC, na.last = TRUE)
  } else if (strategy == "AIC") {
    ord <- order(tab$AIC, na.last = TRUE)
  } else {
    ord <- order(tab$BIC, na.last = TRUE)
  }
  tab <- tab[ord, , drop = FALSE]
  selected_name <- tab$model[which(tab$admissible)[1L]]
  selected <- if (length(selected_name)) models[[match(selected_name, model_names)]] else NULL
  out <- list(table = tab, models = models, strategy = strategy, selected = selected)
  class(out) <- "agri_model_set"
  out
}

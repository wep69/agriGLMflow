`%||%` <- function(x, y) if (is.null(x)) y else x

.agri_abort <- function(message, call. = FALSE) {
  stop(message, call. = call.)
}

.agri_warn <- function(message, call. = FALSE) {
  warning(message, call. = call., immediate. = TRUE)
}

.agri_message <- function(...) message(...)

.require_pkg <- function(pkg, feature = NULL) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    feature_txt <- if (is.null(feature)) "this operation" else feature
    .agri_abort(sprintf(
      "Package '%s' is required for %s. Install it with install.packages('%s').",
      pkg, feature_txt, pkg
    ))
  }
  invisible(TRUE)
}

.capture_names <- function(expr, env = parent.frame(), allow_null = TRUE) {
  if (identical(expr, quote(NULL))) return(if (allow_null) NULL else character())
  if (is.symbol(expr)) {
    # Evaluate the symbol in the caller's environment: if it resolves to a
    # character string (e.g. response = resp_name where resp_name = "insects"),
    # return that value.  Otherwise treat the symbol itself as the column name.
    val <- try(eval(expr, envir = env), silent = TRUE)
    if (!inherits(val, "try-error") && is.character(val)) return(val)
    return(as.character(expr))
  }
  val <- try(eval(expr, envir = env), silent = TRUE)
  if (!inherits(val, "try-error") && is.character(val)) return(val)
  txt <- paste(deparse(expr), collapse = "")
  if (startsWith(txt, "c(")) {
    val2 <- try(eval(parse(text = txt), envir = env), silent = TRUE)
    if (!inherits(val2, "try-error") && is.character(val2)) return(val2)
  }
  txt
}

.assert_columns <- function(data, cols, context = "data") {
  cols <- unique(stats::na.omit(cols))
  cols <- cols[nzchar(cols)]
  missing_cols <- setdiff(cols, names(data))
  if (length(missing_cols)) {
    .agri_abort(sprintf(
      "Missing column(s) in %s: %s.", context, paste(missing_cols, collapse = ", ")
    ))
  }
  invisible(TRUE)
}

.bt <- function(x) paste0("`", x, "`")

.join_terms <- function(x) {
  x <- unique(x[!is.na(x) & nzchar(x)])
  if (!length(x)) "1" else paste(x, collapse = " + ")
}

.interaction_term <- function(x) {
  x <- x[!is.na(x) & nzchar(x)]
  if (!length(x)) "1" else paste(.bt(x), collapse = " * ")
}

.random_term <- function(group) sprintf("(1 | %s)", group)

.as_formula <- function(response, fixed = "1", random = character()) {
  rhs <- c(fixed, random)
  rhs <- rhs[nzchar(rhs)]
  stats::as.formula(sprintf("%s ~ %s", response, paste(rhs, collapse = " + ")))
}

.response_name_from_formula <- function(formula) {
  if (is.null(formula)) return(NULL)
  lhs <- formula[[2L]]
  paste(deparse(lhs), collapse = "")
}

.simple_cbind_response_names <- function(formula) {
  if (is.null(formula) || length(formula) < 3L) return(NULL)
  lhs <- formula[[2L]]
  if (!is.call(lhs) || !identical(as.character(lhs[[1L]]), "cbind")) return(NULL)
  args <- as.list(lhs)[-1L]
  if (!length(args) || !all(vapply(args, is.symbol, logical(1)))) return(NULL)
  vapply(args, as.character, character(1))
}

.safe_AIC <- function(object) {
  out <- try(stats::AIC(object), silent = TRUE)
  if (inherits(out, "try-error") || length(out) != 1L || !is.finite(out)) NA_real_ else as.numeric(out)
}

.safe_BIC <- function(object) {
  out <- try(stats::BIC(object), silent = TRUE)
  if (inherits(out, "try-error") || length(out) != 1L || !is.finite(out)) NA_real_ else as.numeric(out)
}

.safe_logLik <- function(object) {
  out <- try(stats::logLik(object), silent = TRUE)
  if (inherits(out, "try-error") || length(out) != 1L) NA_real_ else as.numeric(out)
}

.safe_df_residual <- function(object) {
  out <- try(stats::df.residual(object), silent = TRUE)
  if (inherits(out, "try-error") || length(out) != 1L) NA_real_ else as.numeric(out)
}

.safe_predict <- function(object, newdata = NULL, type = "response", ...) {
  args <- c(list(object = object, type = type), list(...))
  if (!is.null(newdata)) args$newdata <- newdata
  out <- try(do.call(stats::predict, args), silent = TRUE)
  if (inherits(out, "try-error")) {
    args$type <- NULL
    out <- do.call(stats::predict, args)
  }
  out
}

.safe_residuals <- function(object, type = "pearson") {
  out <- try(stats::residuals(object, type = type), silent = TRUE)
  if (inherits(out, "try-error")) {
    out <- try(stats::residuals(object), silent = TRUE)
  }
  if (inherits(out, "try-error")) numeric() else as.numeric(out)
}

.is_count_vector <- function(y) {
  is.numeric(y) && all(is.finite(y) | is.na(y)) &&
    all(y[!is.na(y)] >= 0) &&
    all(abs(y[!is.na(y)] - round(y[!is.na(y)])) < sqrt(.Machine$double.eps))
}

.skewness_basic <- function(x) {
  x <- x[is.finite(x)]
  if (length(x) < 3L) return(NA_real_)
  s <- stats::sd(x)
  if (!is.finite(s) || s == 0) return(0)
  mean((x - mean(x))^3) / s^3
}

.kurtosis_basic <- function(x) {
  x <- x[is.finite(x)]
  if (length(x) < 4L) return(NA_real_)
  s <- stats::sd(x)
  if (!is.finite(s) || s == 0) return(0)
  mean((x - mean(x))^4) / s^4 - 3
}

.make_named <- function(x, nm) {
  names(x) <- nm
  x
}

.audit_add <- function(audit, step, decision, reason = NULL, status = "info") {
  row <- data.frame(
    time = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
    step = as.character(step),
    decision = as.character(decision),
    reason = as.character(reason %||% ""),
    status = as.character(status),
    stringsAsFactors = FALSE
  )
  if (is.null(audit) || !nrow(audit)) row else rbind(audit, row)
}

.check_random_syntax <- function(formula) {
  grepl("\\|", paste(deparse(formula), collapse = ""), fixed = FALSE)
}

.design_has_random <- function(design) {
  inherits(design, "agri_design") && length(design$random_terms) > 0L
}

.model_data <- function(object) {
  if (inherits(object, "agri_model")) return(object$data)
  tryCatch(stats::model.frame(object), error = function(e) NULL)
}

.response_vector <- function(object) {
  if (inherits(object, "agri_model")) {
    rn <- object$response$name %||% .response_name_from_formula(object$formula)
    if (!is.null(rn) && length(rn) > 1L && all(rn %in% names(object$data))) return(as.matrix(object$data[rn]))
    if (!is.null(rn) && length(rn) == 1L && rn %in% names(object$data)) return(object$data[[rn]])
  }
  mf <- try(stats::model.frame(object$engine_fit %||% object), silent = TRUE)
  if (!inherits(mf, "try-error") && ncol(mf)) return(stats::model.response(mf))
  NULL
}

.package_version_safe <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) return(NA_character_)
  as.character(utils::packageVersion(pkg))
}

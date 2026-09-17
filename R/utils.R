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

# --------------------------------------------------------------------------
# Shared internal helpers
# --------------------------------------------------------------------------

# Name of the predictor a `specs` argument refers to.
#
# `as.character()` on a two-sided formula returns one element per deparsed
# term ("~", LHS, RHS), so `as.character(~ treatment)[1L]` is "~" and never the
# column name. Both a formula and a plain character string are accepted.
.spec_var <- function(specs) {
  if (is.null(specs)) return(NULL)
  if (inherits(specs, "formula")) {
    v <- all.vars(specs)
    return(if (length(v)) v[1L] else NULL)
  }
  if (is.character(specs)) {
    s <- specs[nzchar(specs) & !is.na(specs)]
    return(if (length(s)) s[1L] else NULL)
  }
  txt <- try(as.character(specs), silent = TRUE)
  if (!inherits(txt, "try-error") && length(txt)) return(txt[1L])
  NULL
}

# Evaluate `expr` under a private seed and restore the caller's RNG state.
#
# Calling set.seed() without restoring .Random.seed makes every subsequent
# draw in the user's session depend on the package seed. In a simulation loop
# that passes a fixed seed, that silently collapses all replicates onto one
# realisation.
.with_seed <- function(seed, expr) {
  if (is.null(seed)) return(force(expr))
  had <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  before <- if (had) get(".Random.seed", envir = .GlobalEnv) else NULL
  on.exit({
    if (had) {
      assign(".Random.seed", before, envir = .GlobalEnv)
    } else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
      rm(".Random.seed", envir = .GlobalEnv)
    }
  }, add = TRUE)
  set.seed(seed)
  force(expr)
}

# Run a model fit while collecting the warnings the backend emits.
.fit_with_warnings <- function(expr) {
  ws <- character(0)
  val <- withCallingHandlers(
    force(expr),
    warning = function(w) {
      ws <<- c(ws, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  list(fit = val, warnings = ws)
}

# Warnings that indicate the optimiser stopped before reaching a solution.
.CONVERGENCE_PATTERN <- paste(
  "converg", "did not converge", "iteration", "iterations", "maxiter",
  "non-positive-definite", "false convergence", "singular",
  "boundary", "not obtained", "failed to converge",
  sep = "|"
)

.suspicious_warnings <- function(warnings) {
  warnings <- warnings[!is.na(warnings) & nzchar(warnings)]
  if (!length(warnings)) return(character(0))
  warnings[grepl(.CONVERGENCE_PATTERN, warnings, ignore.case = TRUE)]
}

# VGAM reports an iteration-limit stop through the @iter slot rather than a
# non-zero exit code, so the count must be compared with the ceiling.
.vgam_hit_iteration_limit <- function(fit) {
  if (!methods::is(fit, "vglm")) return(FALSE)
  it <- try(fit@iter, silent = TRUE)
  if (inherits(it, "try-error") || !length(it)) return(FALSE)
  ceiling <- try(fit@control$maxit, silent = TRUE)
  if (inherits(ceiling, "try-error") || is.null(ceiling)) ceiling <- 30L
  isTRUE(it >= ceiling)
}

# Named vector of fixed-effect coefficients, uniform across engines.
#
# stats::coef() returns a list indexed by grouping factor for mixed fits, so a
# positional or as.numeric() read of it yields nothing usable. Returns NULL
# when no named fixed-effect vector can be obtained.
.reg_coef <- function(fit) {
  if (inherits(fit, "glmmTMB") && requireNamespace("glmmTMB", quietly = TRUE)) {
    b <- try(glmmTMB::fixef(fit)$cond, silent = TRUE)
    if (!inherits(b, "try-error") && length(b)) return(b)
  }
  if (inherits(fit, "merMod") && requireNamespace("lme4", quietly = TRUE)) {
    b <- try(lme4::fixef(fit), silent = TRUE)
    if (!inherits(b, "try-error") && length(b)) return(b)
  }
  cf <- try(stats::coef(fit), silent = TRUE)
  if (inherits(cf, "try-error")) return(NULL)
  if (is.list(cf) || is.null(names(cf))) return(NULL)
  if (!length(cf)) return(NULL)
  cf
}

# Fixed-effect covariance matrix, uniform across engines.
.reg_vcov <- function(fit) {
  if (inherits(fit, "glmmTMB") && requireNamespace("glmmTMB", quietly = TRUE)) {
    v <- try(stats::vcov(fit)$cond, silent = TRUE)
    if (!inherits(v, "try-error") && is.matrix(v)) return(v)
  }
  if (inherits(fit, "merMod")) {
    v <- try(as.matrix(stats::vcov(fit)), silent = TRUE)
    if (!inherits(v, "try-error") && is.matrix(v)) return(v)
  }
  v <- try(stats::vcov(fit), silent = TRUE)
  if (inherits(v, "try-error") || !is.matrix(v)) return(NULL)
  v
}

# Locate a quadratic term by name rather than by position, so the extraction
# survives interaction terms added by `by` or by a random-effect formula.
.quadratic_index <- function(coef_names, x) {
  esc <- gsub("([][{}()+*^$|\\\\?.])", "\\\\\\1", x)
  pats <- c(
    sprintf("^I\\(%s\\^2\\)$", esc),
    sprintf("^I\\(%s \\^ 2\\)$", esc),
    sprintf("^%s\\^2$", esc)
  )
  for (p in pats) {
    hit <- grep(p, coef_names)
    if (length(hit)) return(hit[1L])
  }
  NA_integer_
}

# Accept either an agri_response object or a bare response vector.
#
# Several exported functions take an argument named `response` but require the
# object produced by agri_response(). The name invites passing the vector, and
# the resulting error gave no hint that a promotion was possible. A vector is
# now promoted to a single-column response characterization.
.coerce_response <- function(x, arg = "response") {
  if (inherits(x, "agri_response")) return(x)
  if (is.null(x)) {
    .agri_abort(sprintf("'%s' is NULL. Supply an agri_response object or a response vector.", arg))
  }
  if (is.matrix(x) && ncol(x) > 1L) {
    df <- as.data.frame(x)
    return(agri_response(df, response = names(df)))
  }
  if (is.atomic(x) || is.factor(x)) {
    df <- data.frame(.response_value = x, check.names = FALSE)
    return(agri_response(df, response = ".response_value"))
  }
  .agri_abort(sprintf(
    "'%s' must be an agri_response object from agri_response() or a response vector; received class '%s'. A bare vector is promoted automatically, so pass the column itself when you do not need an explicit characterization.",
    arg, paste(class(x), collapse = "/")))
}


.regression_formula <- function(response, x, model) {
  y <- .bt(response); xx <- .bt(x)
  rhs <- switch(model,
    linear = xx,
    quadratic = sprintf("%s + I(%s^2)", xx, xx),
    cubic = sprintf("%s + I(%s^2) + I(%s^3)", xx, xx, xx),
    .agri_abort(sprintf("No polynomial formula for model '%s'.", model))
  )
  stats::as.formula(sprintf("%s ~ %s", y, rhs))
}

.nls_start <- function(data, response, x, model) {
  xx <- data[[x]]; yy <- data[[response]]
  xmin <- min(xx, na.rm = TRUE); xmax <- max(xx, na.rm = TRUE)
  ymin <- min(yy, na.rm = TRUE); ymax <- max(yy, na.rm = TRUE)
  switch(model,
    mitscherlich = list(a = ymax, b = max(ymax - ymin, .Machine$double.eps), c = 1 / max(xmax - xmin, 1)),
    michaelis_menten = list(Vmax = ymax, Km = stats::median(xx[xx > 0], na.rm = TRUE)),
    logistic = list(Asym = ymax, xmid = stats::median(xx, na.rm = TRUE), scal = max(stats::sd(xx, na.rm = TRUE), sqrt(.Machine$double.eps), na.rm = TRUE)),
    gompertz = list(Asym = ymax, b = 2, c = 1 / max(xmax - xmin, 1)),
    weibull = list(Asym = ymax, b = 1, c = 1 / max(xmax, 1)),
    linear_plateau = list(a = ymin, b = (ymax - ymin) / max(xmax - xmin, 1), xp = stats::median(xx, na.rm = TRUE)),
    quadratic_plateau = list(a = ymin, b = (ymax - ymin) / max(xmax - xmin, 1), c = -abs(ymax - ymin) / max((xmax - xmin)^2, 1), xp = stats::median(xx, na.rm = TRUE)),
    list()
  )
}

.nls_formula <- function(response, x, model) {
  y <- .bt(response); xx <- .bt(x)
  txt <- switch(model,
    mitscherlich = sprintf("%s ~ a - b * exp(-c * %s)", y, xx),
    michaelis_menten = sprintf("%s ~ Vmax * %s / (Km + %s)", y, xx, xx),
    logistic = sprintf("%s ~ Asym / (1 + exp((xmid - %s) / scal))", y, xx),
    gompertz = sprintf("%s ~ Asym * exp(-b * exp(-c * %s))", y, xx),
    weibull = sprintf("%s ~ Asym * (1 - exp(-(%s / b)^c))", y, xx),
    linear_plateau = sprintf("%s ~ a + b * pmin(%s, xp)", y, xx),
    quadratic_plateau = sprintf("%s ~ a + b * pmin(%s, xp) + c * pmin(%s, xp)^2", y, xx, xx),
    .agri_abort(sprintf("Unknown nonlinear regression model '%s'.", model))
  )
  stats::as.formula(txt)
}

.numeric_delta_se <- function(fun, cf, vc) {
  if (inherits(vc, "try-error") || !is.matrix(vc)) return(NA_real_)
  nms <- intersect(names(cf), rownames(vc))
  if (!length(nms)) return(NA_real_)
  theta <- cf[nms]
  g <- numeric(length(theta)); names(g) <- nms
  for (j in seq_along(theta)) {
    h <- sqrt(.Machine$double.eps) * (abs(theta[j]) + 1)
    hi <- lo <- theta; hi[j] <- hi[j] + h; lo[j] <- lo[j] - h
    fhi <- try(fun(hi), silent = TRUE); flo <- try(fun(lo), silent = TRUE)
    if (inherits(fhi, "try-error") || inherits(flo, "try-error") || !is.finite(fhi) || !is.finite(flo)) return(NA_real_)
    g[j] <- (fhi - flo) / (2 * h)
  }
  V <- vc[nms, nms, drop = FALSE]
  vv <- as.numeric(t(g) %*% V %*% g)
  if (is.finite(vv) && vv >= 0) sqrt(vv) else NA_real_
}

.regression_targets <- function(fit, model, data, x, level = 0.95, by = NULL) {
  # Read fixed effects through the engine-uniform extractor. stats::coef() on a
  # glmmTMB fit returns a list, and unlist()ing it yields the random-effect
  # entries ("block.(Intercept)1", "block.dose1", ...) rather than the fixed
  # coefficients, so a positional read produced a meaningless target.
  cf <- .reg_coef(fit)
  if (is.null(cf) || !length(cf)) return(NULL)
  vc <- .reg_vcov(fit)
  z <- stats::qnorm(1 - (1 - level) / 2)
  nm <- names(cf)

  make_row <- function(target, estimate, se = NA_real_, group = NULL) {
    out <- data.frame(target = target, estimate = as.numeric(estimate), SE = as.numeric(se),
                      lower = if (is.finite(se)) estimate - z * se else NA_real_,
                      upper = if (is.finite(se)) estimate + z * se else NA_real_,
                      level = level, row.names = NULL)
    if (!is.null(group)) out$group <- as.character(group)
    out
  }
  add_fun <- function(target, fun, group = NULL) {
    est <- try(fun(cf), silent = TRUE)
    if (inherits(est, "try-error") || length(est) != 1L || !is.finite(est)) return(NULL)
    se <- .numeric_delta_se(fun, cf, vc)
    make_row(target, est, se, group)
  }

  # Terms are located by name, never by position: a `by` interaction and a block
  # term both shift positions, and names are the only stable anchor.
  idx_lin <- match(x, nm)
  idx_qua <- .quadratic_index(nm, x)
  qua_name <- if (is.na(idx_qua)) NA_character_ else nm[idx_qua]

  # One coefficient-index set per group of `by`; a single set otherwise.
  # Each set lists the positions that must be SUMMED to obtain that group's
  # linear and quadratic coefficients, so the delta method still runs on the
  # full covariance matrix.
  sets <- list(list(group = NULL,
                    lin = if (is.na(idx_lin)) integer(0) else idx_lin,
                    qua = if (is.na(idx_qua)) integer(0) else idx_qua))
  if (!is.null(by) && length(by) && by %in% names(data) && !is.na(qua_name)) {
    levs <- if (is.factor(data[[by]])) levels(data[[by]]) else sort(unique(as.character(data[[by]])))
    sets <- lapply(levs, function(g) {
      i_lin <- idx_lin
      i_qua <- idx_qua
      # The reference level carries no interaction term; every other level
      # adds its interaction coefficient to the base term.
      add <- function(base_name, base_idx) {
        cand <- paste0(base_name, ":", by, g)
        hit <- match(cand, nm, nomatch = 0L)
        if (hit > 0L) c(base_idx, hit) else base_idx
      }
      list(group = g,
           lin = add(x, if (is.na(idx_lin)) integer(0) else idx_lin),
           qua = add(qua_name, idx_qua))
    })
  }

  sum_at <- function(th, idx) {
    if (!length(idx) || anyNA(idx)) return(NA_real_)
    sum(th[idx])
  }

  rows <- list()
  for (st in sets) {
    grp <- st$group
    if (!length(st$lin) || !length(st$qua)) next
    if (model == "quadratic") {
      rr <- add_fun("x_optimum", function(th) {
        b1 <- sum_at(th, st$lin); b2 <- sum_at(th, st$qua)
        if (!is.finite(b1) || !is.finite(b2) || b2 == 0) return(NA_real_)
        -b1 / (2 * b2)
      }, grp)
      if (!is.null(rr)) rows[[length(rows) + 1L]] <- rr
      rr <- add_fun("x_plateau_response", function(th) {
        b1 <- sum_at(th, st$lin); b2 <- sum_at(th, st$qua); b0 <- th[["(Intercept)"]]
        xo <- -b1 / (2 * b2)
        b0 + b1 * xo + b2 * xo^2
      }, grp)
      if (!is.null(rr)) rows[[length(rows) + 1L]] <- rr
    }
  }
  # The nonlinear models below are parameterised directly, not by polynomial
  # coefficients, so they use the whole fitted vector and ignore `by`.
  if (is.null(by)) {
    add_plain <- function(target, fun) {
      r <- add_fun(target, fun, NULL)
      if (!is.null(r)) rows[[length(rows) + 1L]] <<- r
    }
    if (model == "linear_plateau") {
      add_plain("breakpoint", function(th) th[["xp"]])
      add_plain("plateau", function(th) th[["a"]] + th[["b"]] * th[["xp"]])
    }
    if (model == "quadratic_plateau") {
      add_plain("breakpoint", function(th) th[["xp"]])
      add_plain("plateau", function(th) th[["a"]] + th[["b"]] * th[["xp"]] + th[["c"]] * th[["xp"]]^2)
    }
    ps <- c(0.10, 0.50, 0.90)
    if (model == "logistic") {
      for (pp in ps) add_plain(sprintf("ED%d", round(100 * pp)), function(th) th[["xmid"]] - th[["scal"]] * log(1 / pp - 1))
      add_plain("asymptote", function(th) th[["Asym"]])
    }
    if (model == "gompertz") {
      for (pp in ps) add_plain(sprintf("ED%d", round(100 * pp)), function(th) -log((-log(pp)) / th[["b"]]) / th[["c"]])
      add_plain("asymptote", function(th) th[["Asym"]])
    }
    if (model == "weibull") {
      for (pp in ps) add_plain(sprintf("ED%d", round(100 * pp)), function(th) th[["b"]] * (-log(1 - pp))^(1 / th[["c"]]))
      add_plain("asymptote", function(th) th[["Asym"]])
    }
    if (model == "michaelis_menten") {
      for (pp in ps) add_plain(sprintf("ED%d", round(100 * pp)), function(th) pp * th[["Km"]] / (1 - pp))
      add_plain("asymptote", function(th) th[["Vmax"]])
    }
    if (model == "mitscherlich") {
      for (pp in ps) add_plain(sprintf("ED%d_gain", round(100 * pp)), function(th) -log(1 - pp) / th[["c"]])
      add_plain("asymptote", function(th) th[["a"]])
    }
  }
  rows <- Filter(Negate(is.null), rows)
  if (!length(rows)) return(NULL)
  do.call(rbind, rows)
}

#' Quantitative-treatment and dose-response regression
#' @export
agri_regression <- function(data, response, x,
                            model = c("linear", "quadratic", "cubic", "linear_plateau",
                                      "quadratic_plateau", "mitscherlich", "michaelis_menten",
                                      "logistic", "gompertz", "weibull", "gam", "vgam"),
                            design = NULL, family = "gaussian", engine = "auto",
                            by = NULL, start = NULL, weights = NULL, ...) {
  model <- match.arg(model)
  stopifnot(is.data.frame(data))
  response <- as.character(response)[1L]
  x <- as.character(x)[1L]
  .assert_columns(data, c(response, x, by), "regression")
  if (!is.numeric(data[[x]])) .agri_abort("Quantitative-treatment regression requires a numeric predictor. Convert to factor explicitly only when mean comparisons are scientifically intended.")

  if (model %in% c("linear", "quadratic", "cubic")) {
    form <- .regression_formula(response, x, model)
    if (!is.null(by)) {
      base_rhs <- paste(deparse(form[[3L]]), collapse = "")
      form <- stats::as.formula(sprintf("%s ~ (%s) * %s", .bt(response), base_rhs, .bt(by)))
    }
    if (!is.null(design)) {
      # Preserve the random structure while replacing the design fixed component by the quantitative regression.
      form <- .as_formula(response, paste(deparse(form[[3L]]), collapse = ""), design$random_terms)
      fit <- agri_model(data = data, response = response, design = design, formula = form,
                        family = family, engine = engine, ...)
      targets <- if (family == "gaussian") .regression_targets(fit$engine_fit, model, data, x, by = by) else NULL
      out <- list(model = model, engine = fit$engine, fit = fit$engine_fit,
                  agri_model = fit, data = data, response = response, x = x,
                  targets = targets, family = family,
                  note = .regression_targets_note(model, targets, family),
                  convergence = fit$convergence, warnings = fit$warnings)
      class(out) <- "agri_regression"
      return(out)
    }
    am <- NULL
    if (family == "gaussian") {
      lm_args <- list(formula = form, data = data)
      if (!is.null(weights)) lm_args$weights <- weights
      fw <- .fit_with_warnings(do.call(stats::lm, lm_args))
      fit <- fw$fit
      eng <- "lm"
    } else {
      am <- agri_model(data = data, response = response, formula = form,
                       family = family, engine = engine, ...)
      fit <- am$engine_fit; eng <- am$engine
      fw <- list(fit = fit, warnings = am$warnings %||% character(0))
    }
    tg <- .regression_targets(fit, model, data, x, by = by)
    out <- list(model = model, engine = eng, fit = fit, data = data,
                response = response, x = x,
                targets = tg, family = family,
                note = .regression_targets_note(model, tg, family),
                convergence = .regression_convergence(eng, fit, fw$warnings, am),
                warnings = fw$warnings)
    class(out) <- "agri_regression"
    return(out)
  }

  if (!is.null(design) && .design_has_random(design)) {
    .agri_abort(paste0(
      "Nonlinear fixed-form regression with random experimental-unit effects is not silently approximated. ",
      "Use a polynomial GLMM, a scientifically specified nonlinear mixed model, or a GAMM-compatible backend."
    ))
  }

  if (model == "gam") {
    .require_pkg("mgcv", "generalized additive regression")
    form <- stats::as.formula(sprintf("%s ~ s(%s)", .bt(response), .bt(x)))
    fam <- if (family == "gaussian") stats::gaussian() else .make_stats_family(family)
    fit <- mgcv::gam(form, data = data, family = fam, method = "REML", ...)
    out <- list(model = model, engine = "mgcv", fit = fit, data = data,
                response = response, x = x, targets = NULL, family = family)
    class(out) <- "agri_regression"
    return(out)
  }

  if (model == "vgam") {
    .require_pkg("VGAM", "vector generalized additive regression")
    if (identical(family, "gaussian")) .agri_abort("For model='vgam', specify a registered VGAM family ID.")
    form <- stats::as.formula(sprintf("%s ~ VGAM::sm.bs(%s)", .bt(response), .bt(x)))
    am <- agri_model(data = data, response = response, formula = form,
                     family = family, engine = "VGAM", additive = TRUE, ...)
    out <- list(model = model, engine = "VGAM", fit = am$engine_fit, agri_model = am,
                data = data, response = response, x = x, targets = NULL, family = family)
    class(out) <- "agri_regression"
    return(out)
  }

  form <- .nls_formula(response, x, model)
  st <- start %||% .nls_start(data, response, x, model)
  nls_args <- list(formula = form, data = data, start = st)
  if (!is.null(weights)) nls_args$weights <- weights
  if (requireNamespace("minpack.lm", quietly = TRUE)) {
    fw <- .fit_with_warnings(do.call(minpack.lm::nlsLM, c(nls_args, list(...))))
    eng <- "minpack.lm"
  } else {
    fw <- .fit_with_warnings(do.call(stats::nls, c(nls_args, list(...))))
    eng <- "nls"
  }
  fit <- fw$fit
  conv <- .regression_convergence(eng, fit, fw$warnings, NULL)
  # A non-linear fit that stopped at the iteration ceiling still returns a
  # parameter vector, and the derived targets then look plausible. Say so.
  if (!isTRUE(conv$ok)) {
    .agri_warn(sprintf(
      "Non-linear fit for model '%s' did not converge (%s); the targets below are not reliable.",
      model, conv$message %||% "reason unavailable"))
  }
  out <- list(model = model, engine = eng, fit = fit, data = data,
              response = response, x = x,
              targets = .regression_targets(fit, model, data, x, by = by), family = family,
              note = NULL,
              convergence = conv, warnings = fw$warnings)
  out$note <- .regression_targets_note(model, out$targets, family)
  class(out) <- "agri_regression"
  out
}

# Explain an absent target table instead of returning NULL in silence. A cubic
# curve has no single notable point, so an empty table is correct, but the
# user needs to be told why rather than left to wonder.
.regression_targets_note <- function(model, targets, family) {
  if (!is.null(targets) && nrow(targets)) return(NULL)
  if (!identical(family, "gaussian")) {
    return("Targets are reported only for Gaussian fits; this model was fitted with a non-Gaussian family.")
  }
  if (identical(model, "cubic")) {
    return("A cubic curve has no unique notable point, so no agronomic target is reported. Inspect the fitted coefficients, or use agri_compare_curves() to compare shapes between groups.")
  }
  if (identical(model, "linear")) {
    return("A straight line has no optimum, breakpoint or plateau, so no agronomic target is reported.")
  }
  "No agronomic target could be derived from the fitted coefficients; inspect coef(fit)."
}

# Convergence verdict for a regression fit, uniform across the engines used
# here. Optimisers report a stop either through a return code, through a
# warning, or through the iteration counter reaching its ceiling.
.regression_convergence <- function(engine, fit, warnings = character(0), am = NULL) {
  if (!is.null(am) && is.list(am$convergence)) {
    out <- am$convergence
    sus <- .suspicious_warnings(warnings)
    if (length(sus)) {
      out$ok <- FALSE
      out$message <- sus[1L]
    }
    return(out)
  }
  sus <- .suspicious_warnings(warnings)
  if (length(sus)) {
    return(list(ok = FALSE, code = 1L, message = sus[1L], engine = engine))
  }
  code <- try(fit$convInfo$isConv, silent = TRUE)
  if (!inherits(code, "try-error") && is.logical(code) && length(code)) {
    return(list(ok = isTRUE(code), code = if (isTRUE(code)) 0L else 1L,
                message = if (isTRUE(code)) NULL else "nls did not report convergence",
                engine = engine))
  }
  iter <- try(fit$convInfo$finIter, silent = TRUE)
  maxit <- try(fit$convInfo$finTol, silent = TRUE)
  list(ok = TRUE, code = 0L, message = NULL, engine = engine)
}

#' Compare quantitative response curves among groups
#'
#' For polynomial models, compares a common curve, a common-shape model with
#' group-specific levels, and a fully interacted group-specific curve while
#' preserving a declared mixed-model random structure. For supported nonlinear
#' Gaussian curves, compares a common curve against independently fitted
#' group-specific curves using the nested residual sum-of-squares decomposition.
#' @export
agri_compare_curves <- function(data, response, x, group,
                                model = c("linear", "quadratic", "cubic", "linear_plateau",
                                          "quadratic_plateau", "mitscherlich", "michaelis_menten",
                                          "logistic", "gompertz", "weibull"),
                                design = NULL, family = "gaussian", engine = "auto", ...) {
  model <- match.arg(model)
  response <- as.character(response)[1L]; x <- as.character(x)[1L]; group <- as.character(group)[1L]
  .assert_columns(data, c(response, x, group), "curve comparison")
  if (!is.numeric(data[[x]])) .agri_abort("Curve comparison requires a numeric quantitative predictor.")
  if (length(unique(stats::na.omit(data[[group]]))) < 2L) .agri_abort("Curve comparison requires at least two groups.")

  if (model %in% c("linear", "quadratic", "cubic")) {
    base <- .regression_formula(response, x, model)
    rhs <- paste(deparse(base[[3L]]), collapse = "")
    f_common <- stats::as.formula(sprintf("%s ~ %s", .bt(response), rhs))
    f_level <- stats::as.formula(sprintf("%s ~ (%s) + %s", .bt(response), rhs, .bt(group)))
    f_full <- stats::as.formula(sprintf("%s ~ (%s) * %s", .bt(response), rhs, .bt(group)))
    if (!is.null(design)) {
      f_common <- .as_formula(response, rhs, design$random_terms)
      f_level <- .as_formula(response, paste0("(", rhs, ") + ", .bt(group)), design$random_terms)
      f_full <- .as_formula(response, paste0("(", rhs, ") * ", .bt(group)), design$random_terms)
    }
    fit_one <- function(f) {
      if (is.null(design) && identical(family, "gaussian")) return(stats::lm(f, data = data))
      agri_model(data = data, response = response, design = design, formula = f,
                 family = family, engine = engine, ...)
    }
    common <- fit_one(f_common); level <- fit_one(f_level); full <- fit_one(f_full)
    raw_fit <- function(z) if (inherits(z, "agri_model")) z$engine_fit else z
    cmp <- function(a, b) {
      aa <- raw_fit(a); bb <- raw_fit(b)
      out <- if (inherits(aa, "glm")) try(stats::anova(aa, bb, test = "Chisq"), silent = TRUE) else try(stats::anova(aa, bb), silent = TRUE)
      if (inherits(out, "try-error")) out <- try(stats::anova(aa, bb), silent = TRUE)
      if (inherits(out, "try-error")) NULL else out
    }
    out <- list(
      model = model, family = family, group = group,
      common = common, common_shape = level, group_specific = full,
      tests = list(
        level_difference = cmp(common, level),
        shape_difference = cmp(level, full),
        overall_curve_difference = cmp(common, full)
      ),
      interpretation = c(
        level_difference = "Tests whether groups differ in level while sharing the same quantitative-response shape.",
        shape_difference = "Tests whether quantitative-response coefficients/shape differ among groups beyond level shifts.",
        overall_curve_difference = "Tests the common-curve model against fully group-specific curves."
      )
    )
    class(out) <- "agri_curve_comparison"
    return(out)
  }

  if (!identical(family, "gaussian")) .agri_abort("Nonlinear common-versus-group curve comparison is currently defined for Gaussian residual models only.")
  if (!is.null(design) && .design_has_random(design)) {
    .agri_abort("Nonlinear curve comparison with random experimental-unit effects requires a scientifically specified nonlinear mixed model and is not approximated silently.")
  }
  common <- agri_regression(data, response, x, model = model, family = "gaussian", ...)
  groups <- unique(stats::na.omit(data[[group]]))
  sep <- lapply(groups, function(g) {
    agri_regression(data[data[[group]] == g, , drop = FALSE], response, x,
                    model = model, family = "gaussian", ...)
  })
  names(sep) <- as.character(groups)
  rss_common <- sum(stats::residuals(common$fit)^2, na.rm = TRUE)
  rss_sep <- sum(vapply(sep, function(z) sum(stats::residuals(z$fit)^2, na.rm = TRUE), numeric(1)))
  df_common <- stats::df.residual(common$fit)
  df_sep <- sum(vapply(sep, function(z) stats::df.residual(z$fit), numeric(1)))
  numdf <- df_common - df_sep
  Fval <- if (is.finite(rss_sep) && rss_sep > 0 && numdf > 0 && df_sep > 0)
    ((rss_common - rss_sep) / numdf) / (rss_sep / df_sep) else NA_real_
  pval <- if (is.finite(Fval)) stats::pf(Fval, numdf, df_sep, lower.tail = FALSE) else NA_real_
  ptab <- do.call(rbind, lapply(names(sep), function(g) {
    cf <- stats::coef(sep[[g]]$fit)
    data.frame(group = g, parameter = names(cf), estimate = as.numeric(cf), row.names = NULL)
  }))
  out <- list(model = model, family = family, group = group, common = common,
              group_specific = sep,
              tests = list(overall_curve_difference = data.frame(F = Fval, df1 = numdf, df2 = df_sep, p.value = pval)),
              parameter_table = ptab,
              note = "The nonlinear Gaussian test compares a common curve with separately fitted group curves through the residual sum-of-squares decomposition; inspect convergence and residual assumptions in every group.")
  class(out) <- "agri_curve_comparison"
  out
}

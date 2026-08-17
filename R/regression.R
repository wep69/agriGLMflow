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

.regression_targets <- function(fit, model, data, x, level = 0.95) {
  cf <- try(stats::coef(fit), silent = TRUE)
  if (inherits(cf, "try-error")) return(NULL)
  if (is.list(cf) && !is.null(cf$cond)) cf <- cf$cond
  cf <- unlist(cf)
  vc <- try(stats::vcov(fit), silent = TRUE)
  if (is.list(vc) && !is.null(vc$cond)) vc <- vc$cond
  z <- stats::qnorm(1 - (1 - level) / 2)
  make_row <- function(target, estimate, se = NA_real_) {
    data.frame(target = target, estimate = as.numeric(estimate), SE = as.numeric(se),
               lower = if (is.finite(se)) estimate - z * se else NA_real_,
               upper = if (is.finite(se)) estimate + z * se else NA_real_,
               level = level, row.names = NULL)
  }
  add_fun <- function(target, fun) {
    est <- try(fun(cf), silent = TRUE)
    if (inherits(est, "try-error") || length(est) != 1L || !is.finite(est)) return(NULL)
    se <- .numeric_delta_se(fun, cf, vc)
    make_row(target, est, se)
  }
  rows <- list()

  if (model == "quadratic" && length(cf) >= 3L) {
    b1n <- names(cf)[2L]; b2n <- names(cf)[3L]
    rr <- add_fun("x_optimum", function(th) -th[[b1n]] / (2 * th[[b2n]]))
    if (!is.null(rr)) rows[[length(rows) + 1L]] <- rr
  }

  if (model == "linear_plateau") {
    rows[[length(rows) + 1L]] <- add_fun("breakpoint", function(th) th[["xp"]])
    rows[[length(rows) + 1L]] <- add_fun("plateau", function(th) th[["a"]] + th[["b"]] * th[["xp"]])
  }
  if (model == "quadratic_plateau") {
    rows[[length(rows) + 1L]] <- add_fun("breakpoint", function(th) th[["xp"]])
    rows[[length(rows) + 1L]] <- add_fun("plateau", function(th) th[["a"]] + th[["b"]] * th[["xp"]] + th[["c"]] * th[["xp"]]^2)
  }

  ps <- c(0.10, 0.50, 0.90)
  if (model == "logistic") {
    for (pp in ps) rows[[length(rows) + 1L]] <- add_fun(sprintf("ED%d", round(100 * pp)), function(th) th[["xmid"]] - th[["scal"]] * log(1 / pp - 1))
    rows[[length(rows) + 1L]] <- add_fun("asymptote", function(th) th[["Asym"]])
  }
  if (model == "gompertz") {
    for (pp in ps) rows[[length(rows) + 1L]] <- add_fun(sprintf("ED%d", round(100 * pp)), function(th) -log((-log(pp)) / th[["b"]]) / th[["c"]])
    rows[[length(rows) + 1L]] <- add_fun("asymptote", function(th) th[["Asym"]])
  }
  if (model == "weibull") {
    for (pp in ps) rows[[length(rows) + 1L]] <- add_fun(sprintf("ED%d", round(100 * pp)), function(th) th[["b"]] * (-log(1 - pp))^(1 / th[["c"]]))
    rows[[length(rows) + 1L]] <- add_fun("asymptote", function(th) th[["Asym"]])
  }
  if (model == "michaelis_menten") {
    for (pp in ps) rows[[length(rows) + 1L]] <- add_fun(sprintf("ED%d", round(100 * pp)), function(th) pp * th[["Km"]] / (1 - pp))
    rows[[length(rows) + 1L]] <- add_fun("asymptote", function(th) th[["Vmax"]])
  }
  if (model == "mitscherlich") {
    for (pp in ps) rows[[length(rows) + 1L]] <- add_fun(sprintf("ED%d_gain", round(100 * pp)), function(th) -log(1 - pp) / th[["c"]])
    rows[[length(rows) + 1L]] <- add_fun("asymptote", function(th) th[["a"]])
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
      targets <- if (family == "gaussian") .regression_targets(fit$engine_fit, model, data, x) else NULL
      out <- list(model = model, engine = fit$engine, fit = fit$engine_fit,
                  agri_model = fit, data = data, response = response, x = x,
                  targets = targets, family = family)
      class(out) <- "agri_regression"
      return(out)
    }
    if (family == "gaussian") {
      lm_args <- list(formula = form, data = data)
      if (!is.null(weights)) lm_args$weights <- weights
      fit <- do.call(stats::lm, lm_args)
      eng <- "lm"
    } else {
      am <- agri_model(data = data, response = response, formula = form,
                       family = family, engine = engine, ...)
      fit <- am$engine_fit; eng <- am$engine
    }
    out <- list(model = model, engine = eng, fit = fit, data = data,
                response = response, x = x,
                targets = .regression_targets(fit, model, data, x), family = family)
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
    fit <- do.call(minpack.lm::nlsLM, c(nls_args, list(...)))
    eng <- "minpack.lm"
  } else {
    fit <- do.call(stats::nls, c(nls_args, list(...)))
    eng <- "nls"
  }
  out <- list(model = model, engine = eng, fit = fit, data = data,
              response = response, x = x,
              targets = .regression_targets(fit, model, data, x), family = family)
  class(out) <- "agri_regression"
  out
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

.cluster_residual_diagnostic <- function(residuals, group) {
  ok <- is.finite(residuals) & !is.na(group)
  r <- residuals[ok]; g <- factor(group[ok])
  if (length(r) < 4L || nlevels(g) < 2L) return(list(status = "insufficient_data"))
  n_i <- as.numeric(table(g))
  if (any(n_i < 2L)) {
    # Singleton clusters do not contribute within-cluster variance but may still
    # be retained; require at least two clusters with replication.
    if (sum(n_i >= 2L) < 2L) return(list(status = "insufficient_replication"))
  }
  grand <- mean(r)
  means <- tapply(r, g, mean)
  ssb <- sum(n_i * (means - grand)^2)
  ssw <- sum(tapply(r, g, function(z) sum((z - mean(z))^2)))
  dfb <- nlevels(g) - 1L
  dfw <- length(r) - nlevels(g)
  msb <- if (dfb > 0) ssb / dfb else NA_real_
  msw <- if (dfw > 0) ssw / dfw else NA_real_
  n0 <- if (nlevels(g) > 1L) (sum(n_i) - sum(n_i^2) / sum(n_i)) / (nlevels(g) - 1L) else NA_real_
  icc <- if (is.finite(msb) && is.finite(msw) && is.finite(n0) && n0 > 1) {
    (msb - msw) / (msb + (n0 - 1) * msw)
  } else NA_real_
  Fval <- if (is.finite(msw) && msw > 0) msb / msw else NA_real_
  p <- if (is.finite(Fval) && dfb > 0 && dfw > 0) stats::pf(Fval, dfb, dfw, lower.tail = FALSE) else NA_real_
  list(status = "available", ICC_moment = icc, F = Fval, df1 = dfb, df2 = dfw,
       p.value = p, n_clusters = nlevels(g), harmonic_like_cluster_size = n0,
       note = "One-way moment diagnostic of residual clustering; use as a misspecification signal, not as a replacement for the declared experimental design.")
}

#' Unified model diagnostics
#' @export
agri_diagnose <- function(object, simulate = FALSE, nsim = 250L,
                          time = NULL, cluster = NULL, seed = 123, ...) {
  if (!inherits(object, "agri_model")) .agri_abort("'object' must be an agri_model.")
  fit <- object$engine_fit
  conv <- object$convergence
  messages <- conv$messages %||% character()

  pear <- .safe_residuals(fit, "pearson")
  rdf <- .safe_df_residual(fit)
  disp_ratio <- if (length(pear) && is.finite(rdf) && rdf > 0) sum(pear^2, na.rm = TRUE) / rdf else NA_real_
  disp_status <- if (!is.finite(disp_ratio)) "not_available" else if (disp_ratio > 1.5) "possible_overdispersion" else if (disp_ratio < 0.65) "possible_underdispersion" else "acceptable"
  if (disp_status != "acceptable" && disp_status != "not_available") messages <- c(messages, sprintf("Dispersion diagnostic: %s (ratio %.3f).", disp_status, disp_ratio))
  res_skew <- if (length(pear)) .skewness_basic(pear) else NA_real_
  res_kurt <- if (length(pear)) .kurtosis_basic(pear) else NA_real_
  res_shape_status <- if (!is.finite(res_skew) || !is.finite(res_kurt)) "not_available" else if (abs(res_skew) > 1 || abs(res_kurt) > 2) "review_shape" else "acceptable"
  if (res_shape_status == "review_shape") messages <- c(messages, sprintf("Residual shape warrants review (skewness %.3f; excess kurtosis %.3f).", res_skew, res_kurt))

  y <- .response_vector(object)
  pred <- try(agri_predict(object, type = "response"), silent = TRUE)
  zero_obs <- if (is.numeric(y)) mean(y == 0, na.rm = TRUE) else NA_real_
  zero_note <- "not_available"
  expected_zero <- NA_real_
  zero_interval <- c(NA_real_, NA_real_)
  if (is.numeric(y) && object$family %in% c("poisson", "zip") && !inherits(pred, "try-error") && is.numeric(pred)) {
    mu <- as.numeric(pred)
    expected_zero <- mean(exp(-pmax(mu, 0)), na.rm = TRUE)
    zero_note <- if (is.finite(expected_zero) && zero_obs > expected_zero * 1.25) "more_zeros_than_poisson_expectation" else "compatible_with_poisson_zero_rate"
  }
  if (isTRUE(simulate) && is.numeric(y) && grepl("count", object$family_info$domain[1L])) {
    set.seed(seed)
    zs <- try(stats::simulate(fit, nsim = nsim), silent = TRUE)
    if (!inherits(zs, "try-error")) {
      zm <- as.matrix(zs)
      zfrac <- colMeans(zm == 0, na.rm = TRUE)
      expected_zero <- mean(zfrac, na.rm = TRUE)
      zero_interval <- stats::quantile(zfrac, c(0.025, 0.975), na.rm = TRUE, names = FALSE)
      zero_note <- if (is.finite(zero_obs) && zero_obs > zero_interval[2L]) "more_zeros_than_simulated_model" else if (is.finite(zero_obs) && zero_obs < zero_interval[1L]) "fewer_zeros_than_simulated_model" else "compatible_with_simulated_zero_rate"
    }
  }

  dharma <- NULL
  if (isTRUE(simulate) && object$engine %in% c("stats", "glmmTMB", "lme4", "GLMMadaptive") && requireNamespace("DHARMa", quietly = TRUE)) {
    set.seed(seed)
    dharma <- try(DHARMa::simulateResiduals(fit, n = nsim, plot = FALSE), silent = TRUE)
    if (inherits(dharma, "try-error")) {
      messages <- c(messages, "DHARMa simulation failed; native diagnostics retained.")
      dharma <- NULL
    }
  }

  random <- list(status = "not_applicable", near_zero = FALSE)
  if (object$engine %in% c("glmmTMB", "lme4", "GLMMadaptive")) {
    vc <- if (object$engine == "glmmTMB") try(glmmTMB::VarCorr(fit), silent = TRUE) else if (object$engine == "lme4") try(lme4::VarCorr(fit), silent = TRUE) else try(fit$D, silent = TRUE)
    if (!inherits(vc, "try-error")) {
      vals <- suppressWarnings(as.numeric(unlist(vc)))
      vals <- vals[is.finite(vals)]
      random <- list(status = if (length(vals)) "available" else "not_available",
                     near_zero = length(vals) && any(abs(vals) < 1e-8), values = vals)
      if (isTRUE(random$near_zero)) messages <- c(messages, "At least one random-effect variance/covariance component is near the boundary.")
    }
    if (object$engine == "lme4" && requireNamespace("lme4", quietly = TRUE)) {
      sing <- try(lme4::isSingular(fit, tol = 1e-5), silent = TRUE)
      if (!inherits(sing, "try-error") && isTRUE(sing)) {
        random$singular <- TRUE
        messages <- c(messages, "lme4 reports a singular random-effects fit.")
      }
    }
  }

  influence <- list(status = "not_available")
  if (inherits(fit, "glm")) {
    infl <- try(stats::influence.measures(fit), silent = TRUE)
    cd <- try(stats::cooks.distance(fit), silent = TRUE)
    if (!inherits(infl, "try-error")) {
      threshold <- if (nrow(object$data) > 0L) 4 / nrow(object$data) else NA_real_
      flagged <- if (!inherits(cd, "try-error") && is.finite(threshold)) which(cd > threshold) else integer()
      influence <- list(status = "available", object = infl,
                        cooks_distance = if (inherits(cd, "try-error")) NULL else as.numeric(cd),
                        cooks_threshold = threshold, flagged = flagged)
      if (length(flagged)) messages <- c(messages, sprintf("%d observation(s) exceed the conventional Cook's-distance screening threshold 4/n; investigate scientifically before any exclusion.", length(flagged)))
    }
  }

  dep <- list(temporal = list(status = "not_requested"), cluster = list(status = "not_requested"))
  if (!is.null(time)) {
    tname <- if (is.character(time)) time else paste(deparse(substitute(time)), collapse = "")
    if (tname %in% names(object$data) && length(pear)) {
      ord <- order(object$data[[tname]])
      ac <- try(stats::acf(pear[ord], plot = FALSE, na.action = stats::na.pass), silent = TRUE)
      if (inherits(ac, "try-error")) {
        dep$temporal <- list(status = "failed")
      } else {
        lag1 <- if (length(ac$acf) >= 2L) as.numeric(ac$acf[2L]) else NA_real_
        bound <- if (length(pear) > 0L) 1.96 / sqrt(length(pear)) else NA_real_
        dep$temporal <- list(status = "available", acf = ac, lag1 = lag1,
                             approximate_95_bound = bound, variable = tname)
        if (is.finite(lag1) && is.finite(bound) && abs(lag1) > bound) {
          messages <- c(messages, sprintf("Residual lag-1 autocorrelation for '%s' exceeds the approximate white-noise bound (r=%.3f; bound=%.3f).", tname, lag1, bound))
        }
      }
    }
  }
  if (!is.null(cluster)) {
    cname <- if (is.character(cluster)) cluster[1L] else paste(deparse(substitute(cluster)), collapse = "")
    if (cname %in% names(object$data) && length(pear) == nrow(object$data)) {
      dep$cluster <- .cluster_residual_diagnostic(pear, object$data[[cname]])
      dep$cluster$variable <- cname
      if (identical(dep$cluster$status, "available") && is.finite(dep$cluster$p.value) && dep$cluster$p.value < 0.05 && is.finite(dep$cluster$ICC_moment) && dep$cluster$ICC_moment > 0.05) {
        messages <- c(messages, sprintf("Residual clustering remains associated with '%s' (moment ICC %.3f; F-test p=%.4g).", cname, dep$cluster$ICC_moment, dep$cluster$p.value))
      }
    } else {
      dep$cluster <- list(status = "unavailable", variable = cname,
                          note = "Cluster variable was not found or residual length did not match the original data.")
    }
  }

  vgam_extra <- NULL
  if (object$engine == "VGAM") {
    vres <- try(stats::residuals(fit, type = "response"), silent = TRUE)
    vfit <- try(stats::fitted(fit), silent = TRUE)
    vgam_extra <- list(
      residuals_available = !inherits(vres, "try-error"),
      fitted_available = !inherits(vfit, "try-error"),
      simulation_method = "simulate.vlm when implemented by the selected VGAM family"
    )
  }

  gamlss_extra <- NULL
  if (object$engine == "gamlss") {
    rq <- try(stats::residuals(fit, type = "quantile"), silent = TRUE)
    if (inherits(rq, "try-error")) rq <- try(stats::residuals(fit), silent = TRUE)
    gamlss_extra <- list(randomized_quantile_residuals = if (inherits(rq, "try-error")) NULL else as.numeric(rq))
  }

  serious <- !isTRUE(conv$ok) || disp_status %in% c("possible_overdispersion", "possible_underdispersion")
  overall <- if (serious) "problem" else if (length(messages)) "review" else "acceptable"

  out <- list(
    overall = overall,
    convergence = list(status = if (isTRUE(conv$ok)) "acceptable" else "problem", details = conv),
    dispersion = list(status = disp_status, ratio = disp_ratio, pearson_residuals = pear),
    zeros = list(status = zero_note, observed_fraction = zero_obs,
                 expected_fraction = expected_zero, simulated_interval = zero_interval),
    residuals = list(pearson = pear, skewness = res_skew, excess_kurtosis = res_kurt, shape_status = res_shape_status),
    random = random,
    influence = influence,
    dependence = dep,
    DHARMa = dharma,
    VGAM = vgam_extra,
    GAMLSS = gamlss_extra,
    messages = unique(messages),
    model = object
  )
  class(out) <- "agri_diagnostics"
  out
}

#' Extract convergence diagnostics
#' @export
agri_check_convergence <- function(object, ...) agri_diagnose(object, ...)$convergence
#' Extract dispersion diagnostics
#' @export
agri_check_dispersion <- function(object, ...) agri_diagnose(object, ...)$dispersion
#' Extract zero diagnostics
#' @export
agri_check_zeros <- function(object, ...) agri_diagnose(object, ...)$zeros
#' Extract residual diagnostics
#' @export
agri_check_residuals <- function(object, ...) agri_diagnose(object, ...)$residuals
#' Extract random-effect diagnostics
#' @export
agri_check_random <- function(object, ...) agri_diagnose(object, ...)$random
#' Extract influence diagnostics
#' @export
agri_check_influence <- function(object, ...) agri_diagnose(object, ...)$influence
#' Extract dependence diagnostics
#' @export
agri_check_dependence <- function(object, ...) agri_diagnose(object, ...)$dependence

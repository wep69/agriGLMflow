.gg_required <- function() .require_pkg("ggplot2", "agriGLMflow graphics")

#' Plot raw agricultural data
#' @export
agri_plot_data <- function(data, response, treatment = NULL,
                           type = c("auto", "points", "boxplot", "violin", "count", "time"),
                           time = NULL, group = NULL, ...) {
  .gg_required()
  type <- match.arg(type)
  response <- as.character(response)[1L]
  .assert_columns(data, c(response, treatment, time, group), "plot data")
  y <- data[[response]]
  if (type == "auto") {
    type <- if (.is_count_vector(y)) "count" else if (!is.null(treatment)) "boxplot" else "points"
  }
  if (type == "count") {
    return(ggplot2::ggplot(data, ggplot2::aes(x = .data[[response]])) +
             ggplot2::geom_bar() + ggplot2::labs(x = response, y = "Frequency"))
  }
  if (type == "time") {
    if (is.null(time)) .agri_abort("Provide 'time' for type='time'.")
    aes <- ggplot2::aes(x = .data[[time]], y = .data[[response]], group = if (!is.null(group)) .data[[group]] else 1)
    return(ggplot2::ggplot(data, aes) + ggplot2::geom_line(alpha = 0.5) + ggplot2::geom_point())
  }
  if (is.null(treatment)) {
    return(ggplot2::ggplot(data, ggplot2::aes(x = seq_along(.data[[response]]), y = .data[[response]])) +
             ggplot2::geom_point() + ggplot2::labs(x = "Observation", y = response))
  }
  p <- ggplot2::ggplot(data, ggplot2::aes(x = .data[[treatment]], y = .data[[response]]))
  if (type == "violin") p <- p + ggplot2::geom_violin(trim = FALSE)
  if (type == "boxplot") p <- p + ggplot2::geom_boxplot(outlier.shape = NA)
  p + ggplot2::geom_jitter(width = 0.08, height = 0, alpha = 0.65) + ggplot2::labs(x = treatment, y = response)
}

#' Plot observed versus fitted values
#' @export
agri_plot_fit <- function(object, ...) {
  .gg_required()
  if (!inherits(object, "agri_model")) .agri_abort("'object' must be an agri_model.")
  y <- .response_vector(object)
  pr <- agri_predict(object, type = "response")
  if (is.matrix(pr) || is.data.frame(pr)) {
    .agri_abort("Observed-versus-fitted scatter is not a single-scale plot for multivariate/category-probability VGAM models; use type='means' or type='distribution'.")
  }
  d <- data.frame(observed = as.numeric(y), fitted = as.numeric(pr))
  ggplot2::ggplot(d, ggplot2::aes(x = fitted, y = observed)) +
    ggplot2::geom_point() + ggplot2::geom_abline(slope = 1, intercept = 0, linetype = 2) +
    ggplot2::labs(x = "Fitted", y = "Observed")
}

#' Plot diagnostic panels
#' @export
agri_plot_diagnostics <- function(object, panel = c("residual_fitted", "qq", "rootogram", "zero", "calibration"), ...) {
  .gg_required()
  panel <- match.arg(panel)
  dg <- agri_diagnose(object)
  r <- dg$residuals$pearson
  if (panel == "residual_fitted") {
    f <- try(as.numeric(agri_predict(object, type = "response")), silent = TRUE)
    if (inherits(f, "try-error") || !length(r) || length(f) != length(r)) .agri_abort("Residual-versus-fitted plot is unavailable for this model.")
    d <- data.frame(fitted = f, residual = r)
    return(ggplot2::ggplot(d, ggplot2::aes(fitted, residual)) + ggplot2::geom_point() +
             ggplot2::geom_hline(yintercept = 0, linetype = 2) +
             ggplot2::labs(x = "Fitted", y = "Pearson residual"))
  }
  if (panel == "qq") {
    if (!length(r)) .agri_abort("Residuals unavailable for QQ plot.")
    d <- data.frame(residual = r)
    return(ggplot2::ggplot(d, ggplot2::aes(sample = residual)) +
             ggplot2::stat_qq() + ggplot2::stat_qq_line() + ggplot2::labs(x = "Theoretical quantile", y = "Residual quantile"))
  }
  y <- .response_vector(object)
  if (panel == "zero") {
    if (!is.numeric(y)) .agri_abort("Zero diagnostic plot requires a numeric response.")
    sims <- try(agri_simulate(object, nsim = 250L, seed = 123), silent = TRUE)
    expected_zero <- NA_real_
    if (!inherits(sims, "try-error")) expected_zero <- mean(as.matrix(sims) == 0, na.rm = TRUE)
    if (!is.finite(expected_zero) && object$family == "poisson") expected_zero <- mean(exp(-as.numeric(agri_predict(object))), na.rm = TRUE)
    d <- data.frame(component = c("Observed zeros", "Model-expected zeros"),
                    fraction = c(dg$zeros$observed_fraction, expected_zero))
    return(ggplot2::ggplot(d, ggplot2::aes(component, fraction)) + ggplot2::geom_col() +
             ggplot2::labs(x = NULL, y = "Zero fraction"))
  }
  if (panel == "rootogram") {
    if (!.is_count_vector(y)) .agri_abort("Rootogram is intended for count responses.")
    sims <- try(agri_simulate(object, nsim = 250L, seed = 123), silent = TRUE)
    ymax <- max(y, na.rm = TRUE)
    if (!inherits(sims, "try-error")) {
      sm <- as.matrix(sims); ymax <- max(ymax, sm, na.rm = TRUE)
      support <- 0:ceiling(ymax)
      expected <- vapply(support, function(k) mean(colSums(sm == k, na.rm = TRUE)), numeric(1))
    } else if (object$family == "poisson") {
      mu <- as.numeric(agri_predict(object, type = "response")); support <- 0:ceiling(ymax)
      expected <- vapply(support, function(k) sum(stats::dpois(k, lambda = mu)), numeric(1))
    } else {
      .agri_abort("A fitted-frequency rootogram requires simulation support for this family/backend.")
    }
    observed <- vapply(support, function(k) sum(y == k, na.rm = TRUE), numeric(1))
    d <- data.frame(count = support, observed = observed, expected = expected,
                    root_difference = sqrt(observed) - sqrt(pmax(expected, 0)))
    return(ggplot2::ggplot(d, ggplot2::aes(count, root_difference)) + ggplot2::geom_col() +
             ggplot2::geom_hline(yintercept = 0, linetype = 2) +
             ggplot2::labs(y = "sqrt(Observed) - sqrt(Expected)", x = "Count"))
  }
  if (panel == "calibration") {
    pr <- agri_predict(object, type = "response")
    if (is.matrix(pr)) {
      cats <- colnames(pr) %||% as.character(seq_len(ncol(pr)))
      predicted <- colMeans(pr, na.rm = TRUE)
      observed <- rep(NA_real_, length(cats))
      if (is.factor(y)) observed <- as.numeric(prop.table(table(factor(y, levels = cats))))
      if (is.matrix(y) && ncol(y) == length(cats)) {
        if (all(abs(rowSums(y, na.rm = TRUE) - 1) < 1e-7, na.rm = TRUE)) observed <- colMeans(y, na.rm = TRUE)
        else observed <- colSums(y, na.rm = TRUE) / sum(y, na.rm = TRUE)
      }
      d <- rbind(data.frame(category = cats, source = "Predicted", probability = predicted),
                 data.frame(category = cats, source = "Observed", probability = observed))
      return(ggplot2::ggplot(d, ggplot2::aes(category, probability, fill = source)) +
               ggplot2::geom_col(position = "dodge") + ggplot2::labs(x = "Outcome", y = "Probability", fill = NULL))
    }
    d <- data.frame(predicted = as.numeric(pr), observed = as.numeric(y))
    d$bin <- cut(d$predicted, breaks = unique(stats::quantile(d$predicted, probs = seq(0, 1, 0.1), na.rm = TRUE)), include.lowest = TRUE)
    cal <- stats::aggregate(cbind(predicted, observed) ~ bin, d, mean)
    return(ggplot2::ggplot(cal, ggplot2::aes(predicted, observed)) + ggplot2::geom_point() +
             ggplot2::geom_line() + ggplot2::geom_abline(slope = 1, intercept = 0, linetype = 2))
  }
}

#' Plot estimated means or category probabilities
#' @export
agri_plot_means <- function(object, specs, ...) {
  .gg_required()
  ph <- agri_means(object, specs = specs, ...)
  d <- ph$table
  if (object$engine == "VGAM") {
    return(ggplot2::ggplot(d, ggplot2::aes(x = .data[[specs]], y = estimate, group = outcome)) +
             ggplot2::geom_point(position = ggplot2::position_dodge(width = 0.25)) +
             ggplot2::geom_line(ggplot2::aes(group = outcome), position = ggplot2::position_dodge(width = 0.25)) +
             ggplot2::facet_wrap(~ outcome) + ggplot2::labs(y = "Standardized predicted probability/response"))
  }
  est <- intersect(c("emmean", "response", "prob", "rate", "estimate"), names(d))[1L]
  lo <- grep("lower", names(d), ignore.case = TRUE, value = TRUE)[1L]
  hi <- grep("upper", names(d), ignore.case = TRUE, value = TRUE)[1L]
  if (is.na(est) || !length(est)) .agri_abort("Could not identify the estimated-mean column.")
  p <- ggplot2::ggplot(d, ggplot2::aes(x = .data[[specs]], y = .data[[est]]))
  yraw <- .response_vector(object)
  if (length(specs) == 1L && specs %in% names(object$data) && is.numeric(yraw) && is.null(dim(yraw))) {
    raw <- data.frame(group = object$data[[specs]], observed = as.numeric(yraw))
    names(raw)[1L] <- specs
    p <- p + ggplot2::geom_jitter(data = raw, ggplot2::aes(x = .data[[specs]], y = observed),
                                  inherit.aes = FALSE, width = 0.07, height = 0, alpha = 0.45)
  }
  p <- p + ggplot2::geom_point()
  if (!is.na(lo) && !is.na(hi)) p <- p + ggplot2::geom_errorbar(ggplot2::aes(ymin = .data[[lo]], ymax = .data[[hi]]), width = 0.08)
  p + ggplot2::labs(y = "Estimated response")
}

#' Plot model contrasts
#' @export
agri_plot_contrasts <- function(object, specs, ...) {
  .gg_required()
  ct <- agri_contrasts(object, specs = specs, ...)
  d <- ct$table
  est <- intersect(c("estimate", "odds.ratio", "ratio"), names(d))[1L]
  if (is.na(est) || !length(est)) .agri_abort("Could not identify contrast estimate.")
  d$contrast <- factor(d$contrast, levels = rev(unique(d$contrast)))
  p <- ggplot2::ggplot(d, ggplot2::aes(x = .data[[est]], y = contrast)) + ggplot2::geom_point()
  lo <- grep("lower", names(d), ignore.case = TRUE, value = TRUE)[1L]
  hi <- grep("upper", names(d), ignore.case = TRUE, value = TRUE)[1L]
  if (!is.na(lo) && !is.na(hi)) p <- p + ggplot2::geom_errorbarh(ggplot2::aes(xmin = .data[[lo]], xmax = .data[[hi]]), height = 0.1)
  p + ggplot2::geom_vline(xintercept = 0, linetype = 2) + ggplot2::labs(x = "Contrast estimate", y = NULL)
}

#' Plot a quantitative-treatment regression
#' @export
agri_plot_regression <- function(object, n = 200L, ...) {
  .gg_required()
  if (!inherits(object, "agri_regression")) .agri_abort("'object' must be an agri_regression.")
  d <- object$data; x <- object$x; y <- object$response
  grid <- data.frame(seq(min(d[[x]], na.rm = TRUE), max(d[[x]], na.rm = TRUE), length.out = n))
  names(grid) <- x
  lo <- hi <- NULL
  if (inherits(object$fit, "lm") && !inherits(object$fit, "glm")) {
    pp <- stats::predict(object$fit, newdata = grid, interval = "confidence")
    grid$prediction <- pp[, "fit"]; grid$lower <- pp[, "lwr"]; grid$upper <- pp[, "upr"]
  } else if (inherits(object$fit, "glm")) {
    pp <- stats::predict(object$fit, newdata = grid, type = "link", se.fit = TRUE)
    z <- stats::qnorm(0.975); inv <- object$fit$family$linkinv
    grid$prediction <- inv(pp$fit); grid$lower <- inv(pp$fit - z * pp$se.fit); grid$upper <- inv(pp$fit + z * pp$se.fit)
  } else {
    pr <- stats::predict(object$fit, newdata = grid)
    grid$prediction <- as.numeric(pr)
  }
  p <- ggplot2::ggplot(d, ggplot2::aes(x = .data[[x]], y = .data[[y]])) + ggplot2::geom_point()
  if (all(c("lower", "upper") %in% names(grid))) p <- p + ggplot2::geom_ribbon(data = grid, ggplot2::aes(x = .data[[x]], ymin = lower, ymax = upper), inherit.aes = FALSE, alpha = 0.18)
  p + ggplot2::geom_line(data = grid, ggplot2::aes(x = .data[[x]], y = prediction), inherit.aes = FALSE) +
    ggplot2::labs(y = y, x = x)
}

#' Plot an interaction using adjusted predictions
#' @export
agri_plot_interaction <- function(object, x, trace, ...) {
  .gg_required()
  if (object$engine == "VGAM") {
    .agri_abort("For VGAM multi-outcome models, use agri_plot_means() and facet category probabilities.")
  }
  if (object$engine == "GLMMadaptive") {
    .agri_abort("Interaction plotting for GLMMadaptive is not routed through emmeans. Use agri_means() or agri_contrasts() on scientifically specified strata, then plot their returned tables.")
  }
  .require_pkg("emmeans", "interaction plotting")
  em <- emmeans::emmeans(object$engine_fit, specs = stats::as.formula(paste("~", x, "|", trace)), type = "response", ...)
  d <- as.data.frame(em)
  est <- intersect(c("emmean", "response", "prob", "rate"), names(d))[1L]
  ggplot2::ggplot(d, ggplot2::aes(x = .data[[x]], y = .data[[est]], group = .data[[trace]])) +
    ggplot2::geom_line() + ggplot2::geom_point() + ggplot2::facet_wrap(stats::as.formula(paste("~", trace)))
}

#' Plot observed distribution and model information
#' @export
agri_plot_distribution <- function(object, ...) {
  .gg_required()
  y <- .response_vector(object)
  if (is.null(y)) .agri_abort("Observed response is unavailable.")
  if (is.matrix(y)) {
    d <- data.frame(component = rep(colnames(y) %||% paste0("response", seq_len(ncol(y))), each = nrow(y)),
                    value = as.vector(y), stringsAsFactors = FALSE)
    return(ggplot2::ggplot(d, ggplot2::aes(component, value)) +
             ggplot2::geom_boxplot(outlier.shape = NA) + ggplot2::geom_jitter(width = 0.08, alpha = 0.4) +
             ggplot2::labs(x = "Response component", y = "Observed value"))
  }
  if (is.factor(y)) {
    d <- data.frame(y = y)
    return(ggplot2::ggplot(d, ggplot2::aes(y)) + ggplot2::geom_bar() + ggplot2::labs(x = object$response$name, y = "Frequency"))
  }
  d <- data.frame(y = as.numeric(y))
  if (.is_count_vector(y)) {
    ggplot2::ggplot(d, ggplot2::aes(y)) + ggplot2::geom_bar() + ggplot2::labs(x = object$response$name, y = "Frequency")
  } else {
    ggplot2::ggplot(d, ggplot2::aes(y)) + ggplot2::geom_histogram(bins = 30) +
      ggplot2::geom_density(ggplot2::aes(y = ggplot2::after_stat(count)), alpha = 0.15) +
      ggplot2::labs(x = object$response$name, y = "Frequency")
  }
}

#' Plot random effects
#' @export
agri_plot_random <- function(object, ...) {
  .gg_required()
  if (!inherits(object, "agri_model")) .agri_abort("'object' must be an agri_model.")
  rows <- list(); k <- 0L
  if (object$engine == "glmmTMB") {
    re <- glmmTMB::ranef(object$engine_fit)$cond
    for (grp in names(re)) {
      dat <- re[[grp]]
      for (term in names(dat)) { k <- k + 1L; rows[[k]] <- data.frame(group=grp, level=rownames(dat), term=term, estimate=dat[[term]]) }
    }
  } else if (object$engine == "lme4") {
    re <- lme4::ranef(object$engine_fit)
    for (grp in names(re)) {
      dat <- re[[grp]]
      for (term in names(dat)) { k <- k + 1L; rows[[k]] <- data.frame(group=grp, level=rownames(dat), term=term, estimate=dat[[term]]) }
    }
  } else if (object$engine == "GLMMadaptive") {
    re <- try(GLMMadaptive::ranef(object$engine_fit), silent = TRUE)
    if (inherits(re, "try-error")) .agri_abort("GLMMadaptive random effects could not be extracted.")
    re <- as.data.frame(re); grp <- object$design$blocking %||% "group"
    for (term in names(re)) { k <- k + 1L; rows[[k]] <- data.frame(group=paste(grp, collapse=":"), level=rownames(re), term=term, estimate=re[[term]]) }
  } else {
    .agri_abort("Random-effect caterpillar plotting supports glmmTMB, lme4 and GLMMadaptive models.")
  }
  if (!length(rows)) .agri_abort("No random effects were extracted.")
  d <- do.call(rbind, rows); d$level <- factor(d$level, levels = unique(d$level[order(d$estimate)]))
  ggplot2::ggplot(d, ggplot2::aes(estimate, level)) + ggplot2::geom_point() +
    ggplot2::facet_wrap(~ group + term, scales = "free_y") + ggplot2::geom_vline(xintercept = 0, linetype = 2)
}

#' Plot a family-screen comparison
#' @export
agri_plot_family_scan <- function(object, metric = c("AIC", "BIC"), ...) {
  .gg_required()
  if (!inherits(object, "agri_family_scan")) .agri_abort("'object' must be an agri_family_scan.")
  metric <- match.arg(metric)
  d <- object$table[is.finite(object$table[[metric]]), , drop = FALSE]
  if (!nrow(d)) .agri_abort(sprintf("No finite %s values are available.", metric))
  d$family <- factor(d$family, levels = rev(d$family[order(d[[metric]])]))
  ggplot2::ggplot(d, ggplot2::aes(x = .data[[metric]], y = family)) + ggplot2::geom_col() +
    ggplot2::labs(y = NULL, x = metric)
}

#' Unified plotting dispatcher
#' @export
agri_plot <- function(object,
                      type = c("diagnostics", "fit", "means", "contrasts", "regression",
                               "interaction", "distribution", "random", "family_scan",
                               "rootogram", "zero", "calibration"), ...) {
  type <- match.arg(type)
  if (type == "family_scan") return(agri_plot_family_scan(object, ...))
  if (type == "regression") return(agri_plot_regression(object, ...))
  if (type == "fit") return(agri_plot_fit(object, ...))
  if (type == "means") return(agri_plot_means(object, ...))
  if (type == "contrasts") return(agri_plot_contrasts(object, ...))
  if (type == "interaction") return(agri_plot_interaction(object, ...))
  if (type == "distribution") return(agri_plot_distribution(object, ...))
  if (type == "random") return(agri_plot_random(object, ...))
  if (type == "rootogram") return(agri_plot_diagnostics(object, panel = "rootogram", ...))
  if (type == "zero") return(agri_plot_diagnostics(object, panel = "zero", ...))
  if (type == "calibration") return(agri_plot_diagnostics(object, panel = "calibration", ...))
  agri_plot_diagnostics(object, ...)
}

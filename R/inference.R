#' Analysis-of-deviance / model ANOVA table
#' @export
agri_anova <- function(object, ...) {
  if (!inherits(object, "agri_model")) .agri_abort("'object' must be an agri_model.")
  out <- try(stats::anova(object$engine_fit, ...), silent = TRUE)
  if (inherits(out, "try-error")) {
    .agri_abort(sprintf("ANOVA/deviance table is not available for engine '%s' with these arguments.", object$engine))
  }
  out
}

.vgam_standardized_predictions <- function(object, specs, at = list(), ci = FALSE,
                                           level = 0.95, bootstrap = 0L, seed = 123) {
  data <- object$data
  if (length(specs) != 1L || !specs %in% names(data)) {
    .agri_abort("VGAM marginal predictions currently require one observed predictor name in 'specs'.")
  }
  levs <- if (is.factor(data[[specs]])) levels(data[[specs]]) else sort(unique(data[[specs]]))
  pred_list <- lapply(levs, function(v) {
    nd <- data
    if (is.factor(nd[[specs]])) nd[[specs]] <- factor(v, levels = levels(data[[specs]])) else nd[[specs]] <- v
    for (nm in names(at)) nd[[nm]] <- at[[nm]]
    pr <- stats::predict(object$engine_fit, newdata = nd, type = "response")
    if (is.null(dim(pr))) pr <- matrix(pr, ncol = 1L)
    colMeans(pr, na.rm = TRUE)
  })
  mat <- do.call(rbind, pred_list)
  if (is.null(colnames(mat))) colnames(mat) <- "response"
  tab <- data.frame(level = rep(as.character(levs), each = ncol(mat)),
                    outcome = rep(colnames(mat), times = nrow(mat)),
                    estimate = as.vector(t(mat)), stringsAsFactors = FALSE)
  names(tab)[1L] <- specs

  if (bootstrap > 1L) {
    set.seed(seed)
    boot_arr <- array(NA_real_, dim = c(bootstrap, nrow(mat), ncol(mat)))
    for (b in seq_len(bootstrap)) {
      idx <- sample.int(nrow(data), replace = TRUE)
      bd <- data[idx, , drop = FALSE]
      bm <- try(agri_model(data = bd, formula = object$formula, family = object$family,
                           engine = "VGAM", family_args = object$family_args,
                           engine_args = object$engine_args), silent = TRUE)
      if (inherits(bm, "try-error")) next
      for (j in seq_along(levs)) {
        nd <- bd
        if (is.factor(nd[[specs]])) nd[[specs]] <- factor(levs[j], levels = levels(data[[specs]])) else nd[[specs]] <- levs[j]
        for (nm in names(at)) nd[[nm]] <- at[[nm]]
        bp <- try(stats::predict(bm$engine_fit, newdata = nd, type = "response"), silent = TRUE)
        if (inherits(bp, "try-error")) next
        if (is.null(dim(bp))) bp <- matrix(bp, ncol = 1L)
        boot_arr[b, j, ] <- colMeans(bp, na.rm = TRUE)
      }
    }
    alpha <- (1 - level) / 2
    lo <- apply(boot_arr, c(2, 3), stats::quantile, probs = alpha, na.rm = TRUE)
    hi <- apply(boot_arr, c(2, 3), stats::quantile, probs = 1 - alpha, na.rm = TRUE)
    tab$lower.CL <- as.vector(t(lo))
    tab$upper.CL <- as.vector(t(hi))
    attr(tab, "bootstrap_draws") <- boot_arr
  }
  attr(tab, "levels") <- levs
  attr(tab, "outcomes") <- colnames(mat)
  tab
}

.glmmadaptive_extra_zero <- function(object) {
  identical(object$engine, "GLMMadaptive") &&
    (isTRUE(object$family_info$zero_inflation[1L]) || isTRUE(object$family_info$hurdle[1L]))
}

.mixed_standardized_predictions <- function(object, specs, at = list(), level = 0.95, bootstrap = 0L, seed = 123) {
  data <- object$data
  if (length(specs) != 1L || !specs %in% names(data)) {
    .agri_abort("Standardized mixed-model predictions currently require one observed predictor name in 'specs'.")
  }
  levs <- if (is.factor(data[[specs]])) levels(data[[specs]]) else sort(unique(data[[specs]]))
  pred_mode <- if (.glmmadaptive_extra_zero(object)) "response" else "marginal"
  vals <- vapply(levs, function(v) {
    nd <- data
    if (is.factor(nd[[specs]])) nd[[specs]] <- factor(v, levels = levels(data[[specs]])) else nd[[specs]] <- v
    for (nm in names(at)) nd[[nm]] <- at[[nm]]
    mean(as.numeric(agri_predict(object, newdata = nd, type = pred_mode)), na.rm = TRUE)
  }, numeric(1))
  tab <- data.frame(level = as.character(levs), estimate = vals, stringsAsFactors = FALSE)
  names(tab)[1L] <- specs
  if (bootstrap > 1L) {
    set.seed(seed); B <- matrix(NA_real_, bootstrap, length(levs))
    for (b in seq_len(bootstrap)) {
      block_name <- if (!is.null(object$design) && length(object$design$blocking)) tail(object$design$blocking, 1L) else NULL
      ids <- if (!is.null(block_name)) object$data[[block_name]] else seq_len(nrow(data))
      uid <- unique(ids); sampled <- sample(uid, length(uid), replace = TRUE)
      if (is.null(block_name)) {
        bd <- data[sampled, , drop = FALSE]
      } else {
        chunks <- lapply(seq_along(sampled), function(j) {
          ch <- data[which(ids == sampled[j]), , drop = FALSE]
          ch[[block_name]] <- paste0(".boot_cluster_", j)
          ch
        })
        bd <- do.call(rbind, chunks)
        bd[[block_name]] <- factor(bd[[block_name]], levels = paste0(".boot_cluster_", seq_along(sampled)))
      }
      bm <- try(agri_refit(object, data = bd, engine = object$engine), silent = TRUE)
      if (inherits(bm, "try-error")) next
      for (j in seq_along(levs)) {
        nd <- bd
        if (is.factor(nd[[specs]])) nd[[specs]] <- factor(levs[j], levels = levels(data[[specs]])) else nd[[specs]] <- levs[j]
        for (nm in names(at)) nd[[nm]] <- at[[nm]]
        bm_mode <- if (.glmmadaptive_extra_zero(bm)) "response" else "marginal"
        pr <- try(agri_predict(bm, newdata = nd, type = bm_mode), silent = TRUE)
        if (!inherits(pr, "try-error")) B[b, j] <- mean(as.numeric(pr), na.rm = TRUE)
      }
    }
    alpha <- (1 - level) / 2
    tab$lower.CL <- apply(B, 2L, stats::quantile, probs = alpha, na.rm = TRUE)
    tab$upper.CL <- apply(B, 2L, stats::quantile, probs = 1 - alpha, na.rm = TRUE)
    attr(tab, "bootstrap_draws") <- B
  }
  attr(tab, "prediction_mode") <- pred_mode
  attr(tab, "levels") <- levs
  tab
}

.standardized_pairwise <- function(tab, specs, adjust = "tukey", level = 0.95,
                                   method = "pairwise", control = NULL) {
  if (!specs %in% names(tab)) .agri_abort("The standardized prediction table does not contain the requested predictor.")
  levels_all <- unique(as.character(tab[[specs]]))
  if (length(levels_all) < 2L) return(data.frame())
  method_key <- tolower(as.character(method)[1L])
  dunnett <- method_key %in% c("dunnett", "trt.vs.ctrl", "trt.vs.ctrl1", "trt.vs.ctrlk") || tolower(adjust) %in% c("dunnett", "dunnettx")
  if (dunnett) {
    if (is.null(control)) control <- levels_all[1L]
    control <- as.character(control)[1L]
    if (!control %in% levels_all) .agri_abort(sprintf("Control level '%s' is not present in '%s'.", control, specs))
  }
  outcome_name <- if ("outcome" %in% names(tab)) "outcome" else NULL
  outcomes <- if (is.null(outcome_name)) "response" else unique(as.character(tab[[outcome_name]]))
  draws <- attr(tab, "bootstrap_draws")
  draw_cols <- list(); rows <- list(); kk <- 0L
  for (oi in seq_along(outcomes)) {
    oc <- outcomes[oi]
    tmp <- if (is.null(outcome_name)) tab else tab[as.character(tab[[outcome_name]]) == oc, , drop = FALSE]
    tmp <- tmp[match(levels_all, as.character(tmp[[specs]])), , drop = FALSE]
    pairs <- if (dunnett) {
      ci <- match(control, levels_all)
      cbind(setdiff(seq_along(levels_all), ci), ci)
    } else {
      do.call(rbind, lapply(seq_len(length(levels_all) - 1L), function(i) cbind(i, (i + 1L):length(levels_all))))
    }
    if (is.null(dim(pairs))) pairs <- matrix(pairs, ncol = 2L)
    for (pp in seq_len(nrow(pairs))) {
      i <- pairs[pp, 1L]; j <- pairs[pp, 2L]
      kk <- kk + 1L
      est <- tmp$estimate[i] - tmp$estimate[j]
      row <- data.frame(contrast = paste(levels_all[i], "-", levels_all[j]), estimate = est,
                        stringsAsFactors = FALSE)
      if (!is.null(outcome_name)) row$outcome <- oc
      if (!is.null(draws)) {
        dd <- if (length(dim(draws)) == 3L) draws[, i, oi] - draws[, j, oi] else draws[, i] - draws[, j]
        draw_cols[[kk]] <- dd
        se <- stats::sd(dd, na.rm = TRUE)
        alpha <- (1 - level) / 2
        row$SE <- se
        row$lower.CL <- stats::quantile(dd, alpha, na.rm = TRUE, names = FALSE)
        row$upper.CL <- stats::quantile(dd, 1 - alpha, na.rm = TRUE, names = FALSE)
        row$p.value <- 2 * min(mean(dd <= 0, na.rm = TRUE), mean(dd >= 0, na.rm = TRUE))
      }
      rows[[kk]] <- row
    }
  }
  out <- do.call(rbind, rows)
  if (!is.null(draws) && length(draw_cols)) {
    D <- do.call(cbind, draw_cols)
    ses <- vapply(draw_cols, stats::sd, numeric(1), na.rm = TRUE)
    if (dunnett || tolower(adjust) == "tukey") {
      obs <- out$estimate
      Z <- sweep(D, 2L, obs, "-")
      good <- is.finite(ses) & ses > 0
      Z[, good] <- sweep(Z[, good, drop = FALSE], 2L, ses[good], "/")
      Z[, !good] <- 0
      maxz <- apply(abs(Z), 1L, max, na.rm = TRUE)
      crit <- stats::quantile(maxz, level, na.rm = TRUE, names = FALSE)
      out$lower.CL <- out$estimate - crit * ses
      out$upper.CL <- out$estimate + crit * ses
      zobs <- abs(out$estimate / ses)
      out$p.value.adj <- vapply(zobs, function(z) mean(maxz >= z, na.rm = TRUE), numeric(1))
      attr(out, "adjustment_note") <- if (dunnett) {
        paste0("Bootstrap simultaneous max-|t| familywise adjustment for treatment-versus-control contrasts; control = '", control, "'.")
      } else {
        "Bootstrap simultaneous max-|t| adjustment used for Tukey-like familywise inference on standardized predictions."
      }
    } else {
      method <- tolower(adjust)
      if (method %in% c("none", "identity")) {
        out$p.value.adj <- out$p.value
      } else if (method == "sidak") {
        m <- sum(is.finite(out$p.value))
        out$p.value.adj <- pmin(1, 1 - (1 - out$p.value)^m)
      } else if (method == "scheffe") {
        .agri_abort("Scheffe adjustment is not approximated for bootstrap-standardized VGAM/GLMMadaptive contrasts; use an emmeans-supported engine or a validated planned-contrast adjustment.")
      } else {
        allowed <- c("holm", "hochberg", "hommel", "bonferroni", "BH", "BY", "fdr")
        canonical <- if (adjust %in% allowed) adjust else if (toupper(adjust) == "BH") "BH" else if (toupper(adjust) == "BY") "BY" else method
        if (!canonical %in% stats::p.adjust.methods) .agri_abort(sprintf("Multiplicity adjustment '%s' is not available for standardized bootstrap contrasts.", adjust))
        out$p.value.adj <- stats::p.adjust(out$p.value, method = canonical)
      }
      attr(out, "adjustment_note") <- paste("Bootstrap pairwise response/probability differences with", method, "multiplicity adjustment.")
    }
  } else {
    attr(out, "adjustment_note") <- "No inferential multiplicity adjustment was computed because bootstrap draws were not requested."
  }
  out
}

#' Estimated means or standardized category probabilities
#' @export
agri_means <- function(object, specs, scale = c("response", "link"), adjust = "tukey",
                       at = list(), level = 0.95, bootstrap = 0L, ...) {
  if (!inherits(object, "agri_model")) .agri_abort("'object' must be an agri_model.")
  scale <- match.arg(scale)
  if (object$engine == "VGAM") {
    tab <- .vgam_standardized_predictions(object, specs, at = at,
                                          level = level, bootstrap = bootstrap)
    out <- list(method = "standardized VGAM predictions", table = tab,
                scale = "response", adjust = NA_character_, object = object,
                note = "VGAM post-hoc values are standardized predicted response/category probabilities; bootstrap CIs are available when bootstrap > 1.")
    class(out) <- "agri_posthoc"
    return(out)
  }
  if (object$engine == "GLMMadaptive") {
    tab <- .mixed_standardized_predictions(object, specs, at = at, level = level, bootstrap = bootstrap)
    pmode <- attr(tab, "prediction_mode") %||% "marginal"
    out <- list(method = paste("standardized GLMMadaptive", pmode, "predictions"), table = tab,
                scale = "response", adjust = NA_character_, object = object,
                note = if (pmode == "marginal")
                  "GLMMadaptive is summarized by standardized marginal predictions; bootstrap intervals are available when bootstrap > 1." else
                  "For GLMMadaptive zero-inflated/hurdle models, population-marginal prediction is not exposed by the backend; standardized mean-subject response predictions are reported explicitly instead.")
    class(out) <- "agri_posthoc"
    return(out)
  }
  .require_pkg("emmeans", "estimated marginal means and contrasts")
  type <- if (scale == "response") "response" else "link"
  em <- emmeans::emmeans(object$engine_fit, specs = specs, at = at, type = type, ...)
  sm <- as.data.frame(summary(em, infer = c(TRUE, TRUE), level = level))
  out <- list(method = "emmeans", table = sm, emmeans = em,
              scale = scale, adjust = adjust, object = object)
  class(out) <- "agri_posthoc"
  out
}

#' Contrasts among treatments or planned comparisons
#' @export
agri_contrasts <- function(object, specs = NULL, method = "pairwise",
                           adjust = "tukey", scale = c("response", "link"),
                           weights = NULL, control = NULL, bootstrap = 0L, ...) {
  if (!inherits(object, "agri_model")) .agri_abort("'object' must be an agri_model.")
  scale <- match.arg(scale)
  if (object$engine == "VGAM") {
    if (is.null(specs)) .agri_abort("For VGAM models, provide one predictor in 'specs'.")
    means <- .vgam_standardized_predictions(object, specs, bootstrap = bootstrap)
    tab <- .standardized_pairwise(means, specs = specs, adjust = adjust, method = method, control = control)
    out <- list(method = "VGAM standardized response/category probability differences", table = tab,
                scale = "response", adjust = if (bootstrap > 1L) adjust else "not_applied",
                adjustment_note = attr(tab, "adjustment_note"), object = object)
    class(out) <- "agri_posthoc"
    return(out)
  }
  if (object$engine == "GLMMadaptive") {
    if (is.null(specs)) .agri_abort("For GLMMadaptive standardized contrasts, provide one predictor in 'specs'.")
    means <- .mixed_standardized_predictions(object, specs, bootstrap = bootstrap)
    tab <- .standardized_pairwise(means, specs = specs, adjust = adjust, method = method, control = control)
    out <- list(method = "GLMMadaptive standardized response differences", table = tab,
                scale = "response", adjust = if (bootstrap > 1L) adjust else "not_applied",
                adjustment_note = attr(tab, "adjustment_note"), object = object)
    class(out) <- "agri_posthoc"
    return(out)
  }
  .require_pkg("emmeans", "multiple comparisons")
  em <- emmeans::emmeans(object$engine_fit, specs = specs, type = if (scale == "response") "response" else "link", ...)
  method_key <- tolower(as.character(method)[1L])
  dunnett <- method_key %in% c("dunnett", "trt.vs.ctrl", "trt.vs.ctrl1", "trt.vs.ctrlk") || tolower(adjust) %in% c("dunnett", "dunnettx")
  if (!is.null(weights)) {
    ct <- emmeans::contrast(em, method = weights, adjust = adjust)
  } else if (dunnett) {
    levs <- try(levels(em)[[as.character(specs)[1L]]], silent = TRUE)
    if (inherits(levs, "try-error") || is.null(levs)) {
      grd <- try(as.data.frame(em), silent = TRUE)
      levs <- if (!inherits(grd, "try-error") && as.character(specs)[1L] %in% names(grd)) unique(as.character(grd[[as.character(specs)[1L]]])) else NULL
    }
    if (is.null(control)) control <- if (length(levs)) levs[1L] else 1L
    ref <- if (is.numeric(control)) as.integer(control)[1L] else match(as.character(control)[1L], levs)
    if (!is.finite(ref) || ref < 1L) .agri_abort(sprintf("Control level '%s' could not be resolved for Dunnett contrasts.", as.character(control)[1L]))
    # emmeans' trt.vs.ctrl family uses Dunnett-style adjustment by default.
    adj_use <- if (tolower(adjust) %in% c("dunnett", "dunnettx", "tukey")) "dunnettx" else adjust
    ct <- emmeans::contrast(em, method = "trt.vs.ctrl", ref = ref, adjust = adj_use)
    method <- "dunnett"
    adjust <- adj_use
  } else {
    ct <- emmeans::contrast(em, method = method, adjust = adjust)
  }
  tab <- as.data.frame(summary(ct, infer = c(TRUE, TRUE)))
  out <- list(method = method, table = tab, contrasts = ct, scale = scale,
              adjust = adjust, control = control, object = object)
  class(out) <- "agri_posthoc"
  out
}

#' Estimate or compare trends
#' @export
agri_trends <- function(object, variable, by = NULL, delta = NULL, ...) {
  if (!inherits(object, "agri_model")) .agri_abort("'object' must be an agri_model.")
  if (object$engine == "GLMMadaptive") {
    data <- object$data
    if (!variable %in% names(data) || !is.numeric(data[[variable]])) .agri_abort("GLMMadaptive numerical trends require a numeric predictor.")
    d <- delta %||% (diff(range(data[[variable]], na.rm = TRUE)) * 1e-4 + sqrt(.Machine$double.eps))
    nd1 <- data; nd2 <- data; nd1[[variable]] <- nd1[[variable]] - d / 2; nd2[[variable]] <- nd2[[variable]] + d / 2
    pred_mode <- if (.glmmadaptive_extra_zero(object)) "response" else "marginal"
    p1 <- agri_predict(object, newdata = nd1, type = pred_mode); p2 <- agri_predict(object, newdata = nd2, type = pred_mode)
    tab <- data.frame(trend = mean((as.numeric(p2) - as.numeric(p1)) / d, na.rm = TRUE))
    out <- list(method = "finite-difference standardized GLMMadaptive trend", table = tab, object = object)
    class(out) <- "agri_posthoc"; return(out)
  }
  if (object$engine != "VGAM") {
    .require_pkg("emmeans", "estimated marginal trends")
    tr <- emmeans::emtrends(object$engine_fit, specs = by, var = variable, ...)
    out <- list(method = "emtrends", table = as.data.frame(summary(tr, infer = c(TRUE, TRUE))), trends = tr, object = object)
    class(out) <- "agri_posthoc"
    return(out)
  }
  data <- object$data
  if (!variable %in% names(data) || !is.numeric(data[[variable]])) .agri_abort("VGAM numerical trends require a numeric predictor.")
  d <- delta %||% (diff(range(data[[variable]], na.rm = TRUE)) * 1e-4 + sqrt(.Machine$double.eps))
  nd1 <- data; nd2 <- data
  nd1[[variable]] <- nd1[[variable]] - d / 2
  nd2[[variable]] <- nd2[[variable]] + d / 2
  p1 <- stats::predict(object$engine_fit, newdata = nd1, type = "response")
  p2 <- stats::predict(object$engine_fit, newdata = nd2, type = "response")
  der <- (p2 - p1) / d
  if (is.null(dim(der))) der <- matrix(der, ncol = 1L)
  tab <- data.frame(outcome = colnames(der) %||% paste0("outcome", seq_len(ncol(der))),
                    trend = colMeans(der, na.rm = TRUE), stringsAsFactors = FALSE)
  out <- list(method = "finite-difference standardized VGAM trend", table = tab, object = object)
  class(out) <- "agri_posthoc"
  out
}

#' Marginal effects
#' @export
agri_effects <- function(object, variables = NULL, ...) {
  if (!inherits(object, "agri_model")) .agri_abort("'object' must be an agri_model.")
  if (object$engine == "VGAM") {
    if (is.null(variables) || length(variables) != 1L) .agri_abort("For VGAM, provide one variable; agri_trends() or agri_means() will be used according to its type.")
    if (is.numeric(object$data[[variables]])) return(agri_trends(object, variable = variables, ...))
    return(agri_means(object, specs = variables, ...))
  }
  if (requireNamespace("marginaleffects", quietly = TRUE)) {
    return(marginaleffects::avg_slopes(object$engine_fit, variables = variables, ...))
  }
  .agri_warn("Package 'marginaleffects' is unavailable; returning model predictions instead.")
  agri_predict(object, ...)
}

#' Generate model predictions
#' @export
agri_predict <- function(object, newdata = NULL,
                         type = c("response", "link", "conditional", "marginal"), ...) {
  if (!inherits(object, "agri_model")) .agri_abort("'object' must be an agri_model.")
  type <- match.arg(type)
  fit <- object$engine_fit
  nd <- newdata
  if (object$engine == "gamlss") {
    what <- if (type == "response") "mu" else "mu"
    return(stats::predict(fit, newdata = nd, type = if (type == "link") "link" else "response", what = what, ...))
  }
  if (object$engine == "VGAM") {
    return(stats::predict(fit, newdata = nd, type = if (type == "link") "link" else "response", ...))
  }
  if (object$engine == "ordinal") {
    # ordinal::predict.clm/clmm returns a list; probabilities for all categories
    # require newdata without the response column.
    nd_ord <- nd
    if (is.null(nd_ord)) nd_ord <- object$data
    rname <- object$response$name
    if (length(rname) == 1L && rname %in% names(nd_ord)) nd_ord[[rname]] <- NULL
    ord_type <- if (type == "link") "linear.predictor" else "prob"
    pr <- stats::predict(fit, newdata = nd_ord, type = ord_type, ...)
    return(if (is.list(pr) && !is.null(pr$fit)) pr$fit else pr)
  }
  if (object$engine == "glmmTMB") {
    if (type == "marginal") return(stats::predict(fit, newdata = nd, type = "response", re.form = NA, ...))
    if (type == "conditional") return(stats::predict(fit, newdata = nd, type = "response", re.form = NULL, ...))
    return(stats::predict(fit, newdata = nd, type = type, ...))
  }
  if (object$engine == "lme4") {
    pred_type <- if (type == "link") "link" else "response"
    if (type == "marginal") return(stats::predict(fit, newdata = nd, type = pred_type, re.form = NA, ...))
    if (type == "conditional") return(stats::predict(fit, newdata = nd, type = pred_type, re.form = NULL, ...))
    return(stats::predict(fit, newdata = nd, type = pred_type, ...))
  }
  if (object$engine == "GLMMadaptive") {
    if (type == "marginal" && .glmmadaptive_extra_zero(object)) {
      .agri_abort(paste0(
        "Population-marginal prediction for GLMMadaptive models with an additional zero/hurdle process is not available through the backend. ",
        "Use type = 'response' for explicitly labelled mean-subject predictions, or fit a compatible glmmTMB model when population-level marginalization is required."
      ))
    }
    pred_type <- if (type == "link") "link" else "response"
    mode <- if (type == "marginal") "marginal" else if (type == "conditional") "subject_specific" else "mean_subject"
    return(stats::predict(fit, newdata = nd, type = mode, type_pred = pred_type, ...))
  }
  stats::predict(fit, newdata = nd, type = if (type %in% c("conditional", "marginal")) "response" else type, ...)
}

#' Compact-letter display
#' @export
agri_cld <- function(object, specs, adjust = "tukey", ...) {
  if (object$engine == "VGAM") {
    .agri_abort("Compact-letter displays are not provided for VGAM category probabilities. Use explicit probability contrasts instead.")
  }
  if (object$engine == "GLMMadaptive") {
    .agri_abort("Compact-letter displays are not generated for GLMMadaptive objects because direct emmeans support is not assumed. Use agri_means() and agri_contrasts(), which use explicit standardized predictions.")
  }
  .require_pkg("emmeans", "compact-letter display")
  .require_pkg("multcompView", "compact-letter display")
  em <- emmeans::emmeans(object$engine_fit, specs = specs, ...)
  ct <- emmeans::contrast(em, method = "pairwise", adjust = adjust)
  tt <- as.data.frame(summary(ct))
  # Create named vector of p-values for multcompLetters
  pvals <- tt$p.value
  contrast_names <- apply(tt[, 1, drop = FALSE], 1, paste, collapse = "-")
  names(pvals) <- contrast_names
  cld_result <- multcompView::multcompLetters(pvals)
  out <- as.data.frame(em)
  # Match levels to CLD letters
  level_col <- as.character(specs)
  out$.cld <- cld_result$Letters[match(as.character(out[[level_col]]), names(cld_result$Letters))]
  out
}

#' Simple effects within levels of another experimental factor
#' @export
agri_simple_effects <- function(object, focal, by, adjust = "tukey",
                                scale = c("response", "link"), bootstrap = 0L, ...) {
  if (!inherits(object, "agri_model")) .agri_abort("'object' must be an agri_model.")
  scale <- match.arg(scale)
  focal <- as.character(focal)[1L]; by <- as.character(by)[1L]
  .assert_columns(object$data, c(focal, by), "simple effects")
  if (object$engine %in% c("VGAM", "GLMMadaptive")) {
    bylev <- if (is.factor(object$data[[by]])) levels(object$data[[by]]) else unique(object$data[[by]])
    rows <- lapply(bylev, function(bv) {
      if (object$engine == "VGAM") {
        mm <- .vgam_standardized_predictions(object, focal, at = stats::setNames(list(bv), by), bootstrap = bootstrap)
      } else {
        mm <- .mixed_standardized_predictions(object, focal, at = stats::setNames(list(bv), by), bootstrap = bootstrap)
      }
      cc <- .standardized_pairwise(mm, focal, adjust = adjust)
      cc[[by]] <- bv
      cc
    })
    tab <- do.call(rbind, rows)
    out <- list(method = "standardized simple-effect contrasts", table = tab,
                scale = "response", adjust = if (bootstrap > 1L) adjust else "not_applied",
                object = object)
    class(out) <- "agri_posthoc"
    return(out)
  }
  .require_pkg("emmeans", "simple effects")
  type <- if (scale == "response") "response" else "link"
  spec <- stats::as.formula(sprintf("~ %s | %s", .bt(focal), .bt(by)))
  em <- emmeans::emmeans(object$engine_fit, specs = spec, type = type, ...)
  ct <- emmeans::contrast(em, method = "pairwise", by = by, adjust = adjust)
  out <- list(method = "simple effects", table = as.data.frame(summary(ct, infer = c(TRUE, TRUE))),
              emmeans = em, contrasts = ct, scale = scale, adjust = adjust, object = object)
  class(out) <- "agri_posthoc"
  out
}

#' Interaction contrasts for factorial effects
#' @export
agri_interaction_contrast <- function(object, factors, interaction = "pairwise",
                                      adjust = "holm", scale = c("response", "link"), ...) {
  if (!inherits(object, "agri_model")) .agri_abort("'object' must be an agri_model.")
  factors <- as.character(factors)
  if (length(factors) < 2L) .agri_abort("Provide at least two factor names for an interaction contrast.")
  .assert_columns(object$data, factors, "interaction contrast")
  if (object$engine %in% c("VGAM", "GLMMadaptive")) {
    .agri_abort("General interaction-contrast tensors are not silently approximated for VGAM/GLMMadaptive standardized predictions. Use agri_simple_effects() or explicit planned probability/response contrasts.")
  }
  scale <- match.arg(scale)
  .require_pkg("emmeans", "interaction contrasts")
  em <- emmeans::emmeans(object$engine_fit, specs = factors,
                         type = if (scale == "response") "response" else "link", ...)
  int_method <- if (length(interaction) == 1L) rep(interaction, length(factors)) else interaction
  ct <- emmeans::contrast(em, interaction = int_method, adjust = adjust)
  out <- list(method = "interaction contrast", table = as.data.frame(summary(ct, infer = c(TRUE, TRUE))),
              emmeans = em, contrasts = ct, scale = scale, adjust = adjust, object = object)
  class(out) <- "agri_posthoc"
  out
}

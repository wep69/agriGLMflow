.agri_coef_table <- function(model) {
  if (!inherits(model, "agri_model")) return(NULL)
  fit <- model$engine_fit
  if (model$engine == "glmmTMB") {
    sm <- try(summary(fit)$coefficients$cond, silent = TRUE)
    if (!inherits(sm, "try-error")) return(sm)
  }
  if (model$engine == "lme4") {
    sm <- try(as.matrix(summary(fit)$coefficients), silent = TRUE)
    if (!inherits(sm, "try-error")) {
      if (!any(grepl("Pr\\(", colnames(sm))) && ncol(sm) >= 3L) {
        stat <- sm[, ncol(sm)]
        sm <- cbind(sm, `Pr(>|z|)` = 2 * stats::pnorm(abs(stat), lower.tail = FALSE))
        attr(sm, "p_value_note") <- "Asymptotic normal approximation added by agriGLMflow because lme4 does not provide denominator-df p-values for lmer models."
      }
      return(sm)
    }
  }
  if (model$engine == "GLMMadaptive") {
    est <- try(stats::coef(fit), silent = TRUE)
    V <- try(stats::vcov(fit), silent = TRUE)
    if (!inherits(est, "try-error") && !inherits(V, "try-error")) {
      est <- as.numeric(est); names(est) <- names(stats::coef(fit))
      se <- sqrt(pmax(0, diag(as.matrix(V))[seq_along(est)]))
      z <- est / se
      out <- cbind(Estimate = est, Std.Err = se, z.value = z, `Pr(>|z|)` = 2 * stats::pnorm(abs(z), lower.tail = FALSE))
      rownames(out) <- names(stats::coef(fit))
      return(out)
    }
  }
  if (model$engine %in% c("stats", "brglm2", "betareg")) {
    sm <- try(stats::coef(summary(fit)), silent = TRUE)
    if (!inherits(sm, "try-error") && is.matrix(sm)) return(sm)
  }
  sm <- try(stats::coef(summary(fit)), silent = TRUE)
  if (!inherits(sm, "try-error") && is.matrix(sm)) return(sm)
  NULL
}

#' Simulate responses from a fitted model
#' @export
agri_simulate <- function(object, nsim = 1L, seed = NULL, ...) {
  if (!inherits(object, "agri_model")) .agri_abort("'object' must be an agri_model.")
  if (!is.null(seed)) set.seed(seed)
  out <- try(stats::simulate(object$engine_fit, nsim = nsim, ...), silent = TRUE)
  if (inherits(out, "try-error")) {
    .agri_abort(sprintf("Simulation is not implemented for engine '%s' / family '%s' in the installed backend version.", object$engine, object$family))
  }
  out
}

.bootstrap_unit <- function(object, unit = NULL) {
  if (!is.null(unit)) return(as.character(unit)[1L])
  d <- object$design
  if (is.null(d)) return(NULL)
  if (length(d$experimental_units)) return(tail(d$experimental_units, 1L))
  if (length(d$blocking)) return(tail(d$blocking, 1L))
  NULL
}

#' Bootstrap an agriGLMflow model while respecting experimental units
#' @export
agri_bootstrap <- function(object, R = 500L, unit = NULL,
                           type = c("cluster", "parametric"), seed = 123,
                           statistic = c("coef", "prediction"), newdata = NULL, ...) {
  if (!inherits(object, "agri_model")) .agri_abort("'object' must be an agri_model.")
  type <- match.arg(type)
  statistic <- match.arg(statistic)
  set.seed(seed)
  data <- object$data
  results <- vector("list", R)

  if (type == "parametric") {
    sims <- agri_simulate(object, nsim = R, seed = seed)
    if (is.data.frame(sims)) sims <- as.list(sims)
    for (b in seq_len(R)) {
      bd <- data
      yname <- object$response$name
      if (!yname %in% names(bd)) .agri_abort("Parametric bootstrap currently requires a single response column.")
      bd[[yname]] <- sims[[b]]
      bm <- try(agri_refit(object, data = bd), silent = TRUE)
      if (inherits(bm, "try-error")) next
      results[[b]] <- if (statistic == "coef") try(stats::coef(bm$engine_fit), silent = TRUE) else try(agri_predict(bm, newdata = newdata), silent = TRUE)
    }
  } else {
    unit <- .bootstrap_unit(object, unit)
    if (is.null(unit)) {
      .agri_warn("No experimental-unit identifier was available; cluster bootstrap falls back to observation-level resampling.")
      unit_ids <- seq_len(nrow(data))
      unit_vec <- seq_len(nrow(data))
    } else {
      .assert_columns(data, unit, "bootstrap")
      unit_vec <- data[[unit]]
      unit_ids <- unique(unit_vec)
    }
    for (b in seq_len(R)) {
      sampled <- sample(unit_ids, length(unit_ids), replace = TRUE)
      if (is.null(unit)) {
        idx <- sampled
        bd <- data[idx, , drop = FALSE]
      } else {
        chunks <- lapply(seq_along(sampled), function(j) {
          ch <- data[which(unit_vec == sampled[j]), , drop = FALSE]
          # A sampled cluster appearing twice represents two bootstrap clusters,
          # not one enlarged original cluster. Relabel it accordingly.
          ch[[unit]] <- paste0(".boot_cluster_", j)
          ch
        })
        bd <- do.call(rbind, chunks)
        bd[[unit]] <- factor(bd[[unit]], levels = paste0(".boot_cluster_", seq_along(sampled)))
      }
      bm <- try(agri_refit(object, data = bd), silent = TRUE)
      if (inherits(bm, "try-error")) next
      results[[b]] <- if (statistic == "coef") try(stats::coef(bm$engine_fit), silent = TRUE) else try(agri_predict(bm, newdata = newdata), silent = TRUE)
    }
  }
  valid <- vapply(results, function(z) !is.null(z) && !inherits(z, "try-error"), logical(1))
  vals <- results[valid]
  mat <- if (length(vals)) try(do.call(rbind, lapply(vals, as.numeric)), silent = TRUE) else NULL
  if (inherits(mat, "try-error")) mat <- NULL
  structure(list(type = type, R = R, successful = sum(valid), unit = unit,
                 statistic = statistic, values = vals, matrix = mat, seed = seed,
                 model = object), class = "agri_bootstrap")
}

.cv_observed <- function(data, response) {
  nm <- response$name
  if (length(nm) > 1L) return(as.matrix(data[nm]))
  data[[nm]]
}

.cv_metric <- function(y, pred, family = NULL) {
  eps <- 1e-12
  # Probability matrices: multinomial/ordinal, compositions, or multivariate counts.
  if (is.matrix(pred) || is.data.frame(pred)) {
    P <- as.matrix(pred)
    storage.mode(P) <- "double"
    if (!nrow(P)) return(c(RMSE = NA_real_, MAE = NA_real_, log_loss = NA_real_, Brier = NA_real_, accuracy = NA_real_))
    P[!is.finite(P)] <- NA_real_
    rs <- rowSums(P, na.rm = TRUE)
    good_rs <- is.finite(rs) & rs > 0
    if (any(good_rs)) P[good_rs, ] <- P[good_rs, , drop = FALSE] / rs[good_rs]
    P <- pmin(P, 1 - eps)
    P <- pmax(P, eps)

    if (is.factor(y) || is.ordered(y) || is.character(y) || is.logical(y)) {
      yy <- as.character(y)
      levs <- colnames(P)
      if (is.null(levs)) levs <- if (is.factor(y) || is.ordered(y)) levels(y) else sort(unique(yy))
      if (ncol(P) != length(levs)) return(c(RMSE = NA_real_, MAE = NA_real_, log_loss = NA_real_, Brier = NA_real_, accuracy = NA_real_))
      colnames(P) <- levs
      idx <- match(yy, levs)
      ok <- is.finite(idx) & seq_along(idx) <= nrow(P) & stats::complete.cases(P)
      if (!any(ok)) return(c(RMSE = NA_real_, MAE = NA_real_, log_loss = NA_real_, Brier = NA_real_, accuracy = NA_real_))
      Y <- matrix(0, nrow(P), ncol(P), dimnames = list(NULL, levs))
      Y[cbind(seq_len(nrow(P))[ok], idx[ok])] <- 1
      err <- P[ok, , drop = FALSE] - Y[ok, , drop = FALSE]
      ptrue <- P[cbind(seq_len(nrow(P))[ok], idx[ok])]
      cls <- levs[max.col(P[ok, , drop = FALSE], ties.method = "first")]
      return(c(
        RMSE = sqrt(mean(err^2, na.rm = TRUE)),
        MAE = mean(abs(err), na.rm = TRUE),
        log_loss = -mean(log(ptrue), na.rm = TRUE),
        Brier = mean(rowSums(err^2), na.rm = TRUE),
        accuracy = mean(cls == yy[ok], na.rm = TRUE)
      ))
    }

    if (is.matrix(y) || is.data.frame(y)) {
      Yraw <- as.matrix(y)
      storage.mode(Yraw) <- "double"
      if (nrow(Yraw) != nrow(P) || ncol(Yraw) != ncol(P)) {
        return(c(RMSE = NA_real_, MAE = NA_real_, log_loss = NA_real_, Brier = NA_real_, accuracy = NA_real_))
      }
      totals <- rowSums(Yraw, na.rm = TRUE)
      ok <- stats::complete.cases(Yraw, P) & is.finite(totals) & totals > 0
      if (!any(ok)) return(c(RMSE = NA_real_, MAE = NA_real_, log_loss = NA_real_, Brier = NA_real_, accuracy = NA_real_))
      Yprop <- Yraw[ok, , drop = FALSE] / totals[ok]
      PP <- P[ok, , drop = FALSE]
      err <- PP - Yprop
      # Weighted multiclass cross-entropy for count matrices; for compositions
      # (row totals = 1), this reduces to ordinary compositional cross-entropy.
      ll_num <- -sum(Yraw[ok, , drop = FALSE] * log(PP), na.rm = TRUE)
      ll_den <- sum(Yraw[ok, , drop = FALSE], na.rm = TRUE)
      return(c(
        RMSE = sqrt(mean(err^2, na.rm = TRUE)),
        MAE = mean(abs(err), na.rm = TRUE),
        log_loss = ll_num / ll_den,
        Brier = mean(rowSums(err^2), na.rm = TRUE),
        accuracy = NA_real_
      ))
    }
  }

  y_num <- suppressWarnings(as.numeric(y))
  pred_num <- suppressWarnings(as.numeric(pred))
  ok <- is.finite(y_num) & is.finite(pred_num)
  y_num <- y_num[ok]; pred_num <- pred_num[ok]
  if (!length(y_num)) return(c(RMSE = NA_real_, MAE = NA_real_, log_loss = NA_real_, Brier = NA_real_, accuracy = NA_real_))
  out <- c(RMSE = sqrt(mean((y_num - pred_num)^2)), MAE = mean(abs(y_num - pred_num)),
           log_loss = NA_real_, Brier = NA_real_, accuracy = NA_real_)
  if (all(y_num %in% c(0, 1))) {
    pp <- pmin(1 - eps, pmax(eps, pred_num))
    out["log_loss"] <- -mean(y_num * log(pp) + (1 - y_num) * log(1 - pp))
    out["Brier"] <- mean((y_num - pp)^2)
    out["accuracy"] <- mean((pp >= 0.5) == y_num)
  }
  out
}

#' Design-aware cross-validation
#' @export
agri_cv <- function(object, v = 5L, unit = NULL,
                    scheme = c("grouped_kfold", "leave_one_environment_out"),
                    seed = 123, ...) {
  if (!inherits(object, "agri_model")) .agri_abort("'object' must be an agri_model.")
  scheme <- match.arg(scheme)
  data <- object$data
  ynames <- object$response$name
  if (!length(ynames) || !all(ynames %in% names(data))) {
    .agri_abort("Cross-validation requires response column(s) recorded in the agri_response object.")
  }

  if (scheme == "leave_one_environment_out") {
    env <- object$design$roles$environment %||% NULL
    if (is.null(env)) .agri_abort("leave_one_environment_out requires a multi-environment design with an environment column.")
    if (identical(object$design$options$environment_effect %||% "fixed", "fixed")) {
      .agri_abort(paste0(
        "leave_one_environment_out cannot extrapolate a fixed environment effect to an unseen environment. ",
        "Declare environment_effect = 'random' when scientific inference targets new environments, or use grouped_kfold within observed environments."
      ))
    }
    groups <- data[[env]]
    folds <- lapply(unique(groups), function(g) which(groups == g))
    names(folds) <- as.character(unique(groups))
  } else {
    unit <- .bootstrap_unit(object, unit)
    if (is.null(unit)) .agri_abort("Grouped k-fold CV requires an explicit unit or a design with an experimental-unit/block identifier.")
    .assert_columns(data, unit, "cross-validation")
    set.seed(seed)
    ids <- unique(data[[unit]])
    fold_id <- sample(rep(seq_len(min(v, length(ids))), length.out = length(ids)))
    folds <- lapply(seq_len(max(fold_id)), function(k) which(data[[unit]] %in% ids[fold_id == k]))
  }

  metric_names <- c("RMSE", "MAE", "log_loss", "Brier", "accuracy")
  rows <- vector("list", length(folds))
  preds <- vector("list", length(folds))
  for (k in seq_along(folds)) {
    test_idx <- folds[[k]]
    train <- data[-test_idx, , drop = FALSE]
    test <- data[test_idx, , drop = FALSE]
    fm <- try(agri_refit(object, data = train), silent = TRUE)
    if (inherits(fm, "try-error")) {
      row <- as.list(c(fold = k, n_test = nrow(test), success = FALSE, stats::setNames(rep(NA_real_, length(metric_names)), metric_names)))
      rows[[k]] <- as.data.frame(row, stringsAsFactors = FALSE)
      next
    }
    pred_type <- if (fm$engine %in% c("glmmTMB", "lme4")) "marginal" else if (fm$engine == "GLMMadaptive" && !.glmmadaptive_extra_zero(fm)) "marginal" else "response"
    pr <- if (fm$engine %in% c("glmmTMB", "lme4"))
      try(agri_predict(fm, newdata = test, type = pred_type, allow.new.levels = TRUE), silent = TRUE) else
      try(agri_predict(fm, newdata = test, type = pred_type), silent = TRUE)
    if (inherits(pr, "try-error")) {
      row <- as.list(c(fold = k, n_test = nrow(test), success = FALSE, stats::setNames(rep(NA_real_, length(metric_names)), metric_names)))
      rows[[k]] <- as.data.frame(row, stringsAsFactors = FALSE)
      next
    }
    yy <- .cv_observed(test, object$response)
    met <- .cv_metric(yy, pr, object$family)
    row <- data.frame(fold = k, n_test = nrow(test), success = TRUE, stringsAsFactors = FALSE)
    for (mn in metric_names) row[[mn]] <- unname(met[mn])
    rows[[k]] <- row
    preds[[k]] <- list(index = test_idx, observed = yy, predicted = pr)
  }
  tab <- do.call(rbind, rows)
  for (mn in metric_names) tab[[mn]] <- as.numeric(tab[[mn]])
  tab$fold <- as.integer(tab$fold); tab$n_test <- as.integer(tab$n_test); tab$success <- as.logical(tab$success)
  structure(list(table = tab,
                 summary = colMeans(tab[metric_names], na.rm = TRUE),
                 predictions = preds, scheme = scheme, unit = unit, seed = seed,
                 model = object), class = "agri_cv")
}

#' Simulation-based power for a fitted model term
#' @export
agri_power <- function(object, term, nsim = 500L, alpha = 0.05, seed = 123, ...) {
  if (!inherits(object, "agri_model")) .agri_abort("'object' must be an agri_model.")
  set.seed(seed)
  sims <- agri_simulate(object, nsim = nsim, seed = seed)
  if (is.data.frame(sims)) sims <- as.list(sims)
  yname <- object$response$name
  if (!yname %in% names(object$data)) .agri_abort("Power simulation currently requires a single response column.")
  detected <- rep(NA, nsim)
  estimates <- rep(NA_real_, nsim)
  for (i in seq_len(nsim)) {
    bd <- object$data
    bd[[yname]] <- sims[[i]]
    fm <- try(agri_refit(object, data = bd), silent = TRUE)
    if (inherits(fm, "try-error")) next
    cf <- .agri_coef_table(fm)
    if (is.null(cf) || is.null(dim(cf))) next
    rn <- rownames(cf)
    hit <- grep(term, rn, fixed = TRUE)
    if (!length(hit)) next
    h <- hit[1L]
    estimates[i] <- cf[h, 1L]
    pcol <- grep("Pr\\(", colnames(cf), value = FALSE)
    if (length(pcol)) detected[i] <- cf[h, pcol[1L]] < alpha
  }
  structure(list(power = mean(detected, na.rm = TRUE), alpha = alpha,
                 nsim = nsim, successful = sum(!is.na(detected)), term = term,
                 estimates = estimates, seed = seed, model = object),
            class = "agri_power")
}

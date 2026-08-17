.fit_stats <- function(formula, data, family, link = NULL, engine_args = list()) {
  fam <- .make_stats_family(family, link)
  do.call(stats::glm, c(list(formula = formula, data = data, family = fam), engine_args))
}

.fit_brglm2 <- function(formula, data, family, link = NULL, engine_args = list()) {
  .require_pkg("brglm2", "bias-reduced generalized linear modelling")
  fam <- .make_stats_family(family, link)
  do.call(stats::glm, c(list(formula = formula, data = data, family = fam,
                             method = brglm2::brglmFit), engine_args))
}

.fit_glmmtmb <- function(formula, data, family, link = NULL, ziformula = NULL,
                         dispformula = NULL, family_args = list(), engine_args = list()) {
  .require_pkg("glmmTMB", "advanced generalized linear mixed modelling")
  fam <- .make_glmmtmb_family(family, link)
  zif <- ziformula %||% .family_default_zi(family)
  dispf <- dispformula %||% stats::as.formula("~1")
  args <- c(list(formula = formula, data = data, family = fam,
                 ziformula = zif, dispformula = dispf), engine_args)
  do.call(glmmTMB::glmmTMB, args)
}

.fit_lme4 <- function(formula, data, family, link = NULL, engine_args = list()) {
  .require_pkg("lme4", "reference generalized linear mixed modelling")
  if (!.check_random_syntax(formula)) .agri_abort("lme4 is reserved for models containing random effects in agriGLMflow.")
  if (family == "gaussian") {
    return(do.call(lme4::lmer, c(list(formula = formula, data = data), engine_args)))
  }
  if (family == "nbinom2") {
    return(do.call(lme4::glmer.nb, c(list(formula = formula, data = data), engine_args)))
  }
  allowed <- c("poisson", "binomial", "Gamma", "inverse.gaussian")
  if (!family %in% allowed) {
    .agri_abort(sprintf("Family '%s' is not supported by the agriGLMflow lme4 adapter without changing its statistical definition.", family))
  }
  fam <- .make_stats_family(family, link)
  do.call(lme4::glmer, c(list(formula = formula, data = data, family = fam), engine_args))
}

.fit_GLMMadaptive <- function(formula, data, family, link = NULL, ziformula = NULL,
                                  engine_args = list()) {
  .require_pkg("GLMMadaptive", "adaptive-quadrature generalized linear mixed modelling")
  parts <- .split_single_random_formula(formula)
  fam <- .make_glmmadaptive_family(family, link)
  args <- list(fixed = parts$fixed, random = parts$random, data = data, family = fam)
  if (family %in% c("zip", "zinb2", "hurdle_poisson", "hurdle_nbinom2")) {
    # GLMMadaptive calls the extra-zero/hurdle linear predictor 'zi_fixed'.
    # Keep the default intercept-only mechanism unless the user declared an
    # explicit ziformula, and never drop this component silently.
    args$zi_fixed <- ziformula %||% stats::as.formula("~1")
  }
  do.call(GLMMadaptive::mixed_model, c(args, engine_args))
}

.fit_gamlss <- function(formula, data, family, family_args = list(), engine_args = list()) {
  .require_pkg("gamlss", "GAMLSS distributional regression")
  fam <- .make_gamlss_family(family, family_args)
  args <- c(list(formula = formula, family = fam, data = data), engine_args)
  do.call(gamlss::gamlss, args)
}

.fit_vgam <- function(formula, data, family, family_args = list(), engine_args = list(), additive = FALSE) {
  .require_pkg("VGAM", "vector generalized modelling")
  fam <- .make_vgam_family(family, family_args)
  fn <- if (isTRUE(additive)) VGAM::vgam else VGAM::vglm
  args <- c(list(formula = formula, family = fam, data = data), engine_args)
  # VGAM uses substitute(data) internally; do.call wraps values in promises
  # which break that mechanism. Evaluate directly when no engine_args.
  if (length(engine_args) == 0L) {
    if (isTRUE(additive)) VGAM::vgam(formula = formula, family = fam, data = data)
    else VGAM::vglm(formula = formula, family = fam, data = data)
  } else {
    do.call(fn, args)
  }
}

.fit_ordinal <- function(formula, data, family, engine_args = list(), link = "logit") {
  .require_pkg("ordinal", "ordinal regression")
  mixed <- family == "ordinal_clmm" || .check_random_syntax(formula)
  fn <- if (mixed) ordinal::clmm else ordinal::clm
  do.call(fn, c(list(formula = formula, data = data, link = link), engine_args))
}

.fit_betareg <- function(formula, data, family, engine_args = list(), link = "logit") {
  .require_pkg("betareg", "beta regression")
  args <- c(list(formula = formula, data = data, link = link), engine_args)
  if (family == "extended_beta") {
    # Modern betareg automatically uses extended-support beta when requested through
    # dist = "xbetax". Keeping this argument isolated makes version failures explicit.
    args$dist <- args$dist %||% "xbetax"
  }
  do.call(betareg::betareg, args)
}

.check_convergence_internal <- function(fit, engine) {
  ok <- TRUE
  code <- NA
  messages <- character()
  if (engine %in% c("stats", "brglm2")) {
    ok <- isTRUE(fit$converged %||% TRUE)
    code <- if (ok) 0 else 1
  } else if (engine == "glmmTMB") {
    code <- fit$fit$convergence %||% NA_integer_
    pd <- fit$sdr$pdHess %||% NA
    ok <- isTRUE(code == 0) && !identical(pd, FALSE)
    if (identical(pd, FALSE)) messages <- c(messages, "Non-positive-definite Hessian.")
  } else if (engine == "lme4") {
    msgs <- fit@optinfo$conv$lme4$messages %||% character()
    ok <- !length(msgs)
    code <- if (ok) 0 else 1
    if (length(msgs)) messages <- c(messages, as.character(msgs))
    if (requireNamespace("lme4", quietly = TRUE) && isTRUE(try(lme4::isSingular(fit, tol = 1e-5), silent = TRUE))) {
      messages <- c(messages, "Singular random-effects fit.")
    }
  } else if (engine == "GLMMadaptive") {
    ll <- try(stats::logLik(fit), silent = TRUE)
    cf <- try(stats::coef(fit), silent = TRUE)
    ok <- !inherits(ll, "try-error") && !inherits(cf, "try-error") && all(is.finite(as.numeric(cf)))
    code <- if (ok) 0 else 1
    if (!ok) messages <- c(messages, "GLMMadaptive fit did not yield finite coefficients/log-likelihood.")
  } else if (engine == "gamlss") {
    ok <- isTRUE(fit$converged %||% TRUE)
    code <- fit$iter %||% NA_integer_
  } else if (engine == "VGAM") {
    crit <- try(fit@criterion, silent = TRUE)
    ok <- !inherits(crit, "try-error")
    code <- if (ok) 0 else 1
  } else if (engine == "ordinal") {
    opt <- fit$optRes %||% list(convergence = 0)
    code <- opt$convergence %||% 0
    ok <- isTRUE(code == 0)
  } else if (engine == "betareg") {
    ok <- isTRUE(fit$converged %||% TRUE)
    code <- if (ok) 0 else 1
  } else {
    ok <- TRUE
  }
  list(ok = ok, code = code, messages = messages)
}

#' Fit an agriGLMflow model
#' @export
agri_model <- function(data = NULL, response = NULL, denominator = NULL, design = NULL, formula = NULL,
                       family = "auto", engine = "auto", link = NULL,
                       ziformula = NULL, dispformula = NULL,
                       family_args = list(), engine_args = list(),
                       additive = FALSE, ...) {
  if (!is.null(design)) {
    if (!inherits(design, "agri_design")) .agri_abort("'design' must be an agri_design object.")
    data <- data %||% design$data
    agri_validate_design(design)
  }
  if (is.null(data)) .agri_abort("Provide 'data' directly or through an agri_design object.")

  if (inherits(response, "agri_response")) {
    resp <- response
  } else if (!is.null(response)) {
    resp_name <- if (is.character(response)) response else paste(deparse(substitute(response)), collapse = "")
    if (!is.null(denominator)) {
      denom_name <- if (is.character(denominator)) denominator else paste(deparse(substitute(denominator)), collapse = "")
      resp <- agri_response(data, response = resp_name, denominator = denom_name)
    } else {
      resp <- agri_response(data, response = resp_name)
    }
  } else if (!is.null(formula)) {
    resp_names <- .simple_cbind_response_names(formula)
    if (!is.null(resp_names) && all(resp_names %in% names(data))) {
      resp <- agri_response(data, response = resp_names)
    } else {
      resp_name <- .response_name_from_formula(formula)
      if (length(resp_name) == 1L && resp_name %in% names(data)) resp <- agri_response(data, response = resp_name)
      else resp <- structure(list(name = resp_name, type = "formula_response", multivariate = FALSE, audit = NULL), class = "agri_response")
    }
  } else {
    .agri_abort("Provide 'response' or 'formula'.")
  }

  if (is.null(formula)) {
    if (is.null(design)) {
      .agri_abort("Without an agri_design object, 'formula' must be supplied.")
    }
    lhs <- if (length(resp$name) > 1L) {
      sprintf("cbind(%s)", paste(.bt(resp$name), collapse = ", "))
    } else if (identical(resp$type, "binomial_count") && length(resp$denominator)) {
      sprintf("cbind(%s, %s - %s)", .bt(resp$name), .bt(resp$denominator), .bt(resp$name))
    } else resp$name
    formula <- agri_design_formula(design, lhs)
  }

  family_input <- family
  if (identical(family, "auto")) {
    fs <- agri_family_scan(data, resp, design = design, fit = TRUE, deep = FALSE, formula = formula)
    if (!length(fs$recommended)) .agri_abort("Automatic family screening did not yield a converged and diagnostically admissible candidate family.")
    family <- fs$recommended[1L]
    family_input <- family
  }
  info <- agri_family_info(family_input)
  family_id <- info$id[1L]
  engine <- .route_engine(family_input, design, requested = engine, formula = formula)

  if (engine == "VGAM" && (.check_random_syntax(formula) || .design_has_random(design))) {
    .agri_abort("VGAM cannot be used because this model contains random effects. The current VGAM implementation is fixed-effects only.")
  }

  audit <- NULL
  audit <- .audit_add(audit, "design preservation", design$design %||% "formula_only",
                      if (.design_has_random(design)) "Required random experimental-unit terms retained." else "No required random structure declared.")
  audit <- .audit_add(audit, "family", family_id,
                      sprintf("Family capability specification; validation tier %s.", info$tier[1L]))
  audit <- .audit_add(audit, "engine", engine,
                      sprintf("Engine selected as compatible with family '%s' and declared design.", family_id))

  fit <- switch(engine,
    stats = .fit_stats(formula, data, family_id, link, engine_args),
    brglm2 = .fit_brglm2(formula, data, family_id, link, engine_args),
    glmmTMB = .fit_glmmtmb(formula, data, family_id, link, ziformula, dispformula, family_args, engine_args),
    lme4 = .fit_lme4(formula, data, family_id, link, engine_args),
    GLMMadaptive = .fit_GLMMadaptive(formula, data, family_id, link, ziformula, engine_args),
    gamlss = .fit_gamlss(formula, data, family_input, family_args, engine_args),
    VGAM = .fit_vgam(formula, data, family_input, family_args, engine_args, additive),
    ordinal = .fit_ordinal(formula, data, family_id, engine_args, link %||% "logit"),
    betareg = .fit_betareg(formula, data, family_id, engine_args, link %||% "logit"),
    .agri_abort(sprintf("Engine '%s' has no implemented fitter.", engine))
  )
  conv <- .check_convergence_internal(fit, engine)
  if (!isTRUE(conv$ok)) {
    audit <- .audit_add(audit, "convergence", "warning",
                        paste(conv$messages, collapse = " "), status = "warning")
  } else {
    audit <- .audit_add(audit, "convergence", "accepted", "Backend convergence gate passed.")
  }

  out <- list(
    call = match.call(), data = data, design = design, response = resp,
    formula = formula, family = family_id, family_spec = if (inherits(family_input, "agri_family_spec")) family_input else NULL, family_info = info,
    link = link, engine = engine, engine_fit = fit,
    convergence = conv, ziformula = ziformula, dispformula = dispformula,
    family_args = family_args, engine_args = engine_args,
    diagnostics = NULL, inference = NULL, predictions = NULL,
    model_metrics = list(AIC = .safe_AIC(fit), BIC = .safe_BIC(fit), logLik = .safe_logLik(fit)),
    warnings = conv$messages, audit = audit,
    session = list(R = R.version.string, engine_version = .package_version_safe(if (engine == "stats") "stats" else engine))
  )
  class(out) <- "agri_model"
  out
}

#' Fit a generalized linear model
#' @export
agri_glm <- function(..., family = "gaussian", engine = "stats") {
  agri_model(..., family = family, engine = engine)
}

#' Fit a generalized linear mixed model
#' @export
agri_glmm <- function(..., family = "nbinom2", engine = "glmmTMB") {
  agri_model(..., family = family, engine = engine)
}

#' Fit a GAMLSS model
#' @export
agri_gamlss <- function(..., family = "gamlss_GA", sigma = NULL, nu = NULL, tau = NULL,
                         engine_args = list()) {
  if (!is.null(sigma)) engine_args$sigma.formula <- sigma
  if (!is.null(nu)) engine_args$nu.formula <- nu
  if (!is.null(tau)) engine_args$tau.formula <- tau
  agri_model(..., family = family, engine = "gamlss", engine_args = engine_args)
}

#' Fit a vector generalized model with VGAM
#' @export
agri_vglm <- function(..., family, additive = FALSE) {
  agri_model(..., family = family, engine = "VGAM", additive = additive)
}

#' Fit a multinomial response with VGAM
#' @export
agri_multinomial <- function(data, formula, ref_level = NULL, parallel = FALSE,
                             additive = FALSE, engine_args = list()) {
  fam_args <- list(parallel = parallel)
  if (!is.null(ref_level)) fam_args$refLevel <- ref_level
  agri_model(data = data, formula = formula, family = "vgam_multinomial",
             engine = "VGAM", family_args = fam_args,
             engine_args = engine_args, additive = additive)
}

#' Fit compositional or Dirichlet-multinomial responses with VGAM
#' @export
agri_composition <- function(data, formula, family = c("dirichlet", "dirmultinomial"),
                             additive = FALSE, family_args = list(), engine_args = list()) {
  family <- match.arg(family)
  id <- if (family == "dirichlet") "vgam_dirichlet" else "vgam_dirmultinomial"
  agri_model(data = data, formula = formula, family = id, engine = "VGAM",
             family_args = family_args, engine_args = engine_args, additive = additive)
}

#' Fit a censored response using a registered VGAM family
#' @export
agri_censored <- function(data, formula, family = c("normal", "poisson"),
                          family_args = list(), engine_args = list()) {
  family <- match.arg(family)
  id <- if (family == "normal") "vgam_cens_normal" else "vgam_cens_poisson"
  agri_model(data = data, formula = formula, family = id, engine = "VGAM",
             family_args = family_args, engine_args = engine_args)
}

#' Fit ordinal models
#' @export
agri_ordinal <- function(data, formula, design = NULL,
                         model = c("auto", "cumulative", "partial_proportional",
                                   "adjacent", "continuation", "stopping"),
                         link = "logit", parallel = NULL, family_args = list(), ...) {
  model <- match.arg(model)
  random <- .design_has_random(design) || .check_random_syntax(formula)
  if (model == "auto") model <- if (random) "cumulative" else "cumulative"
  if (random) {
    if (model != "cumulative") {
      .agri_abort("Random-effects ordinal models currently use ordinal::clmm; VGAM adjacent/continuation/stopping models are fixed-effects only.")
    }
    return(agri_model(data = data, formula = formula, design = design,
                      family = "ordinal_clmm", engine = "ordinal", link = link, ...))
  }
  if (model == "cumulative") {
    par_arg <- parallel %||% TRUE
    return(agri_model(data = data, formula = formula, design = design,
                      family = "vgam_cumulative", engine = "VGAM",
                      family_args = c(list(parallel = par_arg), family_args), ...))
  }
  if (model == "partial_proportional") {
    if (!inherits(parallel, "formula")) {
      .agri_abort("Partial proportional-odds models require 'parallel' to be a VGAM constraint formula, e.g. parallel = TRUE ~ -1 + treatment.")
    }
    return(agri_model(data = data, formula = formula, design = design,
                      family = "vgam_cumulative", engine = "VGAM",
                      family_args = c(list(parallel = parallel), family_args), ...))
  }
  id <- switch(model, adjacent = "vgam_acat", continuation = "vgam_cratio", stopping = "vgam_sratio")
  agri_model(data = data, formula = formula, design = design,
             family = id, engine = "VGAM", family_args = family_args, ...)
}


#' Check the proportional-odds parallelism assumption for a VGAM cumulative model
#' @export
agri_check_parallel <- function(object, refit_nonparallel = TRUE) {
  if (!inherits(object, "agri_model")) .agri_abort("'object' must be an agri_model.")
  if (object$engine != "VGAM" || object$family != "vgam_cumulative") {
    .agri_abort("agri_check_parallel() currently requires a VGAM cumulative ordinal model.")
  }
  par_spec <- object$family_args$parallel %||% FALSE
  is_prop <- isTRUE(par_spec)
  if (!is_prop && !inherits(par_spec, "formula")) {
    return(structure(list(status = "nonparallel_model", test = NULL,
                          note = "The fitted cumulative model is already non-proportional; no nested proportional-odds LRT was requested."),
                     class = "agri_parallel_check"))
  }
  if (inherits(par_spec, "formula")) {
    return(structure(list(status = "partial_proportional_model", test = NULL,
                          note = "A partial proportional-odds constraint formula is already in use. Compare scientifically nested constraint structures explicitly."),
                     class = "agri_parallel_check"))
  }
  if (!isTRUE(refit_nonparallel)) {
    return(structure(list(status = "proportional_model", test = NULL,
                          note = "Set refit_nonparallel = TRUE to compare against the nested non-parallel cumulative model."),
                     class = "agri_parallel_check"))
  }
  alt <- try(agri_model(data = object$data, formula = object$formula,
                        family = "vgam_cumulative", engine = "VGAM",
                        family_args = modifyList(object$family_args, list(parallel = FALSE)),
                        engine_args = object$engine_args), silent = TRUE)
  if (inherits(alt, "try-error")) .agri_abort("The non-parallel VGAM comparison model could not be fitted.")
  ll0 <- stats::logLik(object$engine_fit); ll1 <- stats::logLik(alt$engine_fit)
  stat <- 2 * (as.numeric(ll1) - as.numeric(ll0))
  df0 <- attr(ll0, "df") %||% length(stats::coef(object$engine_fit))
  df1 <- attr(ll1, "df") %||% length(stats::coef(alt$engine_fit))
  ddf <- as.numeric(df1 - df0)
  p <- if (is.finite(stat) && is.finite(ddf) && ddf > 0) stats::pchisq(stat, df = ddf, lower.tail = FALSE) else NA_real_
  tab <- data.frame(statistic = stat, df = ddf, p.value = p)
  structure(list(status = "tested", test = tab, proportional = object,
                 nonparallel = alt,
                 note = "Likelihood-ratio comparison of proportional versus non-parallel cumulative models; inspect convergence and sparse categories before interpretation."),
            class = "agri_parallel_check")
}

#' Refit an agriGLMflow model with modified settings
#' @export
agri_refit <- function(object, family = object$family_spec %||% object$family, engine = "auto", formula = object$formula,
                       data = object$data, ...) {
  if (!inherits(object, "agri_model")) .agri_abort("'object' must be an agri_model.")
  agri_model(data = data, response = object$response, design = object$design,
             formula = formula, family = family, engine = engine, ...)
}

#' Fit sensitivity alternatives to a model
#' @export
agri_sensitivity <- function(object, families = NULL, deep = FALSE, ...) {
  if (!inherits(object, "agri_model")) .agri_abort("'object' must be an agri_model.")
  if (is.null(families)) {
    families <- agri_family_candidates(object$response, object$design, tier = 2L)
    families <- setdiff(families, object$family)
  }
  scan <- agri_family_scan(object$data, object$response, object$design,
                           candidates = families, fit = TRUE, deep = deep,
                           formula = object$formula, ...)
  scan
}

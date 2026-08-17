#' List modelling engines and their current availability
#' @export
agri_engines <- function() {
  pkgs <- c(stats = "stats", glmmTMB = "glmmTMB", lme4 = "lme4",
            GLMMadaptive = "GLMMadaptive", gamlss = "gamlss", VGAM = "VGAM",
            ordinal = "ordinal", betareg = "betareg", brglm2 = "brglm2",
            mgcv = "mgcv", brms = "brms")
  data.frame(
    engine = names(pkgs),
    package = unname(pkgs),
    available = vapply(pkgs, requireNamespace, logical(1), quietly = TRUE),
    version = vapply(pkgs, .package_version_safe, character(1)),
    stringsAsFactors = FALSE
  )
}

#' Report optional dependencies
#' @export
agri_dependencies <- function() {
  x <- agri_engines()
  feature <- c(
    stats = "base GLM", glmmTMB = "advanced GLMM", lme4 = "reference GLMM",
    GLMMadaptive = "adaptive-quadrature GLMM", gamlss = "distributional regression",
    VGAM = "vector, multinomial, ordinal and compositional models",
    ordinal = "ordinal mixed models", betareg = "beta regression",
    brglm2 = "bias-reduced GLM", mgcv = "smooth regression", brms = "Bayesian extension"
  )
  x$feature <- unname(feature[x$engine])
  x
}

.route_engine <- function(family, design = NULL, requested = "auto", formula = NULL) {
  info <- agri_family_info(family)
  has_random <- .design_has_random(design) || (!is.null(formula) && .check_random_syntax(formula))

  if (!identical(requested, "auto")) {
    if (requested == "VGAM" && has_random) {
      .agri_abort(paste0(
        "VGAM backend rejected: the declared experimental design requires random experimental-unit effects, ",
        "while the current VGAM implementation is fixed-effects only. Choose a compatible family/engine or explicitly ",
        "declare blocking effects as fixed when scientifically justified."
      ))
    }
    if (has_random && requested %in% c("stats", "gamlss", "betareg", "brglm2")) {
      .agri_abort(sprintf(
        "Engine '%s' cannot preserve the random structure required by the declared design.", requested
      ))
    }
    return(requested)
  }

  engine <- info$engine[1L]
  if (has_random && !isTRUE(info$random_effects[1L])) {
    compatible <- .family_registry()
    compatible <- compatible[compatible$random_effects & compatible$response_type == info$response_type[1L], , drop = FALSE]
    .agri_abort(sprintf(
      paste0("Family '%s' is registered through engine '%s', which cannot preserve the declared random structure. ",
             "Select a random-effects-compatible family. Candidate IDs include: %s."),
      info$id[1L], engine, paste(utils::head(compatible$id, 8L), collapse = ", ")
    ))
  }
  if (has_random && engine == "stats") {
    if (requireNamespace("glmmTMB", quietly = TRUE)) return("glmmTMB")
    if (requireNamespace("lme4", quietly = TRUE) && info$id[1L] %in% c("gaussian", "poisson", "binomial", "Gamma", "inverse.gaussian", "nbinom2")) return("lme4")
    if (requireNamespace("GLMMadaptive", quietly = TRUE) && info$id[1L] %in%
        c("poisson", "binomial", "Gamma", "nbinom2", "beta", "betabinomial",
          "zip", "zinb2", "hurdle_poisson", "hurdle_nbinom2")) return("GLMMadaptive")
    .agri_abort("The design requires random effects, but no compatible mixed-model engine is installed. Install 'glmmTMB' (preferred), 'lme4', or 'GLMMadaptive' for a supported family.")
  }
  if (has_random && engine == "glmmTMB" && !requireNamespace("glmmTMB", quietly = TRUE)) {
    if (info$id[1L] == "nbinom2" && requireNamespace("lme4", quietly = TRUE)) return("lme4")
    if (info$id[1L] %in% c("nbinom2", "poisson", "binomial", "Gamma", "beta", "betabinomial",
                            "zip", "zinb2", "hurdle_poisson", "hurdle_nbinom2") &&
        requireNamespace("GLMMadaptive", quietly = TRUE)) return("GLMMadaptive")
  }
  engine
}

.make_stats_family <- function(id, link = NULL) {
  fn <- switch(id,
    gaussian = stats::gaussian,
    poisson = stats::poisson,
    quasipoisson = stats::quasipoisson,
    binomial = stats::binomial,
    quasibinomial = stats::quasibinomial,
    Gamma = stats::Gamma,
    inverse.gaussian = stats::inverse.gaussian,
    NULL
  )
  if (is.null(fn)) .agri_abort(sprintf("No base-R family constructor registered for '%s'.", id))
  if (is.null(link)) fn() else fn(link = link)
}

.make_glmmtmb_family <- function(id, link = NULL) {
  .require_pkg("glmmTMB", "glmmTMB family construction")
  base_id <- switch(id,
    zip = "poisson", zinb1 = "nbinom1", zinb2 = "nbinom2",
    zicomp = "compois", zigenpois = "genpois",
    hurdle_poisson = "truncated_poisson",
    hurdle_nbinom1 = "truncated_nbinom1",
    hurdle_nbinom2 = "truncated_nbinom2", id
  )
  fun_name <- switch(base_id,
    poisson = NULL,
    binomial = NULL,
    gaussian = NULL,
    Gamma = NULL,
    nbinom1 = "nbinom1", nbinom2 = "nbinom2", compois = "compois",
    genpois = "genpois", betabinomial = "betabinomial", beta = "beta_family",
    ordbeta = "ordbeta", tweedie = "tweedie", lognormal = "lognormal",
    student_t = "t_family", truncated_poisson = "truncated_poisson",
    truncated_nbinom1 = "truncated_nbinom1", truncated_nbinom2 = "truncated_nbinom2",
    NULL
  )
  if (is.null(fun_name)) {
    return(.make_stats_family(base_id, link = link))
  }
  fn <- getExportedValue("glmmTMB", fun_name)
  if (is.null(link)) fn() else fn(link = link)
}

.make_gamlss_family <- function(id, family_args = list()) {
  info <- agri_family_info(id)
  fn_name <- info$engine_family[1L]
  # Most standard families live in gamlss.dist, but expert users may reference
  # a constructor exported by gamlss itself.
  fn <- NULL
  if (requireNamespace("gamlss.dist", quietly = TRUE)) {
    fn <- try(getExportedValue("gamlss.dist", fn_name), silent = TRUE)
    if (inherits(fn, "try-error")) fn <- NULL
  }
  if (is.null(fn) && requireNamespace("gamlss", quietly = TRUE)) {
    fn <- try(getExportedValue("gamlss", fn_name), silent = TRUE)
    if (inherits(fn, "try-error")) fn <- NULL
  }
  if (is.null(fn)) .agri_abort(sprintf("GAMLSS family constructor '%s' is unavailable in installed GAMLSS packages.", fn_name))
  do.call(fn, family_args)
}

.make_vgam_family <- function(id, family_args = list()) {
  .require_pkg("VGAM", "VGAM modelling")
  info <- agri_family_info(id)
  fn_name <- info$engine_family[1L]
  fn <- try(getExportedValue("VGAM", fn_name), silent = TRUE)
  if (inherits(fn, "try-error")) {
    .agri_abort(sprintf("VGAM family constructor '%s' is unavailable in the installed VGAM version.", fn_name))
  }
  do.call(fn, family_args)
}

.family_default_zi <- function(id) {
  if (id %in% c("zip", "zinb1", "zinb2", "zicomp", "zigenpois",
                "hurdle_poisson", "hurdle_nbinom1", "hurdle_nbinom2")) stats::as.formula("~1") else stats::as.formula("~0")
}

.make_glmmadaptive_family <- function(id, link = NULL) {
  .require_pkg("GLMMadaptive", "adaptive-quadrature generalized linear mixed modelling")
  if (!is.null(link) && id %in% c("nbinom2", "beta", "betabinomial", "zip", "zinb2",
                                  "hurdle_poisson", "hurdle_nbinom2")) {
    .agri_warn("The requested link is controlled by the GLMMadaptive family constructor and may not be configurable through agriGLMflow.")
  }
  switch(id,
    poisson = stats::poisson(link = link %||% "log"),
    binomial = stats::binomial(link = link %||% "logit"),
    Gamma = GLMMadaptive::Gamma.fam(),
    nbinom2 = GLMMadaptive::negative.binomial(),
    beta = GLMMadaptive::beta.fam(),
    betabinomial = GLMMadaptive::beta.binomial(),
    zip = GLMMadaptive::zi.poisson(),
    zinb2 = GLMMadaptive::zi.negative.binomial(),
    hurdle_poisson = GLMMadaptive::hurdle.poisson(),
    hurdle_nbinom2 = GLMMadaptive::hurdle.negative.binomial(),
    .agri_abort(sprintf("Family '%s' is not mapped to GLMMadaptive.", id))
  )
}

.split_top_level_plus <- function(x) {
  chars <- strsplit(x, "", fixed = TRUE)[[1L]]
  depth <- 0L; quote <- NULL; start <- 1L; out <- character()
  for (i in seq_along(chars)) {
    ch <- chars[i]
    if (!is.null(quote)) {
      if (ch == quote && (i == 1L || chars[i - 1L] != "\\")) quote <- NULL
      next
    }
    if (ch %in% c("`", "\"", "'")) { quote <- ch; next }
    if (ch == "(") depth <- depth + 1L
    if (ch == ")") depth <- max(0L, depth - 1L)
    if (ch == "+" && depth == 0L) {
      out <- c(out, trimws(substr(x, start, i - 1L)))
      start <- i + 1L
    }
  }
  out <- c(out, trimws(substr(x, start, nchar(x))))
  out[nzchar(out)]
}

.split_single_random_formula <- function(formula) {
  txt <- paste(deparse(formula), collapse = " ")
  if (grepl("\\b(ar1|cs|toep|us)\\s*\\(", txt, perl = TRUE)) {
    .agri_abort("GLMMadaptive does not represent the requested structured covariance term through this interface. Use glmmTMB or another compatible engine.")
  }
  lhs <- paste(deparse(formula[[2L]]), collapse = "")
  rhs <- paste(deparse(formula[[3L]]), collapse = "")
  terms <- .split_top_level_plus(rhs)
  is_random <- grepl("\\|", terms)
  rterms <- terms[is_random]
  fterms <- terms[!is_random]
  if (length(rterms) != 1L) {
    .agri_abort("GLMMadaptive integration requires exactly one random-effects term because the backend supports one grouping factor in this workflow.")
  }
  rt <- trimws(rterms[1L])
  if (startsWith(rt, "(") && endsWith(rt, ")")) rt <- substr(rt, 2L, nchar(rt) - 1L)
  pieces <- strsplit(rt, "\\|", perl = TRUE)[[1L]]
  if (length(pieces) != 2L) .agri_abort("Unable to parse the GLMMadaptive random-effects term.")
  group <- trimws(pieces[2L])
  if (grepl("/", group, fixed = TRUE)) .agri_abort("Nested grouping shorthand is not accepted by the GLMMadaptive router. Use a single explicit grouping factor.")
  fixed_rhs <- if (length(fterms)) paste(fterms, collapse = " + ") else "1"
  list(
    fixed = stats::as.formula(sprintf("%s ~ %s", lhs, fixed_rhs), env = environment(formula)),
    random = stats::as.formula(sprintf("~ %s", rt), env = environment(formula)),
    group = group
  )
}

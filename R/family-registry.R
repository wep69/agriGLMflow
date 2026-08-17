.family_row <- function(id, label, response_type, domain, engine, engine_family,
                        random_effects = FALSE, multivariate = FALSE,
                        multiparameter = FALSE, smooth = FALSE,
                        zero_inflation = FALSE, hurdle = FALSE,
                        truncation = FALSE, censoring = FALSE,
                        simulation = TRUE, posthoc_mode = "mean",
                        tier = 1L, notes = "") {
  data.frame(
    id = id,
    label = label,
    response_type = response_type,
    domain = domain,
    engine = engine,
    engine_family = engine_family,
    random_effects = random_effects,
    multivariate = multivariate,
    multiparameter = multiparameter,
    smooth = smooth,
    zero_inflation = zero_inflation,
    hurdle = hurdle,
    truncation = truncation,
    censoring = censoring,
    simulation = simulation,
    posthoc_mode = posthoc_mode,
    tier = as.integer(tier),
    notes = notes,
    stringsAsFactors = FALSE
  )
}

.family_registry <- function() {
  rows <- list(
    .family_row("gaussian", "Gaussian", "continuous|continuous_positive", "continuous", "stats", "gaussian", TRUE),
    .family_row("poisson", "Poisson", "count", "count", "stats", "poisson", TRUE),
    .family_row("quasipoisson", "Quasi-Poisson", "count", "count", "stats", "quasipoisson", FALSE, tier = 2, notes = "Not comparable by AIC to full-likelihood models."),
    .family_row("binomial", "Binomial", "binary|binomial_count", "binomial", "stats", "binomial", TRUE),
    .family_row("quasibinomial", "Quasi-binomial", "binary|binomial_count", "binomial", "stats", "quasibinomial", FALSE, tier = 2, notes = "Not comparable by AIC to full-likelihood models."),
    .family_row("Gamma", "Gamma", "continuous_positive", "positive_continuous", "stats", "Gamma", TRUE),
    .family_row("inverse.gaussian", "Inverse Gaussian", "continuous_positive", "positive_continuous", "stats", "inverse.gaussian", FALSE),

    .family_row("nbinom1", "Negative binomial 1", "count", "count", "glmmTMB", "nbinom1", TRUE),
    .family_row("nbinom2", "Negative binomial 2", "count", "count", "glmmTMB", "nbinom2", TRUE),
    .family_row("compois", "Conway-Maxwell-Poisson", "count", "count", "glmmTMB", "compois", TRUE),
    .family_row("genpois", "Generalized Poisson", "count", "count", "glmmTMB", "genpois", TRUE),
    .family_row("betabinomial", "Beta-binomial", "binomial_count", "overdispersed_binomial", "glmmTMB", "betabinomial", TRUE),
    .family_row("beta", "Beta", "proportion_open", "continuous_proportion", "glmmTMB", "beta_family", TRUE),
    .family_row("ordbeta", "Ordered beta", "proportion_closed", "closed_proportion", "glmmTMB", "ordbeta", TRUE),
    .family_row("tweedie", "Tweedie", "continuous_positive|semicontinuous", "positive_continuous", "glmmTMB", "tweedie", TRUE, multiparameter = TRUE),
    .family_row("lognormal", "Lognormal", "continuous_positive", "positive_continuous", "glmmTMB", "lognormal", TRUE),
    .family_row("student_t", "Student t", "continuous|continuous_positive", "continuous", "glmmTMB", "t_family", TRUE, multiparameter = TRUE, tier = 2),
    .family_row("truncated_poisson", "Zero-truncated Poisson", "count", "truncated_count", "glmmTMB", "truncated_poisson", TRUE, truncation = TRUE, tier = 2),
    .family_row("truncated_nbinom1", "Zero-truncated NB1", "count", "truncated_count", "glmmTMB", "truncated_nbinom1", TRUE, truncation = TRUE, tier = 2),
    .family_row("truncated_nbinom2", "Zero-truncated NB2", "count", "truncated_count", "glmmTMB", "truncated_nbinom2", TRUE, truncation = TRUE, tier = 2),
    .family_row("zip", "Zero-inflated Poisson", "count", "zero_inflated_count", "glmmTMB", "poisson", TRUE, zero_inflation = TRUE),
    .family_row("zinb1", "Zero-inflated NB1", "count", "zero_inflated_count", "glmmTMB", "nbinom1", TRUE, zero_inflation = TRUE),
    .family_row("zinb2", "Zero-inflated NB2", "count", "zero_inflated_count", "glmmTMB", "nbinom2", TRUE, zero_inflation = TRUE),
    .family_row("zicomp", "Zero-inflated COM-Poisson", "count", "zero_inflated_count", "glmmTMB", "compois", TRUE, zero_inflation = TRUE, tier = 2),
    .family_row("zigenpois", "Zero-inflated generalized Poisson", "count", "zero_inflated_count", "glmmTMB", "genpois", TRUE, zero_inflation = TRUE, tier = 2),
    .family_row("hurdle_poisson", "Hurdle Poisson", "count", "hurdle_count", "glmmTMB", "truncated_poisson", TRUE, hurdle = TRUE),
    .family_row("hurdle_nbinom1", "Hurdle negative binomial 1", "count", "hurdle_count", "glmmTMB", "truncated_nbinom1", TRUE, hurdle = TRUE, tier = 2),
    .family_row("hurdle_nbinom2", "Hurdle negative binomial 2", "count", "hurdle_count", "glmmTMB", "truncated_nbinom2", TRUE, hurdle = TRUE),

    .family_row("gamlss_GA", "GAMLSS Gamma", "continuous_positive", "distributional", "gamlss", "GA", FALSE, multiparameter = TRUE, smooth = TRUE),
    .family_row("gamlss_LOGNO", "GAMLSS lognormal", "continuous_positive", "distributional", "gamlss", "LOGNO", FALSE, multiparameter = TRUE, smooth = TRUE),
    .family_row("gamlss_NBI", "GAMLSS Negative Binomial I", "count", "distributional", "gamlss", "NBI", FALSE, multiparameter = TRUE, smooth = TRUE, tier = 2),
    .family_row("gamlss_NBII", "GAMLSS Negative Binomial II", "count", "distributional", "gamlss", "NBII", FALSE, multiparameter = TRUE, smooth = TRUE, tier = 2),
    .family_row("gamlss_BE", "GAMLSS Beta", "proportion_open", "distributional", "gamlss", "BE", FALSE, multiparameter = TRUE, smooth = TRUE),
    .family_row("gamlss_BEINF", "GAMLSS zero/one inflated beta", "proportion_closed", "distributional", "gamlss", "BEINF", FALSE, multiparameter = TRUE, smooth = TRUE, zero_inflation = TRUE, tier = 2),

    # Extended GAMLSS registry. These families are Tier 2 until the dedicated
    # runtime validation matrix has passed on all supported platforms.
    .family_row("gamlss_NO", "GAMLSS Normal", "continuous|continuous_positive", "distributional", "gamlss", "NO", FALSE, multiparameter = TRUE, smooth = TRUE, tier = 2),
    .family_row("gamlss_TF", "GAMLSS Student t", "continuous|continuous_positive", "distributional", "gamlss", "TF", FALSE, multiparameter = TRUE, smooth = TRUE, tier = 2),
    .family_row("gamlss_PE", "GAMLSS Power Exponential", "continuous|continuous_positive", "distributional", "gamlss", "PE", FALSE, multiparameter = TRUE, smooth = TRUE, tier = 2),
    .family_row("gamlss_SHASH", "GAMLSS Sinh-Arcsinh", "continuous|continuous_positive", "distributional", "gamlss", "SHASH", FALSE, multiparameter = TRUE, smooth = TRUE, tier = 2),
    .family_row("gamlss_JSU", "GAMLSS Johnson SU", "continuous|continuous_positive", "distributional", "gamlss", "JSU", FALSE, multiparameter = TRUE, smooth = TRUE, tier = 2),
    .family_row("gamlss_GG", "GAMLSS Generalized Gamma", "continuous_positive", "distributional", "gamlss", "GG", FALSE, multiparameter = TRUE, smooth = TRUE, tier = 2),
    .family_row("gamlss_IG", "GAMLSS Inverse Gaussian", "continuous_positive", "distributional", "gamlss", "IG", FALSE, multiparameter = TRUE, smooth = TRUE, tier = 2),
    .family_row("gamlss_WEI", "GAMLSS Weibull", "continuous_positive", "distributional", "gamlss", "WEI", FALSE, multiparameter = TRUE, smooth = TRUE, tier = 2),
    .family_row("gamlss_BCCG", "GAMLSS Box-Cox Cole-Green", "continuous_positive", "distributional", "gamlss", "BCCG", FALSE, multiparameter = TRUE, smooth = TRUE, tier = 2),
    .family_row("gamlss_BCPE", "GAMLSS Box-Cox Power Exponential", "continuous_positive", "distributional", "gamlss", "BCPE", FALSE, multiparameter = TRUE, smooth = TRUE, tier = 2),
    .family_row("gamlss_BCT", "GAMLSS Box-Cox t", "continuous_positive", "distributional", "gamlss", "BCT", FALSE, multiparameter = TRUE, smooth = TRUE, tier = 2),
    .family_row("gamlss_PIG", "GAMLSS Poisson-inverse Gaussian", "count", "distributional_count", "gamlss", "PIG", FALSE, multiparameter = TRUE, smooth = TRUE, tier = 2),
    .family_row("gamlss_GPO", "GAMLSS Generalized Poisson", "count", "distributional_count", "gamlss", "GPO", FALSE, multiparameter = TRUE, smooth = TRUE, tier = 2),
    .family_row("gamlss_DPO", "GAMLSS Double Poisson", "count", "distributional_count", "gamlss", "DPO", FALSE, multiparameter = TRUE, smooth = TRUE, tier = 2),
    .family_row("gamlss_SICHEL", "GAMLSS Sichel", "count", "distributional_count", "gamlss", "SICHEL", FALSE, multiparameter = TRUE, smooth = TRUE, tier = 2),
    .family_row("gamlss_BNB", "GAMLSS Beta Negative Binomial", "count", "distributional_count", "gamlss", "BNB", FALSE, multiparameter = TRUE, smooth = TRUE, tier = 2),
    .family_row("gamlss_BB", "GAMLSS Beta Binomial", "binomial_count", "distributional_binomial", "gamlss", "BB", FALSE, multiparameter = TRUE, smooth = TRUE, tier = 2),
    .family_row("gamlss_SIMPLEX", "GAMLSS Simplex", "proportion_open", "distributional_proportion", "gamlss", "SIMPLEX", FALSE, multiparameter = TRUE, smooth = TRUE, tier = 2),
    .family_row("gamlss_BEZI", "GAMLSS zero-inflated beta", "proportion_closed", "distributional_proportion", "gamlss", "BEZI", FALSE, multiparameter = TRUE, smooth = TRUE, zero_inflation = TRUE, tier = 2, notes = "Admissible only when the boundary mass is at zero, not at one."),
    .family_row("gamlss_BEOI", "GAMLSS one-inflated beta", "proportion_closed", "distributional_proportion", "gamlss", "BEOI", FALSE, multiparameter = TRUE, smooth = TRUE, zero_inflation = TRUE, tier = 2, notes = "Admissible only when the boundary mass is at one, not at zero."),
    .family_row("gamlss_ZAGA", "GAMLSS zero-adjusted Gamma", "semicontinuous", "zero_adjusted_positive", "gamlss", "ZAGA", FALSE, multiparameter = TRUE, smooth = TRUE, zero_inflation = TRUE, tier = 2),
    .family_row("gamlss_ZAIG", "GAMLSS zero-adjusted Inverse Gaussian", "semicontinuous", "zero_adjusted_positive", "gamlss", "ZAIG", FALSE, multiparameter = TRUE, smooth = TRUE, zero_inflation = TRUE, tier = 2),

    .family_row("extended_beta", "Extended-support beta", "proportion_closed", "closed_proportion", "betareg", "xbetax", FALSE, multiparameter = TRUE, tier = 1, notes = "Requires a recent betareg version supporting extended-support beta regression."),

    .family_row("ordinal_clm", "Cumulative link model", "ordinal", "ordinal", "ordinal", "clm", FALSE, posthoc_mode = "category_probability"),
    .family_row("ordinal_clmm", "Cumulative link mixed model", "ordinal", "ordinal", "ordinal", "clmm", TRUE, posthoc_mode = "category_probability"),

    .family_row("vgam_multinomial", "Multinomial logit", "categorical_nominal", "nominal_multinomial", "VGAM", "multinomial", FALSE, multivariate = TRUE, multiparameter = TRUE, smooth = TRUE, posthoc_mode = "category_probability"),
    .family_row("vgam_cumulative", "VGAM cumulative ordinal", "ordinal", "ordinal", "VGAM", "cumulative", FALSE, multivariate = TRUE, multiparameter = TRUE, smooth = TRUE, posthoc_mode = "category_probability"),
    .family_row("vgam_acat", "Adjacent-category ordinal", "ordinal", "ordinal", "VGAM", "acat", FALSE, multivariate = TRUE, multiparameter = TRUE, smooth = TRUE, posthoc_mode = "category_probability"),
    .family_row("vgam_cratio", "Continuation-ratio ordinal", "ordinal", "ordinal", "VGAM", "cratio", FALSE, multivariate = TRUE, multiparameter = TRUE, smooth = TRUE, posthoc_mode = "category_probability"),
    .family_row("vgam_sratio", "Stopping-ratio ordinal", "ordinal", "ordinal", "VGAM", "sratio", FALSE, multivariate = TRUE, multiparameter = TRUE, smooth = TRUE, posthoc_mode = "category_probability"),
    .family_row("vgam_dirichlet", "Dirichlet regression", "composition", "composition", "VGAM", "dirichlet", FALSE, multivariate = TRUE, multiparameter = TRUE, smooth = TRUE, posthoc_mode = "composition"),
    .family_row("vgam_dirmultinomial", "Dirichlet-multinomial", "categorical_counts", "composition_counts", "VGAM", "dirmultinomial", FALSE, multivariate = TRUE, multiparameter = TRUE, smooth = TRUE, posthoc_mode = "category_probability"),
    .family_row("vgam_simplex", "Simplex", "proportion_open", "continuous_proportion", "VGAM", "simplex", FALSE, multiparameter = TRUE, smooth = TRUE),
    .family_row("vgam_betabinomial", "VGAM beta-binomial", "binomial_count", "overdispersed_binomial", "VGAM", "betabinomial", FALSE, multiparameter = TRUE, smooth = TRUE, tier = 2),
    .family_row("vgam_extbetabinomial", "Extended beta-binomial", "binomial_count", "overdispersed_binomial", "VGAM", "extbetabinomial", FALSE, multiparameter = TRUE, smooth = TRUE),
    .family_row("vgam_negbinomial", "VGAM negative binomial", "count", "count", "VGAM", "negbinomial", FALSE, multiparameter = TRUE, smooth = TRUE, tier = 2),
    .family_row("vgam_genpoisson1", "VGAM generalized Poisson GP-1", "count", "count", "VGAM", "genpoisson1", FALSE, multiparameter = TRUE, smooth = TRUE, tier = 1),
    .family_row("vgam_genpoisson2", "VGAM generalized Poisson GP-2", "count", "count", "VGAM", "genpoisson2", FALSE, multiparameter = TRUE, smooth = TRUE, tier = 1),
    .family_row("vgam_pospoisson", "Positive Poisson", "count", "truncated_count", "VGAM", "pospoisson", FALSE, truncation = TRUE, smooth = TRUE, tier = 2),
    .family_row("vgam_zapoisson", "Zero-altered Poisson", "count", "hurdle_count", "VGAM", "zapoisson", FALSE, multiparameter = TRUE, smooth = TRUE, hurdle = TRUE, tier = 1),
    .family_row("vgam_zanegbinomial", "Zero-altered negative binomial", "count", "hurdle_count", "VGAM", "zanegbinomialff", FALSE, multiparameter = TRUE, smooth = TRUE, hurdle = TRUE, tier = 2, notes = "Fragile family; advanced validation required."),
    .family_row("vgam_zipoisson", "VGAM zero-inflated Poisson", "count", "zero_inflated_count", "VGAM", "zipoisson", FALSE, multiparameter = TRUE, smooth = TRUE, zero_inflation = TRUE, tier = 2),
    .family_row("vgam_zinegbinomial", "VGAM zero-inflated negative binomial", "count", "zero_inflated_count", "VGAM", "zinegbinomialff", FALSE, multiparameter = TRUE, smooth = TRUE, zero_inflation = TRUE, tier = 2, notes = "Numerically fragile in some regimes; advanced validation required."),
    .family_row("vgam_cens_normal", "Censored normal", "censored_continuous", "censored", "VGAM", "cens.normal", FALSE, censoring = TRUE, tier = 2),
    .family_row("vgam_cens_poisson", "Censored Poisson", "censored_count", "censored", "VGAM", "cens.poisson", FALSE, censoring = TRUE, tier = 2),
    .family_row("vgam_gev", "Generalized extreme value", "extreme", "extreme_value", "VGAM", "gev", FALSE, multiparameter = TRUE, smooth = TRUE, tier = 2),
    .family_row("vgam_gpd", "Generalized Pareto", "extreme", "extreme_value", "VGAM", "gpd", FALSE, multiparameter = TRUE, smooth = TRUE, tier = 2)
  )
  do.call(rbind, rows)
}

#' List registered families
#' @export
agri_families <- function(tier = NULL, engine = NULL, response_type = NULL) {
  x <- .family_registry()
  if (!is.null(tier)) x <- x[x$tier %in% tier, , drop = FALSE]
  if (!is.null(engine)) x <- x[x$engine %in% engine, , drop = FALSE]
  if (!is.null(response_type)) {
    keep <- vapply(strsplit(x$response_type, "\\|"), function(z) response_type %in% z, logical(1))
    x <- x[keep, , drop = FALSE]
  }
  rownames(x) <- NULL
  x
}

#' Inspect one registered family
#' @export
agri_family_info <- function(family) {
  if (inherits(family, "agri_family_spec")) {
    z <- unclass(family)
    return(data.frame(
      id=z$id,label=z$label,response_type=z$response_type,domain=z$domain,
      engine=z$engine,engine_family=z$engine_family,random_effects=z$random_effects,
      multivariate=z$multivariate,multiparameter=z$multiparameter,smooth=z$smooth,
      zero_inflation=z$zero_inflation,hurdle=z$hurdle,truncation=z$truncation,
      censoring=z$censoring,simulation=as.logical(z$simulation),posthoc_mode=z$posthoc_mode,
      tier=as.integer(z$tier),notes=z$notes,stringsAsFactors=FALSE
    ))
  }
  reg <- .family_registry()
  out <- reg[reg$id == family, , drop = FALSE]
  if (!nrow(out)) .agri_abort(sprintf("Family '%s' is not registered. Use agri_families() or agri_family_spec() for an expert backend family.", family))
  out
}

#' Return family candidates for a response
#' @export
agri_family_candidates <- function(response, design = NULL, tier = 1L, include_sensitivity = TRUE) {
  if (!inherits(response, "agri_response")) .agri_abort("'response' must be an agri_response object.")
  reg <- .family_registry()
  reg <- reg[reg$tier <= max(tier), , drop = FALSE]
  type <- response$type
  keep <- vapply(strsplit(reg$response_type, "\\|"), function(z) type %in% z, logical(1))
  cand <- reg[keep, , drop = FALSE]

  if (type == "proportion_closed") {
    bp <- response$boundary_pattern %||% "zero_and_one"
    if (identical(bp, "zero_only")) cand <- cand[cand$id != "gamlss_BEOI", , drop = FALSE]
    if (identical(bp, "one_only")) cand <- cand[cand$id != "gamlss_BEZI", , drop = FALSE]
    if (identical(bp, "zero_and_one")) cand <- cand[!cand$id %in% c("gamlss_BEZI", "gamlss_BEOI"), , drop = FALSE]
  }

  if (type == "count" && include_sensitivity) {
    base_ids <- c("poisson", "nbinom1", "nbinom2", "compois", "genpois",
                  "vgam_genpoisson1", "vgam_genpoisson2")
    if (max(tier) >= 2L) {
      base_ids <- c(base_ids, "gamlss_NBI", "gamlss_NBII", "gamlss_PIG", "gamlss_GPO",
                    "gamlss_DPO", "gamlss_SICHEL", "gamlss_BNB", "vgam_negbinomial")
    }
    if (is.finite(response$zero_excess_ratio) && response$zero_excess_ratio > 1.25) {
      base_ids <- c(base_ids, "zip", "zinb1", "zinb2", "hurdle_poisson", "hurdle_nbinom2", "vgam_zapoisson")
      if (max(tier) >= 2L) base_ids <- c(base_ids, "zicomp", "zigenpois", "vgam_zipoisson", "vgam_zinegbinomial", "vgam_zanegbinomial")
    }
    cand <- reg[reg$id %in% base_ids & reg$tier <= max(tier), , drop = FALSE]
  }

  if (!is.null(design) && .design_has_random(design)) {
    cand <- cand[cand$random_effects, , drop = FALSE]
  }
  unique(cand$id)
}

#' Define an expert backend family without adding it to automatic screening
#'
#' This is the controlled escape hatch for GAMLSS or VGAM families that are
#' available in the installed backend but have not yet completed the dedicated
#' agriGLMflow validation battery. Expert families are never inserted into
#' automatic family screening.
#' @export
agri_family_spec <- function(engine = c("gamlss", "VGAM"), family,
                             response_type = "expert",
                             random_effects = FALSE,
                             multivariate = FALSE,
                             multiparameter = TRUE,
                             smooth = TRUE,
                             posthoc_mode = "unsupported",
                             notes = "Expert backend family; automatic recommendation disabled.") {
  engine <- match.arg(engine)
  family <- as.character(family)[1L]
  if (!nzchar(family)) .agri_abort("'family' must name an exported backend family constructor.")
  out <- list(
    id = paste0("expert_", tolower(engine), "_", family),
    label = paste(engine, family),
    response_type = response_type,
    domain = "expert",
    engine = engine,
    engine_family = family,
    random_effects = isTRUE(random_effects),
    multivariate = isTRUE(multivariate),
    multiparameter = isTRUE(multiparameter),
    smooth = isTRUE(smooth),
    zero_inflation = FALSE,
    hurdle = FALSE,
    truncation = FALSE,
    censoring = FALSE,
    simulation = NA,
    posthoc_mode = posthoc_mode,
    tier = 3L,
    notes = notes
  )
  class(out) <- "agri_family_spec"
  out
}

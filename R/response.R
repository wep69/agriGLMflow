#' Characterize an agricultural response variable
#' @export
agri_response <- function(data, response, process = NULL, denominator = NULL,
                          lower = NULL, upper = NULL) {
  stopifnot(is.data.frame(data))
  env <- parent.frame()
  response <- .capture_names(substitute(response), env)
  denominator <- .capture_names(substitute(denominator), env)
  if (!length(response)) .agri_abort("Provide at least one response column.")
  .assert_columns(data, c(response, denominator), "response characterization")

  # Multivariate response branch used by VGAM composition/count models.
  if (length(response) > 1L) {
    if (length(denominator)) .agri_abort("A shared 'denominator' is not used for multivariate response characterization.")
    M <- data[response]
    if (!all(vapply(M, is.numeric, logical(1)))) .agri_abort("Multivariate agri_response currently requires numeric response columns.")
    mat <- as.matrix(M)
    okrow <- stats::complete.cases(mat)
    obs <- mat[okrow, , drop = FALSE]
    if (!nrow(obs)) .agri_abort("Multivariate response contains no complete observed rows.")
    if (any(!is.finite(obs))) .agri_abort("Multivariate response contains non-finite observed values.")
    rs <- rowSums(obs)
    is_counts <- all(obs >= 0) && all(abs(obs - round(obs)) < sqrt(.Machine$double.eps)) && all(rs > 0)
    is_composition <- all(obs >= 0) && all(abs(rs - 1) < 1e-7)
    type <- if (!is.null(process)) as.character(process)[1L] else if (is_composition) {
      if (any(obs == 0)) "composition_boundary" else "composition"
    } else if (is_counts) "categorical_counts" else "multivariate_numeric"
    zero_fraction <- mean(obs == 0)
    out <- list(
      name = response, denominator = NULL, type = type, process = process,
      multivariate = TRUE, n = nrow(obs), n_missing = nrow(mat) - nrow(obs),
      mean = colMeans(obs), variance = apply(obs, 2L, stats::var),
      variance_mean_ratio = NA_real_, sd = apply(obs, 2L, stats::sd),
      min = apply(obs, 2L, min), max = apply(obs, 2L, max),
      zero_fraction = zero_fraction, one_fraction = mean(obs == 1),
      boundary_pattern = if (is_composition && any(obs == 0)) "component_zero" else NA_character_,
      poisson_zero_expected = NA_real_, zero_excess_ratio = NA_real_,
      skewness = NA_real_, excess_kurtosis = NA_real_, n_unique = NA_integer_,
      levels = NULL, ordered = FALSE,
      row_sums = summary(rs),
      bounds = c(lower = lower %||% NA_real_, upper = upper %||% NA_real_),
      audit = .audit_add(NULL, "response", type,
                         "Multivariate response support characterized before family screening.")
    )
    class(out) <- "agri_response"
    return(out)
  }

  response <- response[1L]
  y <- data[[response]]
  y0 <- y[!is.na(y)]
  if (!length(y0)) .agri_abort("Response contains no observed values.")

  is_ord <- is.ordered(y)
  is_fac <- is.factor(y)
  type <- "unknown"

  if (is_ord) {
    type <- "ordinal"
  } else if (is_fac) {
    if (nlevels(y) == 2L) type <- "binary" else type <- "categorical_nominal"
  } else if (is.logical(y)) {
    type <- "binary"
  } else if (is.numeric(y)) {
    vals <- sort(unique(y0))
    if (all(vals %in% c(0, 1)) && length(vals) <= 2L) {
      type <- "binary"
    } else if (!is.null(denominator) && length(denominator)) {
      type <- "binomial_count"
    } else if (.is_count_vector(y0)) {
      type <- "count"
    } else if (all(y0 >= 0 & y0 <= 1)) {
      if (any(y0 == 0 | y0 == 1)) type <- "proportion_closed" else type <- "proportion_open"
    } else if (all(y0 > 0)) {
      type <- "continuous_positive"
    } else {
      type <- "continuous"
    }
  }

  if (!is.null(process)) type <- as.character(process)[1L]
  mu <- if (is.numeric(y0)) mean(y0) else NA_real_
  vv <- if (is.numeric(y0) && length(y0) > 1L) stats::var(y0) else NA_real_
  zero_fraction <- if (is.numeric(y0)) mean(y0 == 0) else NA_real_
  one_fraction <- if (is.numeric(y0)) mean(y0 == 1) else NA_real_
  poisson_zero_expected <- if (identical(type, "count") && is.finite(mu)) exp(-mu) else NA_real_

  out <- list(
    name = response,
    denominator = denominator,
    type = type,
    process = process,
    multivariate = FALSE,
    n = length(y0),
    n_missing = sum(is.na(y)),
    mean = mu,
    variance = vv,
    variance_mean_ratio = if (is.finite(mu) && mu > 0 && is.finite(vv)) vv / mu else NA_real_,
    sd = if (is.numeric(y0) && length(y0) > 1L) stats::sd(y0) else NA_real_,
    min = if (is.numeric(y0)) min(y0) else NA_real_,
    max = if (is.numeric(y0)) max(y0) else NA_real_,
    zero_fraction = zero_fraction,
    one_fraction = one_fraction,
    boundary_pattern = if (identical(type, "proportion_closed")) {
      if (any(y0 == 0) && any(y0 == 1)) "zero_and_one" else if (any(y0 == 0)) "zero_only" else if (any(y0 == 1)) "one_only" else "none"
    } else NA_character_,
    poisson_zero_expected = poisson_zero_expected,
    zero_excess_ratio = if (is.finite(poisson_zero_expected) && poisson_zero_expected > 0) zero_fraction / poisson_zero_expected else NA_real_,
    skewness = if (is.numeric(y0)) .skewness_basic(y0) else NA_real_,
    excess_kurtosis = if (is.numeric(y0)) .kurtosis_basic(y0) else NA_real_,
    n_unique = length(unique(y0)),
    levels = if (is.factor(y)) levels(y) else NULL,
    ordered = is_ord,
    bounds = c(lower = lower %||% NA_real_, upper = upper %||% NA_real_),
    audit = .audit_add(NULL, "response", type,
                       "Response support characterized before family screening.")
  )
  class(out) <- "agri_response"
  out
}

#' Inspect response metadata
#' @export
agri_response_info <- function(response) {
  if (!inherits(response, "agri_response")) .agri_abort("'response' must be an agri_response object.")
  unclass(response)
}

#' Map a response to admissible distribution domains
#' @export
agri_distribution_map <- function(response) {
  if (!inherits(response, "agri_response")) .agri_abort("'response' must be an agri_response object.")
  switch(response$type,
    count = c("count", "zero_inflated_count", "hurdle_count", "truncated_count"),
    binary = c("binary", "binomial"),
    binomial_count = c("binomial", "overdispersed_binomial"),
    proportion_open = c("continuous_proportion"),
    proportion_closed = c("closed_proportion", "continuous_proportion"),
    continuous_positive = c("positive_continuous", "continuous"),
    continuous = c("continuous"),
    ordinal = c("ordinal"),
    categorical_nominal = c("nominal_multinomial"),
    composition = c("composition"),
    composition_boundary = c("composition_boundary"),
    categorical_counts = c("composition_counts"),
    censored_continuous = c("censored"),
    censored_count = c("censored"),
    extreme = c("extreme_value"),
    c(response$type)
  )
}

#' Define an agricultural experimental design
#'
#' Creates a design-aware object used throughout agriGLMflow. Character column
#' names or unquoted single column names are accepted for scalar design fields.
#' @export
agri_design <- function(data,
                        design = c("crd", "rcbd", "latin_square", "factorial",
                                   "split_plot", "split_split", "strip_plot",
                                   "repeated", "multi_environment", "generic"),
                        treatment = NULL,
                        block = NULL,
                        row = NULL,
                        column = NULL,
                        whole_plot_factor = NULL,
                        subplot_factor = NULL,
                        subsubplot_factor = NULL,
                        whole_plot_id = NULL,
                        subplot_id = NULL,
                        strip_A = NULL,
                        strip_B = NULL,
                        strip_A_id = NULL,
                        strip_B_id = NULL,
                        subject = NULL,
                        time = NULL,
                        environment = NULL,
                        genotype = NULL,
                        replication = NULL,
                        block_effect = c("random", "fixed"),
                        genotype_effect = c("fixed", "random"),
                        environment_effect = c("fixed", "random"),
                        interaction_effect = c("fixed", "random"),
                        covariance = c("independence", "ar1", "cs", "toeplitz", "unstructured"),
                        random = NULL,
                        fixed = NULL,
                        ...) {
  stopifnot(is.data.frame(data))
  design <- match.arg(design)
  block_effect <- match.arg(block_effect)
  genotype_effect <- match.arg(genotype_effect)
  environment_effect <- match.arg(environment_effect)
  interaction_effect <- match.arg(interaction_effect)
  covariance <- match.arg(covariance)

  env <- parent.frame()
  treatment <- .capture_names(substitute(treatment), env)
  block <- .capture_names(substitute(block), env)
  row <- .capture_names(substitute(row), env)
  column <- .capture_names(substitute(column), env)
  whole_plot_factor <- .capture_names(substitute(whole_plot_factor), env)
  subplot_factor <- .capture_names(substitute(subplot_factor), env)
  subsubplot_factor <- .capture_names(substitute(subsubplot_factor), env)
  whole_plot_id <- .capture_names(substitute(whole_plot_id), env)
  subplot_id <- .capture_names(substitute(subplot_id), env)
  strip_A <- .capture_names(substitute(strip_A), env)
  strip_B <- .capture_names(substitute(strip_B), env)
  strip_A_id <- .capture_names(substitute(strip_A_id), env)
  strip_B_id <- .capture_names(substitute(strip_B_id), env)
  subject <- .capture_names(substitute(subject), env)
  time <- .capture_names(substitute(time), env)
  environment <- .capture_names(substitute(environment), env)
  genotype <- .capture_names(substitute(genotype), env)
  replication <- .capture_names(substitute(replication), env)

  dots <- list(...)
  fixed_terms <- character()
  random_terms <- character()
  blocking <- character()
  experimental_units <- character()
  treatment_terms <- treatment %||% character()

  if (design == "crd") {
    if (!length(treatment_terms)) .agri_abort("CRD requires 'treatment'.")
    fixed_terms <- .interaction_term(treatment_terms)
  }

  if (design == "rcbd") {
    if (!length(treatment_terms) || !length(block)) .agri_abort("RCBD requires 'treatment' and 'block'.")
    fixed_terms <- .interaction_term(treatment_terms)
    blocking <- block
    if (block_effect == "random") random_terms <- .random_term(.bt(block))
    else fixed_terms <- .join_terms(c(fixed_terms, .bt(block)))
  }

  if (design == "latin_square") {
    if (!length(treatment_terms) || !length(row) || !length(column)) {
      .agri_abort("Latin square requires 'treatment', 'row', and 'column'.")
    }
    blocking <- c(row, column)
    fixed_terms <- .interaction_term(treatment_terms)
    if (block_effect == "random") {
      random_terms <- c(.random_term(.bt(row)), .random_term(.bt(column)))
    } else {
      fixed_terms <- .join_terms(c(fixed_terms, .bt(row), .bt(column)))
    }
  }

  if (design == "factorial") {
    if (length(treatment_terms) < 2L) {
      .agri_abort("Factorial design requires at least two treatment-factor columns in 'treatment'.")
    }
    fixed_terms <- .interaction_term(treatment_terms)
    if (length(block)) {
      blocking <- block
      if (block_effect == "random") random_terms <- .random_term(.bt(block))
      else fixed_terms <- .join_terms(c(fixed_terms, .bt(block)))
    }
  }

  if (design == "split_plot") {
    req <- c(block, whole_plot_factor, subplot_factor, whole_plot_id)
    if (any(lengths(list(block, whole_plot_factor, subplot_factor, whole_plot_id)) == 0L)) {
      .agri_abort("Split-plot requires 'block', 'whole_plot_factor', 'subplot_factor', and 'whole_plot_id'.")
    }
    treatment_terms <- c(whole_plot_factor, subplot_factor)
    fixed_terms <- .interaction_term(treatment_terms)
    blocking <- block
    experimental_units <- c(whole_plot_id)
    if (block_effect == "fixed") fixed_terms <- .join_terms(c(fixed_terms, .bt(block)))
    random_terms <- c(
      if (block_effect == "random") .random_term(.bt(block)) else character(),
      .random_term(sprintf("%s:%s", .bt(block), .bt(whole_plot_id)))
    )
  }

  if (design == "split_split") {
    if (any(lengths(list(block, whole_plot_factor, subplot_factor, subsubplot_factor,
                         whole_plot_id, subplot_id)) == 0L)) {
      .agri_abort(paste0(
        "Split-split plot requires 'block', 'whole_plot_factor', 'subplot_factor', ",
        "'subsubplot_factor', 'whole_plot_id', and 'subplot_id'."
      ))
    }
    treatment_terms <- c(whole_plot_factor, subplot_factor, subsubplot_factor)
    fixed_terms <- .interaction_term(treatment_terms)
    blocking <- block
    experimental_units <- c(whole_plot_id, subplot_id)
    if (block_effect == "fixed") fixed_terms <- .join_terms(c(fixed_terms, .bt(block)))
    random_terms <- c(
      if (block_effect == "random") .random_term(.bt(block)) else character(),
      .random_term(sprintf("%s:%s", .bt(block), .bt(whole_plot_id))),
      .random_term(sprintf("%s:%s:%s", .bt(block), .bt(whole_plot_id), .bt(subplot_id)))
    )
  }

  if (design == "strip_plot") {
    if (any(lengths(list(block, strip_A, strip_B, strip_A_id, strip_B_id)) == 0L)) {
      .agri_abort("Strip-plot requires 'block', 'strip_A', 'strip_B', 'strip_A_id', and 'strip_B_id'.")
    }
    treatment_terms <- c(strip_A, strip_B)
    fixed_terms <- .interaction_term(treatment_terms)
    blocking <- block
    experimental_units <- c(strip_A_id, strip_B_id)
    if (block_effect == "fixed") fixed_terms <- .join_terms(c(fixed_terms, .bt(block)))
    random_terms <- c(
      if (block_effect == "random") .random_term(.bt(block)) else character(),
      .random_term(sprintf("%s:%s", .bt(block), .bt(strip_A_id))),
      .random_term(sprintf("%s:%s", .bt(block), .bt(strip_B_id)))
    )
  }

  if (design == "repeated") {
    if (!length(subject) || !length(time)) {
      .agri_abort("Repeated-measures design requires 'subject' and 'time'.")
    }
    if (!length(treatment_terms)) .agri_abort("Repeated-measures design requires 'treatment'.")
    fixed_terms <- .interaction_term(c(treatment_terms, time))
    experimental_units <- subject
    if (covariance %in% c("ar1", "cs", "toeplitz", "unstructured")) {
      cov_fun <- switch(covariance, ar1 = "ar1", cs = "cs", toeplitz = "toep", unstructured = "us")
      random_terms <- sprintf("%s(%s + 0 | %s)", cov_fun, .bt(time), .bt(subject))
    } else {
      random_terms <- .random_term(.bt(subject))
    }
    if (length(block)) {
      blocking <- block
      if (block_effect == "random") random_terms <- c(.random_term(.bt(block)), random_terms)
      else fixed_terms <- .join_terms(c(fixed_terms, .bt(block)))
    }
  }

  if (design == "multi_environment") {
    if (!length(environment)) {
      .agri_abort("Multi-environment design requires an explicit 'environment' column. The design cannot be simplified without it.")
    }
    if (!length(genotype)) genotype <- treatment_terms
    if (!length(genotype)) .agri_abort("Multi-environment design requires 'genotype' or 'treatment'.")
    if (!length(replication) && !length(block)) {
      .agri_abort("Multi-environment design requires 'replication' or 'block' within environment.")
    }
    block_me <- replication %||% block
    treatment_terms <- genotype
    blocking <- c(environment, block_me)
    experimental_units <- c(block_me)

    ff <- character()
    rr <- character()
    if (genotype_effect == "fixed") ff <- c(ff, .bt(genotype)) else rr <- c(rr, .random_term(.bt(genotype)))
    if (environment_effect == "fixed") ff <- c(ff, .bt(environment)) else rr <- c(rr, .random_term(.bt(environment)))
    ge <- sprintf("%s:%s", .bt(genotype), .bt(environment))
    if (interaction_effect == "fixed") ff <- c(ff, ge) else rr <- c(rr, .random_term(ge))
    rr <- c(rr, .random_term(sprintf("%s:%s", .bt(environment), .bt(block_me))))
    fixed_terms <- .join_terms(ff)
    random_terms <- rr
  }

  if (design == "generic") {
    if (!length(fixed)) .agri_abort("Generic design requires 'fixed' as a character vector of model terms.")
    fixed_terms <- paste(fixed, collapse = " + ")
    random_terms <- random %||% character()
    treatment_terms <- treatment_terms %||% character()
  }

  cols <- unique(c(treatment_terms, block, row, column, whole_plot_factor,
                   subplot_factor, subsubplot_factor, whole_plot_id, subplot_id,
                   strip_A, strip_B, strip_A_id, strip_B_id, subject, time,
                   environment, genotype, replication))
  cols <- cols[!is.na(cols) & nzchar(cols)]
  .assert_columns(data, cols, "experimental design")

  out <- list(
    data = data,
    design = design,
    treatment = treatment_terms,
    blocking = blocking,
    experimental_units = experimental_units,
    fixed_terms = fixed_terms,
    random_terms = random_terms,
    columns = cols,
    roles = list(
      block = block, row = row, column = column,
      whole_plot_factor = whole_plot_factor, subplot_factor = subplot_factor,
      subsubplot_factor = subsubplot_factor, whole_plot_id = whole_plot_id,
      subplot_id = subplot_id, strip_A = strip_A, strip_B = strip_B,
      strip_A_id = strip_A_id, strip_B_id = strip_B_id, subject = subject,
      time = time, environment = environment, genotype = genotype,
      replication = replication
    ),
    options = list(
      block_effect = block_effect,
      genotype_effect = genotype_effect,
      environment_effect = environment_effect,
      interaction_effect = interaction_effect,
      covariance = covariance,
      dots = dots
    ),
    audit = .audit_add(NULL, "design", design,
                       "Experimental design declared before model construction.")
  )
  class(out) <- "agri_design"
  agri_validate_design(out)
  out
}

#' Validate an agriGLMflow design
#' @export
agri_validate_design <- function(design, strict = TRUE) {
  if (!inherits(design, "agri_design")) .agri_abort("'design' must be an agri_design object.")
  data <- design$data
  .assert_columns(data, design$columns, "design")

  problems <- character()
  for (nm in design$columns) {
    if (all(is.na(data[[nm]]))) problems <- c(problems, sprintf("Column '%s' is entirely missing.", nm))
  }

  if (design$design == "multi_environment") {
    env <- design$roles$environment
    if (is.null(env) || !length(env) || !env %in% names(data)) {
      problems <- c(problems, "Multi-environment design has no valid environment variable.")
    } else if (length(unique(stats::na.omit(data[[env]]))) < 2L) {
      problems <- c(problems, "Multi-environment analysis requires at least two environments.")
    }
  }

  if (design$design %in% c("split_plot", "split_split", "strip_plot") && !length(design$random_terms)) {
    problems <- c(problems, "Hierarchical plot design lacks required experimental-unit random terms.")
  }

  # Experimental-unit identifiers must represent one and only one parent treatment
  # combination. This catches accidental reuse of plot IDs across incompatible strata.
  check_unique_mapping <- function(id, strata, target, label) {
    cols <- c(id, strata, target)
    if (!length(id) || !all(cols %in% names(data))) return(character())
    grp <- interaction(data[c(strata, id)], drop = TRUE, lex.order = TRUE)
    val <- interaction(data[target], drop = TRUE, lex.order = TRUE)
    nmap <- tapply(as.character(val), grp, function(z) length(unique(z[!is.na(z)])))
    if (any(nmap > 1L, na.rm = TRUE)) sprintf("%s is reused for incompatible treatment assignments within its experimental stratum.", label) else character()
  }
  if (design$design %in% c("split_plot", "split_split")) {
    problems <- c(problems, check_unique_mapping(design$roles$whole_plot_id,
      design$roles$block, design$roles$whole_plot_factor, "whole_plot_id"))
  }
  if (design$design == "split_split") {
    problems <- c(problems, check_unique_mapping(design$roles$subplot_id,
      c(design$roles$block, design$roles$whole_plot_id), design$roles$subplot_factor, "subplot_id"))
  }
  if (design$design == "strip_plot") {
    problems <- c(problems,
      check_unique_mapping(design$roles$strip_A_id, design$roles$block, design$roles$strip_A, "strip_A_id"),
      check_unique_mapping(design$roles$strip_B_id, design$roles$block, design$roles$strip_B, "strip_B_id"))
  }

  if (design$design == "repeated") {
    subj <- design$roles$subject
    tim <- design$roles$time
    if (any(table(data[[subj]]) < 2L)) {
      problems <- c(problems, "At least one repeated-measures subject has fewer than two observations.")
    }
    if (design$options$covariance %in% c("ar1", "cs", "toeplitz", "unstructured") && !is.factor(data[[tim]])) {
      problems <- c(problems, paste0("Structured repeated-measures covariance ('", design$options$covariance,
                                      "') requires the time variable to be encoded as a factor with explicit ordered levels."))
    }
  }

  if (length(problems) && strict) .agri_abort(paste(problems, collapse = " "))
  structure(list(valid = !length(problems), problems = problems), class = "agri_design_validation")
}

#' Build a design-preserving formula
#' @export
agri_design_formula <- function(design, response) {
  if (!inherits(design, "agri_design")) .agri_abort("'design' must be an agri_design object.")
  if (length(response) != 1L) .agri_abort("'response' must be a single response expression or column name.")
  .as_formula(response, design$fixed_terms, design$random_terms)
}

#' Inspect design metadata
#' @export
agri_design_info <- function(design) {
  if (!inherits(design, "agri_design")) .agri_abort("'design' must be an agri_design object.")
  list(
    design = design$design,
    treatment = design$treatment,
    blocking = design$blocking,
    experimental_units = design$experimental_units,
    fixed_terms = design$fixed_terms,
    random_terms = design$random_terms,
    roles = design$roles,
    options = design$options,
    validation = agri_validate_design(design, strict = FALSE)
  )
}

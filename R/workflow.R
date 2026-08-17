#' Run the unified agricultural modelling workflow
#' @export
agri_workflow <- function(data, response, denominator = NULL, treatment = NULL,
                          design = c("crd", "rcbd", "factorial", "split_plot",
                                     "split_split", "strip_plot", "repeated", "multi_environment"),
                          family = "auto", tier = 1L, deep_scan = FALSE,
                          fit_scan = TRUE, select = TRUE, design_args = list(),
                          model_args = list(), posthoc = TRUE, make_figures = FALSE,
                          report_file = NULL, report_format = "markdown", ...) {
  design <- match.arg(design)
  response <- as.character(response)
  if (is.null(design_args$treatment) && !is.null(treatment)) design_args$treatment <- treatment
  des <- do.call(agri_design, c(list(data = data, design = design), design_args))
  resp <- if (is.null(denominator)) agri_response(data, response = response) else agri_response(data, response = response, denominator = denominator)
  lhs <- if (length(resp$name) > 1L) sprintf("cbind(%s)", paste(.bt(resp$name), collapse = ", ")) else resp$name
  wf_formula <- agri_design_formula(des, lhs)

  if (identical(family, "auto")) {
    scan <- agri_family_scan(data, resp, des, tier = tier, fit = fit_scan,
                             deep = deep_scan, formula = wf_formula)
    if (fit_scan && length(scan$models)) {
      comp <- agri_compare_models(models = scan$models, strategy = "admissibility", diagnostics = deep_scan)
      selected <- comp$selected
      if (is.null(selected) && length(scan$recommended)) selected <- scan$models[[scan$recommended[1L]]]
    } else {
      comp <- NULL
      fam <- scan$recommended[1L]
      selected <- if (isTRUE(select) && length(fam)) do.call(agri_model, c(list(data = data, response = resp, design = des, formula = wf_formula, family = fam), model_args)) else NULL
    }
  } else {
    scan <- agri_family_scan(data, resp, des, candidates = family, tier = max(tier, 3L), fit = FALSE,
                             formula = wf_formula)
    comp <- NULL
    selected <- if (isTRUE(select)) do.call(agri_model, c(list(data = data, response = resp, design = des, formula = wf_formula, family = family), model_args)) else NULL
  }

  dg <- if (!is.null(selected)) try(agri_diagnose(selected, simulate = deep_scan), silent = TRUE) else NULL
  av <- mn <- ct <- tr <- pr <- figs <- NULL
  posthoc_note <- NULL
  if (!is.null(selected)) {
    av0 <- try(agri_anova(selected), silent = TRUE)
    if (!inherits(av0, "try-error")) av <- av0
    pr0 <- try(agri_predict(selected, type = "response"), silent = TRUE)
    if (!inherits(pr0, "try-error")) pr <- pr0

    trt <- des$treatment
    if (isTRUE(posthoc) && length(trt) == 1L && trt %in% names(data)) {
      if (is.numeric(data[[trt]])) {
        tr0 <- try(agri_trends(selected, variable = trt), silent = TRUE)
        if (!inherits(tr0, "try-error")) tr <- tr0
        posthoc_note <- "The single treatment is quantitative; trend inference was preferred over automatic factor-level multiple comparisons."
      } else {
        mn0 <- try(agri_means(selected, specs = trt), silent = TRUE)
        if (!inherits(mn0, "try-error")) mn <- mn0
        ct0 <- try(agri_contrasts(selected, specs = trt), silent = TRUE)
        if (!inherits(ct0, "try-error")) ct <- ct0
      }
    } else if (isTRUE(posthoc) && length(trt) > 1L) {
      posthoc_note <- "Automatic main-effect decomposition was intentionally skipped because the design contains multiple treatment factors; request scientifically appropriate simple effects/conditional contrasts explicitly."
    }

    if (isTRUE(make_figures) && requireNamespace("ggplot2", quietly = TRUE)) {
      figs <- list()
      f1 <- try(agri_plot_distribution(selected), silent = TRUE)
      if (!inherits(f1, "try-error")) figs$distribution <- f1
      f2 <- try(agri_plot_diagnostics(selected), silent = TRUE)
      if (!inherits(f2, "try-error")) figs$diagnostics <- f2
      if (!is.null(mn)) {
        f3 <- try(agri_plot_means(mn), silent = TRUE)
        if (!inherits(f3, "try-error")) figs$means <- f3
      }
      if (!is.null(ct)) {
        f4 <- try(agri_plot_contrasts(ct), silent = TRUE)
        if (!inherits(f4, "try-error")) figs$contrasts <- f4
      }
    }
  }

  out <- list(
    data = data, design = des, response = resp, family_scan = scan,
    models = scan$models %||% list(), comparison = comp, selected_model = selected,
    diagnostics = if (inherits(dg, "try-error")) NULL else dg,
    anova = av, means = mn, contrasts = ct, trends = tr,
    predictions = pr, figures = figs, report = NULL,
    posthoc_note = posthoc_note, audit = NULL
  )
  class(out) <- "agri_workflow"
  out$audit <- agri_audit(out)
  if (!is.null(report_file) && !is.null(selected)) {
    out$report <- agri_report(out, file = report_file, format = report_format)
  }
  out
}

#' Load an agriGLMflow example dataset by name
#' @export
agri_example_data <- function(name = c("agri_insects", "agri_disease", "agri_germination",
                                       "agri_cover", "agri_biomass", "agri_ordinal",
                                       "agri_dose", "agri_splitplot", "agri_split_split",
                                       "agri_stripplot", "agri_repeated", "agri_multienv",
                                       "agri_distreg", "agri_multiclass", "agri_multicounts", "agri_composition",
                                       "agri_ordstage", "agri_censored")) {
  name <- match.arg(name)
  env <- new.env(parent = parent.frame())
  utils::data(list = name, package = "agriGLMflow", envir = env)
  env[[name]]
}

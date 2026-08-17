# Orchestrator for the frozen A-K simulation scenarios.
# Experiment L is a parameterization-harmonization protocol and is not dispatched
# as an ordinary Monte Carlo generator.

agri_run_battery <- function(experiments = NULL, reps = NULL,
                             scenario_file = system.file("simulation", "scenario_grid.csv", package = "agriGLMflow"),
                             seed_file = system.file("simulation", "seeds.csv", package = "agriGLMflow"),
                             output_dir = NULL) {
  simdir <- dirname(scenario_file)
  source(file.path(simdir, "helpers.R"), local = environment())
  scripts <- sprintf("%02d_%s.R", 1:11, c(
    "count_family", "proportion_family", "positive_family",
    "gamlss_location_scale", "design_misspecification", "regression_recovery",
    "multiple_comparisons", "diagnostic_sensitivity", "ordinal_vgam",
    "multinomial_vgam", "compositional_vgam"
  ))
  for (s in scripts) source(file.path(simdir, s), local = environment())

  scenarios <- utils::read.csv(scenario_file, stringsAsFactors = FALSE)
  seeds <- utils::read.csv(seed_file, stringsAsFactors = FALSE)
  if (!is.null(experiments)) scenarios <- scenarios[scenarios$experiment %in% experiments, , drop = FALSE]
  if (!nrow(scenarios)) stop("No scenarios selected.")

  runners <- list(
    A_count = run_count_scenario,
    B_proportion = run_proportion_scenario,
    C_positive = run_positive_scenario,
    D_gamlss = run_location_scale_scenario,
    E_design = run_design_scenario,
    F_regression = run_regression_scenario,
    G_multiplicity = run_multiplicity_scenario,
    H_diagnostics = run_diagnostic_scenario,
    I_ordinal = run_ordinal_scenario,
    J_multinomial = run_multinomial_scenario,
    K_composition = run_composition_scenario
  )

  if (is.null(output_dir)) output_dir <- file.path(tempdir(), "agriGLMflow-simulation")
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  manifest <- vector("list", nrow(scenarios))

  for (i in seq_len(nrow(scenarios))) {
    sc <- scenarios[i, , drop = FALSE]
    runner <- runners[[sc$experiment]]
    if (is.null(runner)) stop("No runner for experiment: ", sc$experiment)
    seed <- seeds$seed[((i - 1L) %% nrow(seeds)) + 1L]
    args <- list(scenario = sc, seed = seed)
    if (!is.null(reps)) args$reps <- as.integer(reps)
    result <- do.call(runner, args)
    outfile <- file.path(output_dir, paste0(sc$scenario_id, ".rds"))
    saveRDS(result, outfile)
    manifest[[i]] <- data.frame(
      scenario_id = sc$scenario_id,
      experiment = sc$experiment,
      seed = seed,
      file = outfile,
      stringsAsFactors = FALSE
    )
  }

  manifest <- do.call(rbind, manifest)
  utils::write.csv(manifest, file.path(output_dir, "manifest.csv"), row.names = FALSE)
  invisible(manifest)
}

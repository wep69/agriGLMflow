# Frozen validation battery

This directory implements the pre-specified simulation program for the future
software-validation manuscript.

Experiments A-L cover count-family screening, proportional responses, positive
continuous distributions, GAMLSS location-scale regression, design
misspecification, dose-response recovery, multiplicity, diagnostics, VGAM ordinal,
multinomial and compositional models, and cross-backend parameterization checks.

`scenario_grid.csv` and `seeds.csv` are frozen text registries. On a machine with R
and a writable development checkout, `00_freeze_scenarios.R` materializes the
corresponding RDS files. Text registries remain canonical so scenarios can be
inspected without executing R.

Recommended Monte Carlo repetitions are 1,000 for ordinary estimation scenarios,
2,000 or more for Type-I error and FWER experiments, and at least 500 for
computationally intensive GAMLSS/VGAM scenarios. Final counts should additionally
be justified using Monte Carlo standard errors.

## Battery orchestrator

`13_run_battery.R` dispatches the frozen A-K scenario rows to their corresponding
simulation runners and writes one `.rds` result per scenario plus a manifest.
Experiment L remains a parameterization-harmonization protocol because backend
coefficients must first be mapped to common estimands before numerical agreement
is assessed.

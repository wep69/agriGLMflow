# agriGLMflow 0.1.0

* Initial CRAN submission.
* Design-aware workflows for GLM, GLMM, GAMLSS, VGAM, ordinal, and regression models.
* 10 experimental design types (CRD, RCBD, factorial, split-plot, etc.).
* 80+ registered distribution families across 9 statistical engines.
* Automatic family screening with convergence and diagnostic gates.
* Full post-hoc inference (means, contrasts, trends, CLD).
* Quantitative-dose regression with agronomic targets.
* Design-aware cross-validation and cluster bootstrap.
* Comprehensive diagnostics (DHARMa, influence, dependence).
* 18 bundled datasets for agricultural experiments.
* 23 bilingual vignettes (PT/EN).

## Fixes

* `agri_workflow(family = "auto")` aborted before producing any result.
  Root cause: `agri_compare_models()` built its design signature with
  `paste(design, formula, sep = "::")`. Because `paste()` coerces a formula
  through `as.character()`, which yields one element per term (`"~"`, LHS,
  RHS), the surrounding `vapply(..., character(1))` failed with
  "values must be length 1, but FUN(X[[1]]) result is length 3". The formula
  is now collapsed with `deparse()` before pasting. Verified by
  `test-auto-workflow.R`, which covers the automatic path that
  `test-workflow-contract.R` did not exercise because it always passes an
  explicit family.

* `agri_cld()` aborted with "subscript out of bounds". Root cause: the
  predictor name was derived with `as.character(specs)`, which for
  `~ treatment` returns `c("~", "treatment")`, and that length-2 vector was
  used to index a data frame. The name is now extracted with `all.vars()`.

* `agri_cld()` returned `NA` for every letter. Root cause: emmeans labels
  pairs as `"A - B"`; `multcompView::multcompLetters()` splits on `-` and
  keeps the surrounding spaces, so the resulting names (`"BioA "`, `" BioB"`)
  never matched the factor levels. Only the `" - "` separator is now
  collapsed, which preserves levels that legitimately contain spaces, and the
  comparison trims whitespace on both sides.

* The Dunnett branch of `agri_contrasts()` read `"~"` instead of the
  predictor name when resolving the control level, because it used the same
  `as.character(specs)[1L]` pattern. It now uses `all.vars()`.

* `agri_compare_models()` now warns when the compared models were fitted
  under different experimental designs. Information criteria are not
  comparable across designs because the experimental-unit structure changes
  the likelihood. The design signature was previously computed and then
  discarded, so this guard never ran.

* Data objects in `data/` called `stats` random-number generators
  (`rnorm`, `rgamma`, `rbinom`, `rlnorm`, `rlogis`, `rpois`, `rbeta`,
  `rnbinom`, `runif`, `rmultinom`) and `plogis()` without the `stats::`
  qualifier, which broke `devtools::load_all()` and generated a check NOTE.
  All calls are now namespace-qualified.

* `tools/static_check.py` read source files with the platform default
  encoding and failed on UTF-8 vignettes. Reads are now explicitly UTF-8.

## Documentation

* Added `\value` sections to all exported-function help pages, documenting
  the returned object structure with field names verified against live
  `str()` output. `agri_diagnose()` reports its top-level status in the
  `overall` component; the tutorials previously referred to a non-existent
  `status` field.

* Added `\value` documentation for the engine limitation of `agri_anova()`,
  which raises an informative error for engines that cannot produce a
  deviance table (for example `glmmTMB`).

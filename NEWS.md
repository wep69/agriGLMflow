# agriGLMflow 0.1.0

## Vignette code is now runnable

`R CMD check` (R >= 4.6.1) added the step "checking running R code from
vignettes", which extracts the R code from every vignette and runs it in a
clean process, ignoring `eval = FALSE`. Only 3 of the 23 vignettes passed:
none of them attached the package, so `agri_design()` and `data(agri_insects)`
were both unavailable.

* Every vignette now attaches the package in its setup chunk, which makes the
  displayed code copy-pasteable and makes that check step pass.
* Six vignettes had code that could not run at all because it referenced
  objects that were never created or datasets that were never loaded:
  `v08-ordinal` (a covariate that does not exist in `agri_ordstage`),
  `v10-multiple-comparisons` (`des`), `v11-diagnostics` and
  `v15-simulation-power` (`fit`), `v14-graphics` and `v17-reproducible`
  (`agri_insects`). The missing definitions and data loads were added in an
  earlier chunk of each file.
* `v15-simulation-power` displayed `agri_bootstrap(R = 500)` and
  `agri_power(nsim = 1000)`, which alone took 236 s in that check step. The
  counts are now 25, with an explicit note that they are a speed resource and
  that a real analysis needs a much larger bootstrap and at least 1000 power
  replicates per scenario. The step dropped from about 390 s to about 160 s.

Verified by reproducing the check step with `tools:::.run_one_vignette()`, the
same function `R CMD check` uses: 23 OK / 0 FAIL.

## Fixes from the API audit report

The items below come from an audit of the public API against its own
documentation. Items 1-3 and 10 share one root cause: `as.character()` applied
to a two-sided formula returns one element per deparsed term (`"~"`, LHS, RHS),
never the column name. Every fix is pinned by a test in
`tests/testthat/test-report-items.R`.

* **The integrated workflow failed with factory arguments.**
  `agri_workflow(family = "auto", fit_scan = TRUE)` - both defaults - aborted in
  `agri_compare_models()`, which built a design signature with
  `paste(design, formula, sep = "::")`. The formula is now collapsed with
  `deparse()` before pasting, and the design signature, previously computed and
  discarded, now raises a warning when the compared models come from different
  designs, because information criteria are not comparable across
  experimental-unit structures.

* **`agri_cld()` never filled the `.cld` column.** Two chained causes: the
  predictor name came from `as.character(specs)`, which yields `c("~",
  "treatment")`; and `multcompView::multcompLetters()` splits emmeans pair
  labels (`"A - B"`) on `-` while keeping the surrounding spaces, so the
  resulting names (`"BioA "`, `" BioB"`) never matched the factor levels. The
  name now comes from `all.vars()`, only the separator is collapsed (level
  names that legitimately contain spaces survive), and an all-`NA` letter
  column now raises a warning instead of passing as a valid table.

* **Dunnett contrasts could not resolve a control level by name, and chose one
  silently when omitted.** Same root cause. The error now lists the available
  levels, and omitting `control` warns that the first level was adopted.

* **`seed` re-seeded the caller's session.** `agri_bootstrap()`, `agri_cv()`,
  `agri_diagnose()`, `agri_power()` and `agri_simulate()` called `set.seed()`
  without restoring `.Random.seed`. A simulation loop passing a fixed seed
  silently collapsed every replicate onto one realisation. All five now draw
  under a private seed through the internal `.with_seed()` helper.

* **Quadratic targets were wrong for mixed engines and single-valued under
  `by`.** `stats::coef()` on a glmmTMB fit returns a list, and `unlist()`ing it
  yields the random-effect entries (`block.(Intercept)1`, `block.dose1`, ...),
  so a positional read returned a meaningless optimum; the same positional read
  ignored the interaction terms created by `by`. Terms are now located by name,
  coefficients are read through `.reg_coef()`/`.reg_vcov()`, and `by` returns
  one target set per group with a `group` column.

* **`agri_bootstrap(statistic = "coef")` returned an all-`NA` matrix on a mixed
  fit** while `successful` reported every replicate as fine. It now reads fixed
  effects through the same uniform extractor and aborts with a pointer to
  `statistic = "prediction"` if the matrix still cannot be assembled.

* **Convergence was declared for fits that stopped at the iteration ceiling.**
  The gate read only exit codes, while `VGAM` reports the stop through `@iter`
  and several engines report it through a warning. Fits now run inside a
  warning collector, the VGAM iteration counter is compared with its ceiling,
  and `object$warnings` is populated.

* **`delta` was accepted and discarded** on the `emmeans` branch of
  `agri_trends()`, which serves stats, glmmTMB, gamlss and ordinal. It is now
  passed as `delta.var`.

* **`bootstrap` was accepted and discarded** outside the VGAM and GLMMadaptive
  paths of `agri_means()` and `agri_contrasts()`. Both now warn that the engine
  returns analytic intervals and point to `agri_bootstrap()`.

* **`weights` was passed in place of `method`** in `agri_contrasts()`, so every
  legitimate weighting specification failed with
  `Contrast function 'equal.emmc' not found`.

* **`agri_workflow(make_figures = TRUE)` returned two figures instead of four.**
  `agri_plot_means()` and `agri_plot_contrasts()` required an `agri_model` while
  the workflow held `agri_posthoc` objects. Both plot helpers now accept either
  form, and the workflow returns all four figures.

* **`agri_regression()` objects carried no convergence field**, so a non-linear
  fit that stopped at `maxiter` still produced plausible-looking targets. The
  object now has `convergence`, `warnings` and `note` fields, and a failed fit
  raises a warning.

* **`agri_workflow()` did not say where the blocking column goes.**
  `RCBD requires 'treatment' and 'block'.` now continues with
  `Pass the blocking column through design_args, for example
  design_args = list(block = "block").` The CRD and Latin-square messages were
  extended the same way.

* **`agri_engines()` and `agri_dependencies()` returned different columns.**
  Only the latter carried `feature`. Both now return the same registry with the
  same columns.

* **Arguments named `response` that required an object.**
  `agri_response_info()`, `agri_distribution_map()` and
  `agri_family_candidates()` now accept a bare response vector and promote it,
  in addition to the `agri_response` object.

* **`model_args = list(family = ...)` collided with the family the workflow
  already passes**, aborting with a base-R message about a formal argument
  matched by multiple values that never mentioned `model_args`. The user's
  value now wins, and reserved keys (`data`, `response`, `design`, `formula`)
  are refused with an explicit message.

* An absent target table is now explained through the `note` field rather than
  returned as `NULL` in silence, and the unregistered-family message lists
  where the accepted identifiers are.

* `gamlss` printed its deviance trace with `cat()` rather than through a
  message condition, so `message = FALSE` did not intercept it. The backend
  call is now wrapped so the argument behaves as documented.

## Features

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

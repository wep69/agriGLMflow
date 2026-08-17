# agriGLMflow validation status

## Status of this source snapshot

**Static source validation: PASS**

The project-level checker `tools/static_check.py` verifies, independently of an
R runtime:

- balanced delimiters in R-like source files;
- exported symbols have corresponding function definitions;
- documentation aliases exist for exported functions;
- dataset scripts and vignette files are discoverable;
- key package files are present;
- the dedicated state-of-the-art vignette is present;
- every DOI cited in `vignettes/references.bib` has a double-verification record;
- every citation key used by the state-of-the-art vignette resolves to the package bibliography.

At the time this snapshot was assembled it reported:

- 68 R-like files checked;
- 66 exported functions;
- 146 function definitions in `R/`;
- 83 Rd aliases;
- 18 dataset generators;
- 23 vignettes;
- PASS, with one intentional warning about the maintainer e-mail.

## What was not executable in the build environment

A real R runtime was not available in the execution container. An attempt to
install it through the operating-system package manager failed because the
container could not resolve the Debian package host. Therefore the following
checks **have not been claimed as completed** for this snapshot:

- parsing every R file with R itself;
- installing all optional statistical backends;
- `testthat` execution;
- vignette rendering;
- `R CMD build`;
- `R CMD check --as-cran`;
- compiled-backend numerical tests for `glmmTMB`, VGAM and other packages.

The `.tar.gz` and `.zip` supplied with this snapshot are therefore source
snapshots, not artifacts produced by `R CMD build`.

## Intentional CRAN blocker

`DESCRIPTION` contains the placeholder maintainer address:

`REPLACE_WITH_MAINTAINER_EMAIL@example.invalid`

Replace it with the real maintainer e-mail before any CRAN submission. No
contact address was invented during implementation.

## Required local validation sequence

Run on a clean Windows PC and, ideally, also through Linux/macOS CI.

```r
install.packages(c(
  "devtools", "testthat", "roxygen2", "pkgdown", "covr",
  "ggplot2", "glmmTMB", "lme4", "GLMMadaptive",
  "gamlss", "gamlss.dist", "gamlss.inf", "VGAM",
  "ordinal", "betareg", "brglm2", "emmeans", "DHARMa",
  "performance", "marginaleffects", "ggeffects", "mgcv",
  "MASS", "minpack.lm", "segmented", "drc", "agridat"
))

setwd("<parent-directory-containing-agriGLMflow>")
devtools::document("agriGLMflow")
devtools::test("agriGLMflow")
devtools::build_vignettes("agriGLMflow")
devtools::check("agriGLMflow", cran = TRUE)
```

Then run the base R commands from a terminal:

```text
R CMD build agriGLMflow
R CMD check --as-cran agriGLMflow_0.1.0.tar.gz
```

## High-priority runtime validation matrix

The first local run should prioritize:

1. CRD/RCBD formula equivalence against direct backend fits.
2. Split-plot, split-split and strip-plot random strata.
3. Repeated-measures covariance structures.
4. Mandatory `environment` enforcement and block-within-environment handling.
5. `glmmTMB` families, zero-inflation, hurdle and dispersion models.
6. GAMLSS `mu`, `sigma`, `nu`, `tau` formulas and Tier-2 family constructors.
7. VGAM multinomial, cumulative/PPO, adjacent-category, continuation/stopping,
   Dirichlet, Dirichlet-multinomial and simplex models.
8. Hard blocking of VGAM for random-effect designs.
9. GLMMadaptive single-grouping-factor restrictions.
10. `emmeans` Tukey/Dunnett/Holm and response-scale transformations.
11. Bootstrap-standardized VGAM/GLMMadaptive comparisons.
12. Quantitative-treatment regression and curve-derived quantities.
13. Group-aware cross-validation and cluster bootstrap.
14. All graphics and report formats.
15. Frozen simulation battery A-L.

## Release criterion

Do not label version 0.1.0 as CRAN-ready until the full runtime matrix passes and
all warnings from `R CMD check --as-cran` have been resolved or documented.

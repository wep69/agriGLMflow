# agriGLMflow <img src="man/figures/logo.png" align="right" height="139" alt="" />

<!-- badges: start -->
[![R-CMD-check](https://github.com/wep69/agriGLMflow/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/wep69/agriGLMflow/actions/workflows/R-CMD-check.yaml)
[![CRAN status](https://www.r-pkg.org/badges/version/agriGLMflow)](https://CRAN.R-project.org/package=agriGLMflow)
<!-- badges: end -->

`agriGLMflow` is a design-aware R framework for generalized, mixed,
distributional, vector, categorical and compositional modelling in agricultural
experiments.

The package is built around four rules:

1. the experimental design is defined before the statistical model;
2. the support and scientific meaning of the response restrict admissible families;
3. an engine is never selected if it cannot preserve the experimental-unit structure;
4. automated decisions are recorded and can be audited.

## Installation

### Stable version (from GitHub)

```r
# install.packages("remotes")
remotes::install_github("wep69/agriGLMflow")
```

This installs the package **without** building vignettes (fast).

### With vignettes

```r
remotes::install_github("wep69/agriGLMflow", build_vignettes = TRUE)
```

This rebuilds all 23 vignettes during installation. It takes longer but gives
you access to `vignette("v01-introduction", package = "agriGLMflow")`.

### Quick install with pak

```r
# install.packages("pak")
pak::pak("wep69/agriGLMflow")
```

### Dependencies

Most backends are in `Suggests` and installed automatically. If you need all
engines, install them explicitly:

```r
install.packages(c(
  "glmmTMB", "lme4", "GLMMadaptive", "gamlss", "gamlss.dist",
  "VGAM", "ordinal", "betareg", "brglm2", "emmeans", "DHARMa",
  "mgcv", "MASS", "minpack.lm", "segmented", "drc"
))
```

## Minimal workflow

```r
library(agriGLMflow)
data(agri_insects)

des <- agri_design(
  agri_insects,
  design = "rcbd",
  treatment = "treatment",
  block = "block"
)

scan <- agri_family_scan(
  data = agri_insects,
  response = "insects",
  design = des,
  fit = FALSE
)

fit <- agri_model(
  data = agri_insects,
  response = "insects",
  design = des,
  family = "nbinom2"
)

agri_diagnose(fit)
agri_means(fit, specs = "treatment")
agri_plot(fit, type = "diagnostics")
```

See the vignettes for complete workflows.

## Cheatsheets and tutorials

Detailed tutorials in Portuguese and English are available in `inst/cheatsheet/`:

- **PT**: `agriGLMflow-tutorial-PT.html` — fluxos completos com dados simulados
- **EN**: `agriGLMflow-tutorial-EN.html` — complete workflows with simulated data

Each tutorial covers:

1. RCBD with count data (family selection, diagnostics, post-hoc inference)
2. Quantitative dose-response regression (polynomial, plateau, comparison)
3. Cross-engine model comparison (betareg vs glmmTMB vs GAMLSS)
4. Diagnostic sensitivity and cross-validation

After installing the package, open them with:

```r
browseURL(system.file("cheatsheet/agriGLMflow-tutorial-EN.html",
                       package = "agriGLMflow"))
```


## Statistical engines

The package routes compatible models to `stats`, `glmmTMB`, `lme4`, `GLMMadaptive`, `gamlss`, `VGAM`, `ordinal`, `betareg`, and `brglm2`. `glmmTMB` is preferred for advanced mixed models. `VGAM` is restricted to fixed-effects workflows. `GLMMadaptive` is restricted to a single grouping factor. Engine changes never silently remove random experimental-unit terms or substitute a different probability family.

## Capability registry

The current source snapshot contains 81 registered family-capability entries across
base GLMs, `glmmTMB`, GAMLSS, `betareg`, `ordinal`, and VGAM. Registration does not
mean that every family participates in automatic selection. Tier 1 contains the
main validated workflow targets; Tier 2 exposes advanced candidates that require
explicit opt-in; Tier 3 is an expert escape hatch through `agri_family_spec()`.

```r
agri_families()
agri_family_candidates(resp, design = des, tier = 1)
agri_family_candidates(resp, design = des, tier = 2)
```

VGAM contributes fixed-effects multinomial, ordinal, compositional, vector and
specialized distributional models. Because the current VGAM implementation is
fixed-effects only, the engine router rejects VGAM whenever the declared
experimental design requires random experimental-unit effects.

## Validation status

This repository includes unit tests, golden-test scaffolding, frozen simulation
scenarios A-L, and a static integrity checker. See `VALIDATION.md` before treating
the source snapshot as a CRAN release candidate. A real maintainer e-mail must be
inserted in `DESCRIPTION` before submission.

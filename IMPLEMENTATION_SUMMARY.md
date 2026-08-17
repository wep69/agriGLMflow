# agriGLMflow implementation summary

## Scope implemented

`agriGLMflow` is implemented as a design-aware orchestration layer rather than a
new statistical estimator. The original backend object is retained in every
`agri_model`, while the package standardizes design metadata, response support,
family capability, diagnostics, inference, plots and audit trails.

## Public API

The snapshot exports 66 functions covering:

- experimental-design declaration and validation;
- response classification and distribution mapping;
- capability/family registry and family screening;
- engine discovery and routing;
- GLM, GLMM, GAMLSS, VGAM/VGLM, ordinal, compositional and censored models;
- quantitative regression and curve comparison;
- convergence, dispersion, zeros, residual, influence, random-effect and
  dependence diagnostics;
- ANOVA-style tests, estimated means, contrasts, simple effects, interaction
  contrasts, trends, marginal effects, predictions and CLDs;
- cross-validation, bootstrap, simulation and power;
- scientific plotting, reporting, audit and export;
- one-call `agri_workflow()` orchestration.

## Experimental designs

Implemented design contracts:

- completely randomized design;
- randomized complete block design;
- Latin square;
- factorial designs;
- split-plot;
- split-split plot;
- strip-plot;
- repeated measurements;
- multi-environment experiments;
- generic nested/crossed structures.

Design validation precedes engine routing. The package does not drop a required
experimental-unit random term merely to make a backend fit. Multi-environment
objects require an explicit `environment` variable.

## Statistical engines

Implemented routing/adapters:

- `stats`;
- `glmmTMB`;
- `lme4`;
- `GLMMadaptive`;
- `gamlss`/`gamlss.dist`;
- `VGAM`;
- `ordinal`;
- `betareg`;
- `brglm2`;
- optional `mgcv` for smooth quantitative relationships.

VGAM is treated as a specialized fixed-effects vector/distributional backend.
It is blocked when the declared design requires random effects. Additional
VGAM/GAMLSS constructors can be requested through an explicit Tier-3 expert
family specification but are not automatically recommended.

## Family capability registry

The current registry has 81 capability entries. It records, per family:

- response support;
- backend and constructor;
- random-effect support;
- multivariate/multiparameter capability;
- smooth-term support;
- zero-inflation/hurdle/truncation/censoring capability;
- simulation support;
- post-hoc interpretation mode;
- validation tier.

The registry contains conventional GLMs, `glmmTMB` count/proportion/continuous
families, an expanded GAMLSS branch, beta/ordinal models and a VGAM branch with
multinomial, multiple ordinal formulations, Dirichlet, Dirichlet-multinomial,
simplex, specialized count, censored and extreme-value models.

## Family selection

`agri_family_scan()` follows an admissibility workflow:

1. mathematical support;
2. scientific response/process classification;
3. candidate-family registry;
4. preservation of one experimental design across candidates;
5. engine availability and compatibility;
6. convergence gate;
7. residual/dispersion/zero diagnostics;
8. likelihood/predictive comparison only among admissible models;
9. recommended set rather than forced winner when evidence is close.

AIC/BIC do not override structural incompatibility or failed diagnostics.

## Quantitative regression

Implemented paths include linear, quadratic, cubic, plateau, Mitscherlich,
Michaelis-Menten, logistic, Gompertz, Weibull, GAM and VGAM smoothers. Numeric
treatments remain numeric by default. Polynomial terms can coexist with GLMM
random structures. Unsupported nonlinear mixed approximations are rejected
rather than silently converted to fixed-effects fits.

## Multiple comparisons and effects

For supported model classes, `emmeans` is used for EMMs, Tukey,
treatment-versus-control/Dunnett, Holm and related adjustments, trends and
conditional comparisons. For VGAM and GLMMadaptive paths not natively supported
by `emmeans`, the package uses standardized predictions and optional bootstrap
inference instead of claiming unsupported native support.

## Diagnostics

Implemented checks include:

- convergence/Hessian/boundary signals where exposed;
- Pearson dispersion;
- observed and simulation-based zero checks;
- DHARMa when available and appropriate;
- random-effect singular/boundary checks;
- Cook's distance flags without automatic deletion;
- residual skewness/kurtosis;
- temporal lag-1 autocorrelation;
- cluster-level residual association as a misspecification signal;
- GAMLSS quantile residuals;
- VGAM native/simulation diagnostic hooks.

## Data, vignettes and simulation support

The source includes 18 deterministic dataset generators and 23 vignettes,
including English and Portuguese introductions plus dedicated GLMM, GAMLSS,
VGAM, regression, post-hoc, diagnostics, repeated-measures and multi-environment
workflows.

A frozen simulation design A-L contains 188 scenario definitions and 12,000
registered seeds. The planned article endpoints include bias, RMSE, confidence
interval coverage, type-I error, power, convergence, family-set recovery,
calibration, predictive log score, Brier score and multiclass log-loss.

## State-of-the-art and metadata verification

A dedicated English vignette, `v19-state-of-the-art.Rmd`, now documents the scoped
state of the art, compares agriculture-oriented packages with specialized GLM/GLMM,
GAMLSS, VGAM, response-specific, post-model and diagnostic packages, and states the
novelty claim conservatively as a gap in integrated design-aware orchestration rather
than as the absence of existing modelling algorithms.

The vignette uses `vignettes/references.bib`. Each scientific DOI in that bibliography
is linked to a machine-readable double-verification record in
`inst/metadata/reference_verification.csv`, with a human-readable audit in
`inst/METADATA_VERIFICATION.md`. Software-version comparisons are explicitly dated
2026-08-12 because CRAN metadata are time-dependent.

## Tests

The test suite contains structural and backend-contract tests for designs,
family screening, GAMLSS, VGAM, mixed backends, regression, curve comparison,
Dunnett contracts, multivariate responses, CV metrics, workflow contracts and
cluster diagnostics.

See `VALIDATION.md` for the distinction between static validation completed in
this environment and runtime R validation that remains mandatory before CRAN.

- The state-of-the-art comparison also covers complementary Bayesian/smooth/diagnostic frameworks (`brms`, `mgcv`, `DHARMa`, `hnp`) so the novelty claim is not based only on direct core backends.

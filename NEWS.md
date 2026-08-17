# agriGLMflow 0.1.0

* Initial development release implementing the design-first architecture.
* Added CRD, RCBD, Latin square, factorial, split-plot, split-split plot,
  strip-plot, repeated-measures and multi-environment design validation.
* Added model routing across base GLM, glmmTMB, GAMLSS, VGAM, ordinal,
  betareg and brglm2 backends.
* Added capability-aware family registry with validated, advanced and expert tiers.
* Added VGAM support for multinomial, ordinal, compositional, specialized count,
  censored and extreme-value models while enforcing its fixed-effects limitation.
* Added family screening, diagnostics, multiple comparisons, regression,
  prediction, plotting, resampling, power and reporting workflows.

- Added design-aware multiclass/compositional cross-validation metrics (log-loss, Brier score, accuracy, cross-entropy).
- Added explicit Dunnett treatment-versus-control handling, including bootstrap simultaneous inference for standardized VGAM/GLMMadaptive predictions.
- Added category-probability prediction handling for ordinal models.
- Added a dedicated state-of-the-art vignette comparing agriculture-oriented packages, GLMM engines, GAMLSS, VGAM, specialized response models, post-model inference and diagnostic layers.
- Added a double-verification bibliography workflow with machine-readable DOI/source audit records and a dated CRAN software snapshot.

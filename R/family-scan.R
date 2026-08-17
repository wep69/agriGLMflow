#' Screen scientifically admissible response families
#'
#' Candidate generation is based first on response support and design compatibility.
#' If fitting is requested, models are ranked only after convergence and compatibility
#' gates. Information criteria are not used to override structural incompatibility.
#' @export
agri_family_scan <- function(data, response, design = NULL, candidates = "auto",
                             tier = 1L, fit = TRUE, deep = FALSE,
                             formula = NULL, engine_args = list(), ...) {
  if (!inherits(response, "agri_response")) {
    response <- agri_response(data, response = response)
  }
  if (identical(candidates, "auto")) {
    candidates <- agri_family_candidates(response, design = design, tier = tier)
  }
  candidates <- unique(as.character(candidates))
  if (!length(candidates)) .agri_abort("No admissible registered families were found for this response/design combination.")

  audit <- .audit_add(NULL, "family screening", paste(candidates, collapse = ", "),
                      "Candidates restricted by response support and design compatibility.")
  results <- vector("list", length(candidates))
  models <- list()

  for (i in seq_along(candidates)) {
    fam <- candidates[i]
    info <- try(agri_family_info(fam), silent = TRUE)
    if (inherits(info, "try-error")) {
      results[[i]] <- data.frame(family = fam, engine = NA_character_, status = "unregistered",
                                 converged = FALSE, AIC = NA_real_, BIC = NA_real_, logLik = NA_real_, note = "Family not registered.")
      next
    }
    eng <- try(.route_engine(fam, design, formula = formula), silent = TRUE)
    if (inherits(eng, "try-error")) {
      results[[i]] <- data.frame(family = fam, engine = info$engine[1L], status = "incompatible",
                                 converged = FALSE, AIC = NA_real_, BIC = NA_real_, logLik = NA_real_, note = as.character(eng))
      next
    }
    if (!fit) {
      results[[i]] <- data.frame(family = fam, engine = eng, status = "candidate",
                                 converged = NA, AIC = NA_real_, BIC = NA_real_, logLik = NA_real_, note = info$notes[1L])
      next
    }
    pkg <- if (eng == "stats") "stats" else eng
    if (!requireNamespace(pkg, quietly = TRUE)) {
      results[[i]] <- data.frame(family = fam, engine = eng, status = "engine_unavailable",
                                 converged = FALSE, AIC = NA_real_, BIC = NA_real_, logLik = NA_real_,
                                 note = sprintf("Optional package '%s' is not installed.", pkg))
      next
    }
    m <- try(agri_model(data = data, response = response, design = design,
                        formula = formula, family = fam, engine = eng,
                        engine_args = engine_args, ...), silent = TRUE)
    if (inherits(m, "try-error")) {
      results[[i]] <- data.frame(family = fam, engine = eng, status = "fit_failed",
                                 converged = FALSE, AIC = NA_real_, BIC = NA_real_, logLik = NA_real_, note = as.character(m))
      next
    }
    dg <- try(agri_diagnose(m, simulate = isTRUE(deep)), silent = TRUE)
    ok <- isTRUE(m$convergence$ok)
    status <- if (ok) "admissible" else "convergence_warning"
    if (!inherits(dg, "try-error") && identical(dg$overall, "problem")) status <- "diagnostic_problem"
    results[[i]] <- data.frame(
      family = fam, engine = eng, status = status, converged = ok,
      AIC = .safe_AIC(m$engine_fit), BIC = .safe_BIC(m$engine_fit),
      logLik = .safe_logLik(m$engine_fit), note = info$notes[1L], stringsAsFactors = FALSE
    )
    models[[fam]] <- m
  }

  tab <- do.call(rbind, results)
  rownames(tab) <- NULL
  eligible <- tab$status == "admissible" & is.finite(tab$AIC)
  tab$delta_AIC <- NA_real_
  tab$role <- "rejected_or_unavailable"
  if (any(eligible)) {
    amin <- min(tab$AIC[eligible])
    tab$delta_AIC[eligible] <- tab$AIC[eligible] - amin
    tab$role[eligible & tab$delta_AIC <= 2] <- "recommended"
    tab$role[eligible & tab$delta_AIC > 2] <- "sensitivity"
  } else {
    admiss <- tab$status %in% c("admissible", "candidate")
    tab$role[admiss] <- "candidate"
  }

  recommended <- tab$family[tab$role == "recommended"]
  if (!length(recommended)) recommended <- tab$family[tab$role == "candidate"]
  out <- list(
    response = response, design = design, candidates = candidates,
    table = tab, models = models, recommended = recommended,
    audit = .audit_add(audit, "family recommendation", paste(recommended, collapse = ", "),
                       "Only structurally admissible and converged models can enter the recommended set.")
  )
  class(out) <- "agri_family_scan"
  out
}

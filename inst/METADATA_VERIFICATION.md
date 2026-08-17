# Reference and software metadata verification

**Verification date:** 2026-08-12  
**Purpose:** support the `State of the art, ecosystem comparison, and rationale for agriGLMflow` vignette and the future software manuscript.

## Policy

Scientific references used to establish the methodological rationale are accepted into the vignette only after the bibliographic metadata have been checked against two sources. Preference is given to the journal/publisher version of record plus an independent bibliographic index, institutional repository, Crossref record, or the software package's official citation record.

The machine-readable record is `inst/metadata/reference_verification.csv`. It contains the citation key, DOI, title, two verification sources, verification date, status, and notes. The bibliography rendered by the vignette is `vignettes/references.bib`.

This process verifies **metadata**, not the scientific validity of every claim in a cited work. Scientific claims are paraphrased conservatively and tied to the scope of the corresponding source.

## References checked twice

| Key | DOI | Source A | Source B | Status |
|---|---|---|---|---|
| MaddenOjiambo2024 | 10.3389/fhort.2024.1423462 | Frontiers in Horticulture | DOAJ | Verified |
| ShimizuEtAl2025 | 10.4025/actasciagron.v47i1.73889 | Acta Scientiarum. Agronomy | CRAN AgroR citation/package record | Verified |
| ArchontoulisMiguez2015 | 10.2134/agronj2012.0506 | Agronomy Journal/Wiley | Crossref DOI metadata | Verified |
| BatesEtAl2015 | 10.18637/jss.v067.i01 | Journal of Statistical Software | CRAN lme4 citation/package documentation | Verified |
| BrooksEtAl2017 | 10.32614/RJ-2017-066 | The R Journal | ETH Zurich Research Collection | Verified |
| RigbyStasinopoulos2005 | 10.1111/j.1467-9876.2005.00510.x | Oxford Academic/JRSS C | Wiley/Crossref DOI metadata | Verified |
| StasinopoulosEtAl2018 | 10.1177/1471082X18759144 | SAGE/Statistical Modelling | London Metropolitan University repository | Verified |
| MerderEtAl2026 | 10.1038/s43586-026-00498-z | Nature Reviews Methods Primers | Crossref Crossmark | Verified |
| Yee2010 | 10.18637/jss.v032.i10 | Journal of Statistical Software | CRAN VGAM citation / RePEc | Verified |
| Yee2015 | 10.1007/978-1-4939-2818-7 | Springer book record | CRAN VGAM citation | Verified |
| CribariNetoZeileis2010 | 10.18637/jss.v034.i02 | Journal of Statistical Software | RePEc/IDEAS | Verified |
| Lenth2016 | 10.18637/jss.v069.i01 | Journal of Statistical Software | CRAN lsmeans citation | Verified |
| ArelBundockEtAl2024 | 10.18637/jss.v111.i09 | Journal of Statistical Software | official marginaleffects citation | Verified |
| LudeckeEtAl2021 | 10.21105/joss.03139 | Journal of Open Source Software | CRAN performance citation | Verified |
| PujolRigolEtAl2025 | 10.1002/wics.70025 | Wiley/WIREs Computational Statistics | UPC repository / Zenodo replication record | Verified |
| Buerkner2017 | 10.18637/jss.v080.i01 | Journal of Statistical Software | CRAN brms citation | Verified |
| MoralEtAl2017 | 10.18637/jss.v081.i10 | Journal of Statistical Software | CRAN hnp citation | Verified |
| Wood2025 | 10.1146/annurev-statistics-112723-034249 | Annual Reviews | University of Edinburgh repository / CRAN mgcv documentation | Verified |

### Metadata discrepancy documented

For Archontoulis & Miguez, some older secondary copies display legacy 2013 volume/page metadata associated with the same DOI. The current publisher record and DOI metadata identify the version of record as **Agronomy Journal 107(2), 786-798 (2015)**. The package bibliography uses the current version-of-record metadata rather than reproducing the legacy record.


### Correction tracked for the ordinal-package systematic review

The 2025 WIREs systematic review by Pujol-Rigol, Fernández, and Casals has a published
2026 correction (DOI `10.1002/wics.70060`) concerning Table 4 entries for GLMcat and
`brms`. The package uses the review conservatively and does not propagate those corrected
entries into its capability claims. This is another reason the ecosystem matrix is dated.

## Software snapshot used for the ecosystem comparison

Software evolves more quickly than journal metadata. The comparison vignette therefore treats versions as a dated snapshot, not permanent bibliographic facts.

| Package | Snapshot metadata on 2026-08-12 | Verification approach |
|---|---|---|
| agricolae | 1.3-7; CRAN publication 2023-10-22 | CRAN package index + CRAN reference manual |
| ExpDes / ExpDes.pt | 1.2.2; CRAN publication 2021-10-05 | CRAN package index + CRAN reference manual |
| AgroR | 1.3.7; CRAN publication 2025-07-02 | CRAN package index + published AgroR article |
| AgroReg | 1.2.11; CRAN publication 2025-07-01 | CRAN package index + reference manual/package documentation |
| lme4 | 2.0-6; CRAN publication 2026-07-16 | CRAN package index + CRAN reference manual |
| glmmTMB | 1.1.14; CRAN publication 2026-01-15 | CRAN package index + CRAN reference manual/current checks |
| GLMMadaptive | 0.9-7; CRAN publication 2025-03-04 | CRAN package index + CRAN reference manual |
| gamlss | 5.5-0; CRAN publication 2025-08-19 | CRAN package index + reference manual |
| VGAM | 1.1-14; CRAN publication 2025-12-04 | CRAN package index + CRAN citation/reference documentation |
| betareg | 3.2-5; CRAN publication 2026-07-12 | CRAN package index + README/reference manual |
| emmeans | 2.0.4; CRAN publication 2026-07-15 | CRAN package index + reference manual/changelog |
| performance | 0.17.1; CRAN publication 2026-06-30 | CRAN package index + reference manual/citation |
| marginaleffects | 0.32.0; CRAN publication 2026-02-14 | CRAN package documentation + official citation/documentation site |
| ordinal | 2026.7-26; CRAN publication 2026-07-27 | CRAN package index + reference manual |
| brms | 2.23.0; CRAN publication 2025-09-09 | CRAN package index + official citation record |
| mgcv | 1.9-4; CRAN publication 2025-11-07 | CRAN package index + current methodological review |
| DHARMa | 0.5.0; CRAN publication 2026-06-01 | CRAN package index + current checks/documentation |
| hnp | 1.2-7; CRAN publication 2025-04-15 | CRAN package index + JSS software paper |

Critical routing constraints were also checked against current documentation. In particular, current VGAM documentation states that only fixed-effects models are implemented, whereas GLMMadaptive currently allows multiple random-effect terms but only one grouping factor. These are hard routing rules in `agriGLMflow`.

## Before manuscript submission

Repeat this verification immediately before submission because:

1. CRAN package versions may change;
2. software capabilities may be expanded or deprecated;
3. a newer peer-reviewed comparison may supersede a preprint or software note;
4. the state-of-the-art claim must remain explicitly bounded by the search date and package set.

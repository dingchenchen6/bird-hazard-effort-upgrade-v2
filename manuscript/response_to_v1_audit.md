# Response to the v1 audit (internal, dated 2026-05-11)

This document maps each audit point to a concrete v2 fix. It is **not**
a peer-review response (v1 was an internal report, not a submission).
Use it when handing v2 to a co-author or when responding to future
reviewers who may have seen v1.

## A. Methodological audits

| v1 audit ID | Pain | v2 resolution |
|-------------|------|---------------|
| P0-1 grid-MAUP | Grid 100-km map was province-resolution in disguise | `code/28_grid_native_climate.R` recomputes climate at native grid resolution from CHELSA v2.1 rasters; `code/31_maup_sensitivity.R` confirms < 10 % β-elasticity between adjacent scales |
| P0-2 z-scored offset | Broke offset coefficient ≡ 1 assumption | `code/32_offset_reformulation.R` switches to `offset = log(person_hours + 1)` and reports 4-way sensitivity |
| P0-3 grid event collapse | Multi-species same-(grid, year) collapsed by `species[1]` | `code/33_grid_event_definition_fix.R` redefines event as earliest record per (species, grid) and exports `events_*_grid_assigned_v2.parquet` |
| P0-4 covariate shift | Out-of-distribution risk not quantified | `code/30_forecast_skill_decay.R` quantifies AUC decay vs lead time + per-feature PSI |
| P1-5 random CV | Row-random folds leak spatial autocorrelation | `code/26_spatial_block_cv.R` uses `blockCV::cv_spatial(size = 250 km, k = 5)` |
| P1-6 no Moran I | Residual spatial structure unchecked | `code/27_morans_i_diagnostics.R` reports Moran's I across 50/100/250/500 km classes + DHARMa spatial test |
| P1-7 single-GCM CMIP6 | Point estimate only | `code/29_cmip6_ensemble_prediction.R` aggregates 5 GCMs × SSP245/SSP585 × 2050/2080 → median + IQR + disagreement |
| P1-8 engineering debt | Duplicated utils, no lockfile, no DAG | `code/utils/*.R` consolidated; `renv.lock` pins versions; `_targets.R` orchestrates |

## B. Numerical inconsistencies

| Item | v1 inconsistency | v2 canonical | Where enforced |
|------|------------------|--------------|----------------|
| Provinces | 32 vs 34 | 32 mainland | manuscript §1.1, README, `code/37_reproducibility_selfcheck.R` |
| Species | 200+ vs 333 | 333 | same |
| Records | unstated | 12,813 | same |
| CHELSA | unstated | v2.1, baseline 1981–2010 | METHODS.md |
| Software | unstated | R 4.4.1, glmmTMB 1.1.9, xgboost 2.0.3.1 | `renv.lock` |
| CRS | unstated | WGS84 (4326) raw → Albers (4524) grids | `code/utils/utils_spatial.R` |
| variance-decomp basis | "80.4 %" unclear | 80.4 % of conditional R² = 0.301 | manuscript §2.3, §3.5 |
| Joint overlap | -0.0001 | 0.000, footnote: floating-point near-zero | manuscript §2.3 |
| OLR ΔAIC 1857 | not discussed | Results §3.8 paragraph + Supp Table S2 | manuscript |
| Conservation implications | 3 bullets | new Discussion §4.4 (≥ 600 words) | manuscript |

## C. Residual risks (declared in manuscript §4.5)

R1 species-shared interaction slope; R2 effort endogeneity; R3
detection-ceiling artefact; R4 CHELSA reprojection bias; R5 CMIP6
ensemble selection bias; R6 sparse western-Xizang records; R7
phylogenetic non-independence. Each gets one paragraph and a citation
to the SI for full discussion.

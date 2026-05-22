# Gap resolution — v1 → v2

Cross-reference of v1 issues (audit dated 2026-05-11) to v2 fixes.
v1 files are read-only; the entries below cite the **v1** path so the
reader can confirm the original problem.

## P0 — must fix before submission

### P0-1  Grid model used province-level climate (MAUP)
- **v1 evidence**: `code/17_unified_multi_metric_modeling.R:203-204`
  joined `risk_grid_cc` to `climate_metrics_province_year.csv`,
  effectively painting every 100 km cell with its province's
  climate-velocity z-score.
- **Impact**: the 100 km "risk map" was a province map at finer
  resolution — multi-scale conclusion was unsupported.
- **v2 fix**: `code/28_grid_native_climate.R` recomputes
  `climate_velocity_z`, `temp_anom_z`, `precip_anom_z` directly from
  CHELSA v2.1 monthly rasters at native 50 / 100 km grid cells.
  Outputs: `data/derived/grid_{50,100}km_climate_native.parquet`.
- **Verification**: `code/31_maup_sensitivity.R` re-runs M1–M5 at
  prov / 50 / 100 / 200 km and reports coefficient elasticity (Fig S8).

### P0-1b  Grid model used province-level EFFORT (effort MAUP)
- **v1 evidence**: `code/06_build_grid_infrastructure.R:260-285` built
  `grid_{50,100}km_effort.csv` by merging the **province-year** effort
  panel onto every (grid_id, year) row of that province. Verified by
  inspection: Anhui-2002 has 9 grid cells, **all with identical**
  `log_effort_visits_z = -1.0019`, `effort_pc1_z = -0.6588`, etc.
- **Impact**: any "grid hazard model" claim about within-province
  effort variation was unfounded; the grid coefficient was a province
  coefficient in disguise.
- **v2 fix**: `code/28b_grid_native_effort.R` rebuilds (grid_id, year)
  effort from coordinate-level records — counts per cell of records,
  visits (observer × day pairs when available), unique observers,
  unique birding days; PCA → `effort_pc1`; grid-native z-scoring.
  Province totals are reconstructed as a QC check.
  Output: `data/derived/grid_{50,100}km_effort_native.parquet` +
  `results/diagnostics/figS_grid_effort_within_province_variance.{pdf,png}`.

### P0-2  Z-scored offset (broke offset≡1 assumption)
- **v1 evidence**:
  `code/01_build_effort_upgraded_risk_set.R:86-89` standardised every
  effort metric; `code/17_unified_multi_metric_modeling.R:270` then used
  the standardised vector inside `offset()`.
- **Impact**: the offset coefficient is fixed at 1 in cloglog — only
  meaningful if the offset is on the **log-rate** scale. Z-scoring
  shifts and rescales, so M5 was not what it claimed to be (ΔAIC=86.5
  vs M3 was almost certainly an artefact of the broken offset).
- **v2 fix**: `code/32_offset_reformulation.R` rebuilds M5 with
  `offset = log(person_hours + 1)` and reports a 4-way sensitivity
  (raw, log, sqrt, z-score, none) in
  `results/sensitivity/table_offset_reformulation.csv` and Fig S9.

### P0-3  Grid event definition collapsed multi-species ties + missed SDM filter
- **v1 evidence**: `code/07_hazard_model_grid.R:177-178` defined
  `grid_event_summary <- grid_events[, .(event=1L, species=species[1]),
   by=.(grid_id, year)]` — multi-species first arrivals in the same
  (grid, year) collapsed to one row; multi-coordinate ties within a
  grid kept only the first row. Additionally, the species × grid × year
  cartesian was built without restricting to the SDM-suitable
  (species, province) candidate set, so every species was exposed to
  every grid in China regardless of habitat suitability.
- **Impact**: event count under-counted (ties lost); risk denominator
  over-counted (species exposed to unsuitable cells); coefficient
  estimates biased on both sides.
- **v2 fix**: `code/33_grid_event_definition_fix.R` redefines event =
  earliest record per **(species, grid)** triple AND restricts the
  cartesian to (species, province) candidate pairs that pass the v1
  SDM province threshold filter (extracted from
  `data/raw/grid_*km_risk_set.csv`), then expands only to grids within
  candidate provinces. Outputs:
  `data/derived/events_{50,100}km_grid_assigned_v2.parquet` (first
  arrivals) and `events_{50,100}km_grid_risk_set_v2.parquet`
  (SDM-thresholded risk set). Counts before/after in Fig S10 +
  `results/diagnostics/table_grid_event_redefinition_summary.csv`.

### P0-4  XGBoost future predictions had no skill-decay guard
- **v1 evidence**: `code/10_xgboost_shap_prediction.R` and
  `code/16_multi_scale_future_prediction.R` trained on 2002–2024 and
  predicted onto SSP2050/2080 climates without quantifying covariate
  shift or out-of-distribution risk.
- **Impact**: 2050 risk maps presented as if reliability matched
  near-term predictions.
- **v2 fix**: `code/30_forecast_skill_decay.R` trains on 1980–2010,
  validates on rolling 2011–2024 windows, plots AUC vs lead time and
  computes per-feature PSI to flag covariate-shift hot-spots. Fig 6
  shows the skill curve; Fig S12 the PSI bars.

## P1 — high priority

### P1-5  Random 5-fold CV on spatially autocorrelated data
- **v1 evidence**: `code/22_ml_validation_complete.R:65`
  `folds <- sample(rep(1:k, length.out = nrow(.)))` is row-random.
- **v2 fix**: `code/26_spatial_block_cv.R` uses
  `blockCV::cv_spatial(x = sf_points, size = 250e3, k = 5,
   selection = "random", iteration = 50)`. Reports ROC-AUC, PR-AUC,
  Brier and calibration per fold (Fig 4, Tab S7).

### P1-6  No systematic Moran's I / DHARMa spatial
- **v2 fix**: `code/27_morans_i_diagnostics.R` extracts Pearson
  residuals from M4 at province and grid scales; computes Moran's I
  over 50 / 100 / 250 / 500 km classes via `ape::Moran.I`; runs
  `DHARMa::testSpatialAutocorrelation`; renders Fig 4 inset + Fig S2.

## P1 — medium priority

### P1-7  Single-model CMIP6 projection
- **v2 fix**: `code/29_cmip6_ensemble_prediction.R` aggregates 5 CMIP6
  GCMs × 2 SSPs × 2 horizons → grid-wise median + IQR + ensemble
  disagreement. Fig 5 main map; Fig S11 per-model maps.

### P1-9  No prefecture / county hazard models
- **v1 evidence**: `code/16_multi_scale_future_prediction.R` produced
  prefecture- (市) and county- (县) level **predictions** by re-using
  the province-level XGBoost. No (species, prefecture, year) or
  (species, county, year) hazard model was ever fitted.
- **Impact**: claims of "multi-scale insight" were predictions of a
  province model painted on finer polygons — heterogeneity of the
  climate × effort interaction at sub-province scale was untested.
- **v2 fix**: `code/38_prefecture_county_hazard.R` spatially joins
  events to prefecture/county polygons (GS(2019)1822 shapefile
  family), builds (species, unit, year) cartesians restricted to SDM
  candidate (species, province) pairs, derives within-province effort
  via per-unit record share, and fits M1–M5 at both scales. Outputs:
  `data/derived/events_{prefecture,county}_risk_set.parquet`,
  `results/sensitivity/table_prefecture_county_{aic,coefs}.csv`.

### P1-10  No unified multi-metric × multi-scale comparison
- **v1 evidence**: model comparisons were scattered across
  `code/02_hazard_model_effort_comparison.R`,
  `code/05_hazard_model_advanced_climate.R`,
  `code/07_hazard_model_grid.R`,
  `code/17_unified_multi_metric_modeling.R` — no single artefact let a
  reviewer see the climate × effort interaction across 6 climate
  metrics × 4 effort specifications × 5 spatial scales simultaneously.
- **v2 fix**: `code/39_unified_multi_metric_multi_scale.R` fits
  the 6 × 4 × 5 = 120 cell matrix in one go and writes
  `results/tables/table_unified_multi_metric_multi_scale.{csv,parquet}`,
  `figures/main/fig3b_unified_interaction_matrix.{pdf,png}` (HR heat-
  map across metrics × scales) and
  `figures/supplementary/figS_unified_forest_by_scale.{pdf,png}`.

### P1-8  Code duplication, no renv.lock, no pipeline
- **v2 fix**:
  - `code/utils/{utils_data,utils_models,utils_spatial,utils_plots}.R`
    centralise helpers (`extract_coefs_manual`, `aic_table`,
    `variance_decomp`, `make_spatial_blocks`, `theme_geb`, …).
  - `renv.lock` pins R 4.4.1, glmmTMB 1.1.9, xgboost 2.0.3, blockCV
    3.1, terra 1.7, sf 1.0, targets 1.7, fst 0.9, arrow 14, …
  - `_targets.R` orchestrates the DAG (~60 nodes);
    `00_run_all.R` calls `targets::tar_make()`.
  - Large CSVs (5.5 GB / 1.4 GB) re-emitted as parquet (~600 MB / 180 MB).

## Manuscript-level fixes

| Item | v1 wording | v2 fix |
|------|------------|--------|
| Province count | "32" vs "34" | unified to **32 mainland (excl. HK/Macau/Taiwan)** |
| Species count | "200+" vs "333" | unified to **333** |
| Records | unstated | **12,813** |
| variance-decomp basis | "80.4 %" unclear | **80.4 % of conditional R² = 0.301; marginal R² = 0.0417** |
| Joint overlap −0.0001 | not explained | reported as **0.000**, footnote: floating-point near-zero |
| CHELSA version | unstated | **v2.1, 1981–2010 baseline** |
| Software | unstated | **R 4.4.1, glmmTMB 1.1.9, xgboost 2.0.3** |
| CRS | unstated | **WGS84 (EPSG:4326) raw → Albers Equal-Area (EPSG:4524) grids** |
| OLR ΔAIC = 1857 | not discussed | new Results 3.8 paragraph: detection-ceiling test; interaction β stable |
| Conservation implications | 3 bullets | new Discussion 4.4 (≥600 words) on Yunnan–Guizhou–Sichuan–Xizang priority |
| Residual P0 risks | not flagged | new Limitations bullets 4–6 |

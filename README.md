# Bird Hazard × Effort Upgrade — v2 + v3 (GEB submission ready)

**Scientific question / 科学问题**
Across continental China, do climate-velocity exposure and survey effort
interactively rather than additively drive the hazard of new bird
distribution records, and is this interaction robust across spatial
scales (province → prefecture → county) and across alternative
risk-set definitions?

**目标 / Target journal:** *Global Ecology and Biogeography*

This directory is a **non-destructive re-build** of
`../bird_hazard_model_effort_upgrade/` (v1). v1 is referenced read-only
via symlinks in `data/raw/` and `data/spatial/`. All derived products,
new analyses, refreshed figures and the rewritten manuscript land here.

> **TWO PARALLEL TRACKS** (v2 + v3, files separated by suffix):
>
> | Track | Risk-set | Species | Events | Rows | Headline M4 HR (Spec B) |
> |---|---|---:|---:|---:|---|
> | **v2** | SDM threshold = 100 (tight, v1 published) | 333 | 512 | 12,813 | **1.288** (1.179, 1.407, p = 2.1×10⁻⁸) |
> | **v3** | SDM threshold = 50 + event-override + 501 modelled species | 463 | 817 | 188,870 | **1.274** (1.198, 1.354, **p = 1.1×10⁻¹⁴**) |
>
> v2 = manuscript headline. v3 = sensitivity check (Results §3.10).
> See [INDEX_v2_v3.md](INDEX_v2_v3.md) for the full file-level pairing.
> See [manuscript/audit_report_v3.docx](manuscript/audit_report_v3.docx)
> for a comprehensive 12-section review.

## Layout

```
bird_hazard_model_effort_upgrade_v2/
├── README.md, METHODS.md, GAP_RESOLUTION.md, RESEARCH_GAPS_AND_RISKS.md
├── _targets.R, renv.lock, .Rprofile, sessionInfo.txt
├── code/                       # 01-25 ported (+ utils/), 26-37 new
├── data/{raw,derived,spatial}/ # raw = symlink to v1, derived = parquet
├── data_dictionary/            # YAML schemas + variables_master.csv
├── results/{tables,diagnostics,sensitivity,forecasts}/
├── figures/{main,supplementary,diagnostics}/  # 600 dpi PDF + PNG
├── manuscript/                 # manuscript_v2.Rmd, SI, cover letter
└── logs/, targets/             # run logs and targets cache
```

## End-to-end run

```bash
cd tasks/bird_hazard_model_effort_upgrade_v2
Rscript -e 'renv::restore()'
Rscript code/00_run_all.R               # targets::tar_make()
Rscript code/37_reproducibility_selfcheck.R
Rscript -e 'rmarkdown::render("manuscript/manuscript_v2.Rmd")'
```

Estimated runtime: ~4–6 h on 16-core / 64 GB RAM, ~30 min on a warm
`targets/` cache. Hardware floor: 32 GB RAM, 8 cores, 30 GB free disk.

## What changed vs v1

| ID | Severity | v1 issue | v2 fix |
|----|----------|----------|--------|
| P0-1 | 🔴 critical | 100 km grid model used **province-level climate** (MAUP) | `code/28_grid_native_climate.R` recomputes grid-native climate from CHELSA v2.1 rasters |
| P0-1b| 🔴 critical | Grid **effort** z-scores were also province-mirrors (verified: Anhui-2002, 9 cells, identical z-scores) | `code/28b_grid_native_effort.R` builds (grid_id × year) effort from coordinate-level records with grid-native z-scoring |
| P0-2 | 🔴 critical | M5 offset used z-scored effort (breaks offset≡1 assumption) | `code/32_offset_reformulation.R` rebuilds with `offset = log(person_hours+1)` + 4-way sensitivity |
| P0-3 | 🔴 critical | Grid event = first row in same (grid,year); cartesian ignored SDM threshold | `code/33_grid_event_definition_fix.R` redefines event = earliest record per (species,grid) AND restricts the cartesian to province-level SDM candidates |
| P0-4 | 🔴 critical | XGBoost future predictions had no covariate-shift / skill-decay quantification | `code/30_forecast_skill_decay.R` adds horizon skill curves + per-feature PSI |
| P1-5 | 🟠 high | Only random 5-fold CV (`code/22:65`) on spatially autocorrelated data | `code/26_spatial_block_cv.R` uses `blockCV::cv_spatial` (250 km, k=5) |
| P1-6 | 🟠 high | No systematic Moran's I residual diagnostics | `code/27_morans_i_diagnostics.R` reports Moran's I + DHARMa spatial test |
| P1-7 | 🟡 medium | Single-model CMIP6 projection — point estimate only | `code/29_cmip6_ensemble_prediction.R` aggregates 5 GCMs × SSP245/585 × 2050/2080 with median + IQR + disagreement |
| P1-9 | 🟠 high | No **prefecture / county** hazard models (v1 only predicted at those scales) | `code/38_prefecture_county_hazard.R` builds (species, unit, year) risk sets at 市 / 县 scales and fits M1–M5 |
| P1-10| 🟠 high | No unified **multi-climate × multi-effort × multi-scale** comparison | `code/39_unified_multi_metric_multi_scale.R` fits 6 climate × 4 effort × 5 scale = 120 model matrix and outputs Table 2 / Fig 3b |
| P1-8 | 🟡 medium | utils duplicated, no renv.lock, no targets DAG | `code/utils/*.R` consolidates helpers; `renv.lock`; `_targets.R` |

See [GAP_RESOLUTION.md](GAP_RESOLUTION.md) for the full mapping of v1
issues → v2 fixes with file:line references.

## Canonical numbers (manuscript_v2)

| Quantity | Value | Source |
|----------|-------|--------|
| Records | 12,813 | `results/tables/table_dataset_summary.csv` |
| Provinces | 32 (mainland; excludes HK/Macau/Taiwan) | `data/raw/effort_panel_upgraded.csv` |
| Species | 333 | `data/raw/hazard_risk_upgraded_complete_case.csv` |
| Period | 2002–2024 | M0–M5 risk set |
| CHELSA | v2.1, 1981–2010 baseline | `code/28_grid_native_climate.R` |
| CRS | WGS84 (EPSG:4326) raw → Albers Equal-Area (EPSG:4524) for grids/areas | `code/utils/utils_spatial.R` |
| Software | R 4.4.1, glmmTMB 1.1.9, xgboost 2.0.3, blockCV 3.1, terra 1.7, sf 1.0 | `renv.lock` |

## License & ethics

- Code: MIT (see `LICENSE`).
- Manuscript & figures: CC-BY 4.0 on acceptance.
- Data: observational only (no animal handling); see Supp Methods for
  source-level licenses (CHELSA, CMIP6 ESGF, Bird records, basemap
  GS(2019)1822).

## Citation

Ding, C.-C. *et al.* (in prep). *Climate-velocity exposure and survey
effort interactively drive new bird distribution records across China:
a multi-scale hazard framework.* Manuscript draft in
[manuscript/manuscript_v2.Rmd](manuscript/manuscript_v2.Rmd).

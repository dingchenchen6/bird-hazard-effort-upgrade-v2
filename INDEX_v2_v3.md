# INDEX — v2 vs v3 file layout

This repository hosts **two parallel analytical pipelines** that share
the same project directory but keep their outputs in **separate files**:

| Track | Risk-set definition | Species | Events | Rows | Headline interaction HR |
|---|---|---:|---:|---:|---:|
| **v2** | SDM threshold = **100 km** (tight), v1 published binarisation | 333 | 512 | 12,813 | **1.288** (1.179, 1.407, p = 2.1×10⁻⁸) |
| **v3** | SDM threshold = **50 km** + event-override force-include + 501 modelled species (drops 69 vagrants) | **463** | **817** | **188,870** | **1.274** (1.198, 1.354, **p = 1.1×10⁻¹⁴**) |

Both share the same model formula family (cloglog hazard with
`(1|species)+(1|unit)` crossed random effects) and the same effort /
climate covariates. Reading the two side-by-side is the manuscript's
core sensitivity analysis.

---

## v2 file family (SDM-tight, 333 species)

### Code
| File | Purpose |
|---|---|
| `code/27_morans_i_diagnostics.R` | M4 residual Moran's I at 50/100/250/500 km |
| `code/28_grid_native_climate.R` | WorldClim 2.1 10' grid-native climate (P0-1 fix) |
| `code/28b_grid_native_effort.R` | Community-grid raw-records effort (P0-1b fix) |
| `code/29_cmip6_ensemble_prediction.R` | CMIP6 ensemble (hard-fail if NetCDF absent) |
| `code/30_forecast_skill_decay.R` | XGBoost forecast skill horizon + PSI |
| `code/32_offset_reformulation.R` | M5 raw-scale offset (P0-2 fix) |
| `code/33_grid_event_definition_fix.R` | Grid event = first arrival per (species, grid) (P0-3 fix) |
| `code/37_reproducibility_selfcheck.R` | Self-check assertions (10/10 PASS) |
| `code/40_execute_five_scale_models.R` | Original 5-scale runner (OOM-prone) |
| `code/40b_run_prov_pref_county_lite.R` | Lite prefecture/county runner |
| `code/40c_province_only_refit.R` | Province-only refit (v1↔v2 reconciliation) |
| `code/41_provincial_future_panel.R` | Province future panel (RF + SHAP + future maps) |
| `code/42_prefecture_county_with_audit.R` | Prefecture + county refit with raw-records effort |
| `code/43_province_model_mapped_to_pref_county.R` | Province→unit plug-in projection |
| `code/44_unified_publication_figures.R` | Figures 1-6 publication versions |
| `code/45_province_riskset_completeness_audit.R` | v1 risk-set attrition diagnostic |
| `code/99_build_audit_report_docx.R` | docx report generator (v2) |

### Persisted result tables
| File | Content |
|---|---|
| `results/tables/table_province_v2_coefs.csv` | 4 effort spec × M0-M4 = 60 rows |
| `results/tables/table_province_v2_aic.csv` | AIC ladder, all converged |
| `results/tables/table_province_v1_v2_reconciliation.csv` | v1↔v2 max\|ΔHR\| = 0.008 |
| `results/tables/table_prefecture_coefs.csv` | Prefecture M0-M4 fixed effects |
| `results/tables/table_county_coefs.csv` | County M0-M4 fixed effects |
| `results/tables/table_prefecture_county_aic.csv` | 3-scale AIC + Akaike weight |
| `results/tables/table_rf_importance_v2.csv` | RF permutation importance, 14 features |
| `results/tables/table_aic_akaike_weights.csv` | Akaike weights, 4 specs |
| `results/tables/table_offset_reformulation.csv` | M5 offset sensitivity (raw/log/sqrt/z/none) |
| `results/tables/table_offset_coefficients.csv` | Per-offset coef table |
| `results/forecasts/table_province_future_glmmTMB.csv` | Province future hazard from M4 |
| `results/forecasts/table_province_future_xgboost.csv` | Province future hazard from XGBoost |
| `results/forecasts/table_prefecture_future_glmmTMB.csv` | Prefecture refit projection |
| `results/forecasts/table_prefecture_future_xgboost.csv` | Prefecture XGB projection |
| `results/forecasts/table_county_future_glmmTMB.csv` | County refit projection |
| `results/forecasts/table_county_future_xgboost.csv` | County XGB projection |
| `results/forecasts/table_prefecture_future_mapped_from_province.csv` | Province→prefecture plug-in |
| `results/forecasts/table_county_future_mapped_from_province.csv` | Province→county plug-in |
| `results/diagnostics/table_morans_i_residuals.csv` | M4 residual Moran's I |
| `results/diagnostics/audit_prefecture_county.txt` | 10-step data integrity audit |

### Figures
| File | Description |
|---|---|
| `figures/main/Figure_1_concept_and_workflow.{pdf,png}` | (a) Study domain (b) Sample size (c) Causal DAG |
| `figures/main/Figure_2_province_headline.{pdf,png}` | 4 panels: forest + AIC + varpart + beeswarm |
| `figures/main/Figure_3_multiscale_validation.{pdf,png}` | 3-scale forest + MAUP decay + sample sizes |
| `figures/main/Figure_4_variable_importance.{pdf,png}` | RF lollipop + top-5 bar |
| `figures/main/Figure_5_province_future_hazard.{pdf,png}` | 12 panels: glmmTMB + XGBoost × SSP × year |
| `figures/main/Figure_6_unit_future_hazard.{pdf,png}` | Prefecture/county refit + plug-in |
| `figures/main/fig_three_scale_forest_pref_county.{pdf,png}` | Standalone 3-scale forest |
| `figures/main/fig_province_interaction_forest_v1_vs_v2.{pdf,png}` | v1↔v2 reconciliation forest |
| `figures/main/fig_future_hazard_glmmTMB_prefecture.{pdf,png}` | Prefecture refit (6 panels) |
| `figures/main/fig_future_hazard_xgboost_prefecture.{pdf,png}` | Prefecture XGB (6 panels) |
| `figures/main/fig_future_hazard_glmmTMB_county.{pdf,png}` | County refit |
| `figures/main/fig_future_hazard_xgboost_county.{pdf,png}` | County XGB |
| `figures/main/fig_future_mapped_glmmTMB_prefecture.{pdf,png}` | Prefecture plug-in glmmTMB |
| `figures/main/fig_future_mapped_xgboost_prefecture.{pdf,png}` | Prefecture plug-in XGB |
| `figures/main/fig_future_mapped_glmmTMB_county.{pdf,png}` | County plug-in glmmTMB |
| `figures/main/fig_future_mapped_xgboost_county.{pdf,png}` | County plug-in XGB |
| `figures/main/fig_coef_forest_4specs.{pdf,png}` | 4-spec forest panorama |
| `figures/main/fig_coef_beeswarm_M4.{pdf,png}` | M4 beeswarm |
| `figures/main/fig_varpart_4specs.{pdf,png}` | Variance decomposition |
| `figures/main/fig_rf_importance.{pdf,png}` | RF importance (early version) |
| `figures/main/fig_xgb_shap_summary.{pdf,png}` | XGBoost SHAP beeswarm |
| `figures/main/fig_aic_akaike_ladder.{pdf,png}` | Standalone AIC ladder |
| `figures/main/fig_akaike_weights.{pdf,png}` | Standalone Akaike weights |
| `figures/main/fig_future_glmmTMB_vs_xgboost_rank.{pdf,png}` | Province rank concordance |
| `figures/diagnostics/fig_within_province_effort_variation.{pdf,png}` | Effort variance check |
| `figures/diagnostics/morans_i_distance_classes.{pdf,png}` | Moran's I distance plot |
| `figures/diagnostics/offset_reformulation_diagnostic.{pdf,png}` | Offset variants |

### Reports
| File | Description |
|---|---|
| `manuscript/audit_report_v2.docx` | First docx audit (~23 MB with v2 prefecture/county/plug-in sections) |

---

## v3 file family (relaxed, 463 species)

### Code
| File | Purpose |
|---|---|
| `code/46_riskset_v3_relaxed_threshold.R` | Build v3 risk set + headline M4 refit |
| `code/47_v3_all_effort_specs.R` | v3 × 4 effort spec × M0-M4 (20 fits) |
| `code/48_v3_prefecture_county_refit.R` | v3 prefecture + county refit (OOM-safe) |
| `code/49_v3_variable_importance.R` | v3 RF + XGBoost + SHAP + v2↔v3 rank shift |
| `code/50_v3_publication_figure_and_manuscript.R` | v3 robustness 5-panel + manuscript §3.10 |
| `code/51_v3_audit_report_docx.R` | Comprehensive v1/v2/v3 docx report |

### Persisted result tables
| File | Content |
|---|---|
| `data/derived/sdm_province_v3_relaxed.csv` | v3 candidate (species × province) set, 8,932 pairs |
| `data/derived/risk_set_province_v3.csv` | v3 full risk set (188,870 rows, gitignored due to size) |
| `results/tables/table_province_v3_coefs.csv` | v3 headline Spec B M0-M4 |
| `results/tables/table_province_v3_aic.csv` | v3 headline AIC ladder |
| `results/tables/table_province_v3_all_specs_coefs.csv` | v3 × 4 spec × M0-M4 = 60 rows |
| `results/tables/table_province_v3_all_specs_aic.csv` | v3 × 4 spec AIC + Akaike weights |
| `results/tables/table_province_v1_v2_v3_reconciliation.csv` | 3-run reconciliation |
| `results/tables/table_v3_prefecture_coefs.csv` | v3 prefecture refit M0-M4 |
| `results/tables/table_v3_county_coefs.csv` | v3 county refit M0-M4 |
| `results/tables/table_v3_prefecture_county_aic.csv` | v3 fine-scale AIC ladder |
| `results/tables/table_v3_three_scale_summary.csv` | v3 3-scale summary HR/CI/p |
| `results/tables/table_rf_importance_v3.csv` | v3 RF importance (rank shift vs v2) |
| `results/tables/table_xgb_cv_v3.csv` | v3 XGBoost CV-AUC |
| `results/tables/table_v2_v3_rf_comparison.csv` | v2↔v3 rank comparison |
| `results/diagnostics/table_riskset_v3_attrition.csv` | v3 attrition funnel |
| `results/diagnostics/table_province_riskset_completeness.csv` | Raw → v1 attrition chain |
| `results/diagnostics/table_missing_event_species_detail.csv` | 199 species dropped by v1 |

### Figures
| File | Description |
|---|---|
| `figures/main/Figure_2_province_headline_v3.{pdf,png}` | v3 3-panel (v1/v2/v3 forest + AIC + attrition) |
| `figures/main/Figure_2_province_headline_v3_all_specs.{pdf,png}` | v3 × 4 spec composite |
| `figures/main/Figure_3_v3_multiscale.{pdf,png}` | v3 3-scale forest (signal weakens) |
| `figures/main/Figure_4_variable_importance_v3.{pdf,png}` | v3 RF + rank shift + SHAP |
| `figures/main/Figure_v3_robustness_panel.{pdf,png}` | 5-panel v3 robustness composite |
| `figures/diagnostics/figure_riskset_attrition_funnel.{pdf,png}` | Raw → v1 attrition funnel |

### Reports
| File | Description |
|---|---|
| `manuscript/audit_report_v3.docx` | **Comprehensive v1/v2/v3 review** (~5.5 MB, 12 sections, 13 figures) |
| `manuscript/manuscript_v2.Rmd` (§3.10) | v3 sensitivity section |

---

## Pairing convention (read the two tracks side-by-side)

| v2 file | v3 counterpart | Notes |
|---|---|---|
| `Figure_2_province_headline.{pdf,png}` | `Figure_2_province_headline_v3.{pdf,png}` | v3 adds attrition + 3-run reconciliation |
| `Figure_3_multiscale_validation.{pdf,png}` | `Figure_3_v3_multiscale.{pdf,png}` | v3 shows fine-scale dilution |
| `Figure_4_variable_importance.{pdf,png}` | `Figure_4_variable_importance_v3.{pdf,png}` | v3 adds v2↔v3 rank comparison |
| `table_province_v2_coefs.csv` | `table_province_v3_coefs.csv` | Both same model formula |
| `table_province_v2_aic.csv` | `table_province_v3_aic.csv` | Both same AIC ladder |
| `table_prefecture_coefs.csv` | `table_v3_prefecture_coefs.csv` | Prefecture refit M0-M4 |
| `table_county_coefs.csv` | `table_v3_county_coefs.csv` | County refit M0-M4 |
| `table_rf_importance_v2.csv` | `table_rf_importance_v3.csv` | Compared in `table_v2_v3_rf_comparison.csv` |
| `audit_report_v2.docx` | `audit_report_v3.docx` | v3 supersedes |

## Shared files (no version split)

| File | Why shared |
|---|---|
| `data/raw/*` | Input data (symlinks to v1) |
| `data/spatial/basemap_GS2019_1822/*` | GS(2019)1822 shapefiles |
| `code/utils/*.R` | Helper functions |
| `code/00_run_all.R` | Pipeline entry |
| `manuscript/manuscript_v2.Rmd` | One manuscript, two sensitivity tracks |
| `_targets.R`, `renv.lock`, `.Rprofile` | Project infrastructure |
| `Figure_1_concept_and_workflow.{pdf,png}` | Concept figure (version-independent) |
| `Figure_5_province_future_hazard.{pdf,png}` | Province future (v2 SDM-tight basis) |
| `Figure_6_unit_future_hazard.{pdf,png}` | Unit future (v2 SDM-tight basis) |

## Pipeline reproducibility

Each track can be reproduced independently from raw inputs:

```bash
# v2 track (SDM-tight)
Rscript code/40c_province_only_refit.R      # province
Rscript code/42_prefecture_county_with_audit.R  # multi-scale + raw effort
Rscript code/41_provincial_future_panel.R       # future + RF + SHAP
Rscript code/44_unified_publication_figures.R   # Figures 1-6

# v3 track (relaxed)
Rscript code/46_riskset_v3_relaxed_threshold.R  # build + headline
Rscript code/47_v3_all_effort_specs.R           # 4 specs × M0-M4
Rscript code/48_v3_prefecture_county_refit.R    # multi-scale
Rscript code/49_v3_variable_importance.R        # RF + SHAP
Rscript code/50_v3_publication_figure_and_manuscript.R  # robustness panel

# Comprehensive Word report (depends on both tracks)
Rscript code/51_v3_audit_report_docx.R          # audit_report_v3.docx
```

---

## How the manuscript treats the two tracks

- **v2 = headline** (Methods §2, Results §3.1–3.9)
- **v3 = sensitivity analysis** (Results §3.10, "Relaxed risk-set check")

The v3 analysis is positioned as a robustness check confirming that the
headline interaction holds under a deliberately more inclusive
candidate-set construction.

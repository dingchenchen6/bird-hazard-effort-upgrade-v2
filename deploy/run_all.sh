#!/usr/bin/env bash
# ============================================================
# Server-side one-shot runner for v2.
# 服务器端一键执行。
# Usage:
#   cd <project_root>
#   ./deploy/run_all.sh            # full pipeline
#   ./deploy/run_all.sh --phase 1  # phase 1 only (critical fixes)
#   ./deploy/run_all.sh --phase 2  # phase 2 (ensemble + multi-scale)
#   ./deploy/run_all.sh --phase 3  # phase 3 (figures + manuscript)
# ============================================================

set -euo pipefail

V2="$(cd "$(dirname "$0")/.." && pwd)"
cd "$V2"

PHASE="all"
NO_INIT="--no-init-file"   # bypass .Rprofile / renv autoloader noise

while [[ $# -gt 0 ]]; do
  case "$1" in
    --phase) PHASE="$2"; shift 2 ;;
    --with-renv) NO_INIT=""; shift ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
done

mkdir -p logs results/tables results/diagnostics results/sensitivity \
         results/forecasts figures/main figures/supplementary \
         figures/diagnostics data/derived data_dictionary

ts() { date '+%Y-%m-%d %H:%M:%S'; }
log() { echo "[run_all $(ts)] $*"; }
run_R() {
  local script="$1"
  local name="$(basename "$script" .R)"
  local logf="logs/${name}.log"
  log "▶ $script  (log → $logf)"
  if Rscript $NO_INIT "$script" > "$logf" 2>&1; then
    log "✓ $name OK"
  else
    log "✗ $name FAILED — see $logf"
    return 1
  fi
}

# ----------------------------------------------------------------
# Phase 1: critical data + P0 fixes
# ----------------------------------------------------------------
phase_1() {
  log "===== PHASE 1: critical fixes ====="
  run_R code/28_grid_native_climate.R   || true
  run_R code/28b_grid_native_effort.R   || true
  run_R code/32_offset_reformulation.R  || true
  run_R code/33_grid_event_definition_fix.R || true
  run_R code/30_forecast_skill_decay.R  || true
  run_R code/26_spatial_block_cv.R      || true
  run_R code/27_morans_i_diagnostics.R  || true
}

# ----------------------------------------------------------------
# Phase 2: ensemble + multi-scale execution
# ----------------------------------------------------------------
phase_2() {
  log "===== PHASE 2: ensemble + multi-scale ====="
  run_R code/29_cmip6_ensemble_prediction.R || true
  run_R code/31_maup_sensitivity.R          || true
  run_R code/40_execute_five_scale_models.R || true
}

# ----------------------------------------------------------------
# Phase 3: figures + dictionary + self-check + manuscript
# ----------------------------------------------------------------
phase_3() {
  log "===== PHASE 3: figures + manuscript ====="
  run_R code/34_publication_figures_main.R          || true
  run_R code/35_publication_figures_supplementary.R || true
  run_R code/36_data_dictionary_export.R            || true
  run_R code/37_reproducibility_selfcheck.R         || true
  log "▶ knit manuscript_v2.Rmd"
  Rscript $NO_INIT -e \
    "rmarkdown::render('manuscript/manuscript_v2.Rmd', output_file='manuscript_v2.md')" \
    > logs/manuscript_render.log 2>&1 \
    && log "✓ manuscript rendered" \
    || log "✗ manuscript render failed — see logs/manuscript_render.log"
}

case "$PHASE" in
  1)   phase_1 ;;
  2)   phase_2 ;;
  3)   phase_3 ;;
  all) phase_1; phase_2; phase_3 ;;
  *) echo "Unknown phase: $PHASE" >&2; exit 2 ;;
esac

log "===== DONE ====="
log "Outputs:"
log "  results/tables/, results/diagnostics/, results/forecasts/"
log "  figures/main/, figures/supplementary/, figures/diagnostics/"
log "  manuscript/manuscript_v2.md"
log "Logs in logs/<script>.log"

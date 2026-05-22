#!/usr/bin/env bash
# ============================================================
# Local → server one-shot rsync for v2 (bird hazard upgrade).
# 本地推送到服务器。
# Usage:
#   ./deploy/rsync_to_server.sh user@server23.macroecology.org:/path/to/v2
#   ./deploy/rsync_to_server.sh user@server23:~/projects/bird_hazard_v2
# ============================================================

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <user@host:/dest/path>" >&2
  echo "Example: $0 chenchen@server23.macroecology.org:/home/chenchen/bird_hazard_v2" >&2
  exit 2
fi

DEST="$1"
LOCAL_V2="$(cd "$(dirname "$0")/.." && pwd)"
LOCAL_V1="$(cd "$LOCAL_V2/.." && pwd)/bird_hazard_model_effort_upgrade"
LOCAL_COMMUNITY="/Users/dingchenchen/Documents/New project/bird_dynamic_occupancy_analysis"
LOCAL_WORLDCLIM="/Users/dingchenchen/Documents/New project/bird_full_community_analysis/data/external/climate/wc2.1_10m"

echo "=== Step 1/3 : v2 project (code, manuscript, deploy, docs) ==="
rsync -avh --partial --progress \
  --exclude '.git/' --exclude 'targets/' --exclude '*.log' \
  --exclude 'data/raw/' --exclude 'data/spatial/' \
  --exclude 'data/derived/*.parquet' --exclude 'data/derived/*.fst' \
  --exclude 'logs/' --exclude '*.rds' \
  --exclude 'renv/library/' --exclude '.Rproj.user/' \
  --exclude 'figures/main/*.pdf' --exclude 'figures/supplementary/*.pdf' \
  --exclude 'figures/diagnostics/*.pdf' --exclude 'figures/*/*.png' \
  "$LOCAL_V2/" "$DEST/"

echo ""
echo "=== Step 2/3 : v1 raw data CSV (needed by data/raw symlinks) ==="
# These were symlinked locally — on the server we ship the real CSVs
# under data/raw/, preserving v1 directory layout.
rsync -avh --partial --progress \
  --include '*.csv' --include '*.xlsx' --exclude '*' \
  "$LOCAL_V1/data/" "$DEST/data/raw/"

echo ""
echo "=== Step 3a/3 : v1 GS(2019)1822 basemap shapefiles ==="
rsync -avh --partial --progress \
  "$LOCAL_V1/2019中国地图-审图号GS(2019)1822号/" \
  "$DEST/data/spatial/basemap_GS2019_1822/"

echo ""
echo "=== Step 3b/3 : community-dynamics Combined effort + grid sf ==="
rsync -avh --partial --progress \
  --include 'table_effort_by_grid_year_source_100km.csv' \
  --include 'table_effort_by_grid_year_source_10km.csv' \
  --include 'table_effort_by_grid_period_source.csv' \
  --exclude '*' \
  "$LOCAL_COMMUNITY/results_v2/" "$DEST/data/spatial/community_effort/"

rsync -avh --partial --progress \
  --include 'china_grid_100km_v2.rds' \
  --include 'china_grid_10km_v2.rds' \
  --exclude '*' \
  "$LOCAL_COMMUNITY/data/derived_v2/" "$DEST/data/spatial/community_grids/"

echo ""
echo "=== Step 3c/3 : WorldClim 2.1 10' bio rasters (optional, ~80 MB) ==="
read -r -p "Also push WorldClim 10m rasters (~80 MB)? [y/N] " ans
if [[ "${ans,,}" == y* ]]; then
  rsync -avh --partial --progress \
    --include 'wc2.1_10m_bio_*.tif' --include 'wc2.1_10m_elev.tif' \
    --exclude '*' \
    "$LOCAL_WORLDCLIM/" "$DEST/data/spatial/worldclim_10m/"
else
  echo "Skipped WorldClim. Either upload separately or wget on server."
fi

echo ""
echo "==== rsync DONE ===="
echo "On the server, run:"
echo "  cd $DEST"
echo "  Rscript deploy/install_packages.R   # one-off"
echo "  bash deploy/run_all.sh              # full pipeline"

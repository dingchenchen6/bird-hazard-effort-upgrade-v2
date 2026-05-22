#!/usr/bin/env bash
# ============================================================
# 在服务器上跑：扫描所有可能已经存在的 v1 数据 / 基础底图 /
# 群落动态分析 effort / WorldClim / CHELSA / CMIP6，列出
# "已有 | 缺失 | 大小" 的清单。基于此决定 rsync 只补缺失的部分。
#
# Server-side scan. SSH 上去后:
#   bash check_remote_data.sh           # 用默认搜索路径
#   bash check_remote_data.sh /scratch  # 加搜索根
#
# Outputs:
#   /tmp/v2_remote_inventory.txt        # 完整清单
#   /tmp/v2_remote_missing.txt          # 需要 rsync 的文件名列表
# ============================================================

set -uo pipefail

declare -a SEARCH_ROOTS
SEARCH_ROOTS=(
  "$HOME"
  "$HOME/projects"
  "$HOME/work"
  "$HOME/data"
  "/data" "/data1" "/data2" "/scratch" "/mnt"
  "/srv" "/share" "/storage"
)
# 额外用户指定根
for d in "$@"; do SEARCH_ROOTS+=("$d"); done

INV=/tmp/v2_remote_inventory.txt
MISS=/tmp/v2_remote_missing.txt
: > "$INV"; : > "$MISS"

log() { echo "[$(date '+%H:%M:%S')] $*" | tee -a "$INV"; }

log "=========================================================="
log "Server inventory scan for bird_hazard_v2 dependencies"
log "Host : $(hostname)"
log "User : $(whoami)"
log "Free disk on \$HOME ($(df -h "$HOME" | awk 'NR==2{print $2}' || echo n/a) total):"
df -h "$HOME" 2>/dev/null | sed -e 's/^/    /' | tee -a "$INV"
log "Search roots: ${SEARCH_ROOTS[*]}"
log "----------------------------------------------------------"

# 受检查的文件清单 ----------------------------------------------------
# 每一项: <local-relative-path>|<unique-token-to-find>
declare -a ITEMS=(
  # v1 raw CSV
  "data/raw/hazard_risk_upgraded_complete_case.csv|hazard_risk_upgraded_complete_case.csv"
  "data/raw/hazard_risk_upgraded_range_map_anom.csv|hazard_risk_upgraded_range_map_anom.csv"
  "data/raw/effort_panel_upgraded.csv|effort_panel_upgraded.csv"
  "data/raw/climate_metrics_province_year.csv|climate_metrics_province_year.csv"
  "data/raw/displacement_metrics.csv|displacement_metrics.csv"
  "data/raw/events_50km_grid_assigned.csv|events_50km_grid_assigned.csv"
  "data/raw/events_100km_grid_assigned.csv|events_100km_grid_assigned.csv"
  "data/raw/grid_50km_base.csv|grid_50km_base.csv"
  "data/raw/grid_50km_climate.csv|grid_50km_climate.csv"
  "data/raw/grid_50km_effort.csv|grid_50km_effort.csv"
  "data/raw/grid_50km_risk_set.csv|grid_50km_risk_set.csv"
  "data/raw/grid_50km_sdm_sample.csv|grid_50km_sdm_sample.csv"
  "data/raw/grid_100km_base.csv|grid_100km_base.csv"
  "data/raw/grid_100km_climate.csv|grid_100km_climate.csv"
  "data/raw/grid_100km_effort.csv|grid_100km_effort.csv"
  "data/raw/grid_100km_risk_set.csv|grid_100km_risk_set.csv"
  "data/raw/grid_100km_sdm_sample.csv|grid_100km_sdm_sample.csv"
  "data/raw/species_historical_range_centroid.csv|species_historical_range_centroid.csv"
  "data/raw/species_native_climate_centroid.csv|species_native_climate_centroid.csv"
  "data/raw/species_range_native_anom.csv|species_range_native_anom.csv"
  "data/raw/bird_new_records_20260509.xlsx|鸟类新纪录20260509.xlsx"
  # GS(2019)1822 basemap (anchor shapefile)
  "data/spatial/basemap_GS2019_1822/province_albers.shp|省（等积投影）.shp"
  "data/spatial/basemap_GS2019_1822/prefecture.shp|市.shp"
  "data/spatial/basemap_GS2019_1822/county.shp|县.shp"
  # community effort + grid sf
  "data/spatial/community_effort/table_effort_by_grid_year_source_100km.csv|table_effort_by_grid_year_source_100km.csv"
  "data/spatial/community_effort/table_effort_by_grid_year_source_10km.csv|table_effort_by_grid_year_source_10km.csv"
  "data/spatial/community_grids/china_grid_100km_v2.rds|china_grid_100km_v2.rds"
  "data/spatial/community_grids/china_grid_10km_v2.rds|china_grid_10km_v2.rds"
  # WorldClim 2.1 10m
  "data/spatial/worldclim_10m/wc2.1_10m_bio_1.tif|wc2.1_10m_bio_1.tif"
  "data/spatial/worldclim_10m/wc2.1_10m_bio_4.tif|wc2.1_10m_bio_4.tif"
  "data/spatial/worldclim_10m/wc2.1_10m_bio_12.tif|wc2.1_10m_bio_12.tif"
  "data/spatial/worldclim_10m/wc2.1_10m_bio_15.tif|wc2.1_10m_bio_15.tif"
  "data/spatial/worldclim_10m/wc2.1_10m_elev.tif|wc2.1_10m_elev.tif"
  # CHELSA v2.1 monthly (used by code/28_grid_native_climate.R)
  "data/spatial/chelsa/tas/CHELSA_tas_*_2010_V.2.1.tif|CHELSA_tas_"
  "data/spatial/chelsa/pr/CHELSA_pr_*_2010_V.2.1.tif|CHELSA_pr_"
  # CMIP6 (optional, large)
  "data/spatial/chelsa/cmip6/ACCESS-CM2/ssp585/2050/tas.tif|cmip6"
)

# 准备 find 的 -path 限制（仅根目录中存在的）
EXISTING_ROOTS=()
for r in "${SEARCH_ROOTS[@]}"; do
  [ -d "$r" ] && EXISTING_ROOTS+=("$r")
done
log "Existing roots: ${EXISTING_ROOTS[*]:-NONE}"

# 用一次性 find 把所有 token 找出来（更高效）
TOKENS=()
declare -A LOCAL_FOR_TOKEN
for item in "${ITEMS[@]}"; do
  local_path="${item%%|*}"
  token="${item##*|}"
  LOCAL_FOR_TOKEN["$token"]="$local_path"
  TOKENS+=("$token")
done

# 单次 find，做 substring 匹配
HITS=/tmp/v2_remote_hits.txt
: > "$HITS"
log "Running find (this may take 30–120 s)…"
for token in "${TOKENS[@]}"; do
  # 用 -name 精准匹配（含通配符则用 -path）
  if [[ "$token" == *"*"* ]]; then
    pattern="$token"
    finder=(-path "*${pattern}*")
  else
    finder=(-name "$token")
  fi
  for r in "${EXISTING_ROOTS[@]}"; do
    find "$r" -type f -mount "${finder[@]}" 2>/dev/null \
      | head -3 | while read -r f; do
        sz=$(stat -c '%s' "$f" 2>/dev/null || stat -f '%z' "$f" 2>/dev/null)
        echo "$token|$f|${sz:-0}" >> "$HITS"
      done
  done
done

# 汇总
log "----------------------------------------------------------"
log "Inventory result:"
log "  Format: STATUS | local-target-path | size (MB) | remote-found-path"
log "----------------------------------------------------------"

n_have=0; n_miss=0; total_have=0; total_miss=0
for item in "${ITEMS[@]}"; do
  local_path="${item%%|*}"
  token="${item##*|}"
  found_line=$(grep -F "${token}|" "$HITS" 2>/dev/null | head -1)
  if [ -n "$found_line" ]; then
    rp=$(echo "$found_line" | awk -F'|' '{print $2}')
    sz=$(echo "$found_line" | awk -F'|' '{print $3}')
    sz_mb=$(awk -v s="$sz" 'BEGIN{printf "%.1f", s/1024/1024}')
    log "  HAVE | $local_path | $sz_mb MB | $rp"
    n_have=$((n_have+1)); total_have=$((total_have+${sz:-0}))
  else
    log "  MISS | $local_path | -- | (not found)"
    echo "$local_path" >> "$MISS"
    n_miss=$((n_miss+1))
  fi
done

log "----------------------------------------------------------"
log "Summary"
log "  HAVE: $n_have files, total $(awk -v s="$total_have" 'BEGIN{printf "%.2f", s/1024/1024/1024}') GB"
log "  MISS: $n_miss files (paths written to $MISS)"
log "----------------------------------------------------------"
log "Decision:"
if [ "$n_miss" -eq 0 ]; then
  log "  → All data present on server. Skip rsync; symlink everything into v2."
else
  log "  → Run 'deploy/rsync_to_server.sh ...' to push only the MISSING items."
  log "  → Or edit deploy/rsync_to_server.sh to skip files already present."
fi
log "----------------------------------------------------------"
log "Full inventory : $INV"
log "Missing list   : $MISS"

# 友好提示：如果用户希望把已发现的远程文件 symlink 到 v2，
# 写一个 helper script。
SYM=/tmp/v2_symlink_existing.sh
: > "$SYM"
echo "#!/usr/bin/env bash" >> "$SYM"
echo "# Auto-generated by check_remote_data.sh — symlink already-present" >> "$SYM"
echo "# server-side files into the v2 layout. Run from v2 project root." >> "$SYM"
echo "set -e" >> "$SYM"
echo "V2=\"\$(pwd)\"" >> "$SYM"
for item in "${ITEMS[@]}"; do
  local_path="${item%%|*}"
  token="${item##*|}"
  found_line=$(grep -F "${token}|" "$HITS" 2>/dev/null | head -1)
  if [ -n "$found_line" ]; then
    rp=$(echo "$found_line" | awk -F'|' '{print $2}')
    dst="\$V2/$local_path"
    echo "mkdir -p \"\$(dirname \"$dst\")\"" >> "$SYM"
    echo "ln -sfn \"$rp\" \"$dst\"" >> "$SYM"
  fi
done
chmod +x "$SYM"
log "Symlink helper : $SYM (review and run from v2 root)"

#!/usr/bin/env bash
# ============================================================
# 在本地跑：根据服务器返回的 /tmp/v2_remote_missing.txt
# 只 rsync 缺失的文件，不重复传 v1 的 6.9 GB。
# Usage:
#   1) ssh server 'bash check_remote_data.sh'
#   2) scp server:/tmp/v2_remote_missing.txt /tmp/v2_remote_missing.txt
#   3) ./deploy/rsync_missing_only.sh user@host:/dest /tmp/v2_remote_missing.txt
# 或者一行链：
#   ssh user@host 'bash bird_hazard_v2/deploy/check_remote_data.sh' \
#     && scp user@host:/tmp/v2_remote_missing.txt /tmp/ \
#     && ./deploy/rsync_missing_only.sh user@host:/home/user/bird_hazard_v2 /tmp/v2_remote_missing.txt
# ============================================================

set -euo pipefail

if [ $# -lt 2 ]; then
  cat <<EOF >&2
Usage: $0 <user@host:/dest> <local-missing-list.txt>

The missing list is the file printed by check_remote_data.sh on the
server as /tmp/v2_remote_missing.txt (one local-target-path per line,
e.g. data/raw/grid_50km_risk_set.csv).
EOF
  exit 2
fi

DEST="$1"
MISS_LIST="$2"
LOCAL_V2="$(cd "$(dirname "$0")/.." && pwd)"
LOCAL_V1="$(cd "$LOCAL_V2/.." && pwd)/bird_hazard_model_effort_upgrade"
LOCAL_COMM="/Users/dingchenchen/Documents/New project/bird_dynamic_occupancy_analysis"
LOCAL_WC="/Users/dingchenchen/Documents/New project/bird_full_community_analysis/data/external/climate/wc2.1_10m"

if [ ! -f "$MISS_LIST" ]; then
  echo "Missing list not found: $MISS_LIST" >&2
  exit 2
fi

# 把每条缺失记录翻译成 (本地源, 远端目标) 对，然后批量 rsync。
TMPMAP=$(mktemp)
trap "rm -f $TMPMAP" EXIT

while IFS= read -r dst_rel; do
  [ -z "$dst_rel" ] && continue
  case "$dst_rel" in
    data/raw/bird_new_records_*.xlsx)
      # 本地是中文文件名 鸟类新纪录20260509.xlsx
      src=$(ls "$LOCAL_V1"/鸟类新纪录*.xlsx 2>/dev/null | head -1)
      ;;
    data/raw/*.csv|data/raw/*.xlsx)
      src="$LOCAL_V1/data/$(basename "$dst_rel")"
      ;;
    data/spatial/basemap_GS2019_1822/*)
      # 整个 basemap 目录直接整体推
      src="$LOCAL_V1/2019中国地图-审图号GS(2019)1822号/"
      dst_rel="data/spatial/basemap_GS2019_1822/"
      ;;
    data/spatial/community_effort/*)
      src="$LOCAL_COMM/results_v2/$(basename "$dst_rel")"
      ;;
    data/spatial/community_grids/*)
      src="$LOCAL_COMM/data/derived_v2/$(basename "$dst_rel")"
      ;;
    data/spatial/worldclim_10m/*)
      src="$LOCAL_WC/$(basename "$dst_rel")"
      ;;
    *)
      # v2 自身代码 / manuscript / deploy — 单独处理
      src="$LOCAL_V2/$dst_rel"
      ;;
  esac
  if [ -e "$src" ]; then
    echo "$src|$dst_rel" >> "$TMPMAP"
  else
    echo "  WARN: local source missing for $dst_rel  (looked at $src)"
  fi
done < "$MISS_LIST"

n=$(wc -l < "$TMPMAP" | tr -d ' ')
echo "Will rsync $n entries to $DEST"
echo

if [ "$n" -eq 0 ]; then
  echo "Nothing to do — server already has everything in your missing list."
  exit 0
fi

# 去重 + 排序
sort -u "$TMPMAP" -o "$TMPMAP"

# 推送
while IFS='|' read -r src dst_rel; do
  remote_path="$DEST/$dst_rel"
  echo "→ $src"
  echo "  → $remote_path"
  rsync -avh --partial --progress --mkpath "$src" "$remote_path"
  echo
done < "$TMPMAP"

echo "==== rsync_missing_only DONE ===="
echo "Tip: 在服务器上重跑一次自检确认全部就绪:"
echo "  ssh $DEST 'cd $(dirname "$DEST" | sed "s|.*:||"); bash deploy/check_remote_data.sh'"

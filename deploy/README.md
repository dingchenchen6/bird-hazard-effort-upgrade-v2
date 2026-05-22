# Server deployment — bird hazard v2

本目录把 v2 完整流水线打包成"本地一键推 + 服务器一键跑"的两个脚本。
本地 macOS 上的进程已全部 `pkill -f Rscript` 终止，所有重活转到服务器执行。

## 前置条件

**本地端**：

- `rsync ≥ 3.0`、`ssh` 已配置好对服务器 22 端口的访问（如需 VPN，请先连 VPN）。
- 项目根目录已在
  `/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2/`。

**服务器端**：

- R ≥ 4.3.0（推荐 4.4.x）。
- 系统依赖（已 root 安装常见包即可）：
  `gdal-devel proj-devel udunits2-devel libxml2-devel libcurl-devel libssl-devel`。
- 至少 32 GB RAM、30 GB 自由磁盘、16 核（推荐）。
- 网络可访问 `https://cloud.r-project.org` 来装 R 包。

---

## 一、先查后传（推荐：避免重复传 6.9 GB）

服务器上很可能已经有 v1 原始数据 / 基础底图 / WorldClim 等。先扫一遍，再只补缺失。

**步骤 1 — 在本地推送代码骨架到服务器**（小，~3 MB）：

```bash
cd /Users/dingchenchen/Documents/New\ records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2

# 只推 deploy/ + code/ + manuscript/ + docs，不传任何数据
rsync -avh --partial --progress \
  --exclude 'data/' --exclude 'logs/' --exclude 'targets/' \
  --exclude 'renv/library/' --exclude 'figures/*/*.pdf' \
  --exclude 'figures/*/*.png' \
  ./ <user>@<server>:<dest>/
```

**步骤 2 — 在服务器上跑自检脚本**：

```bash
ssh <user>@<server>
cd <dest>
bash deploy/check_remote_data.sh        # 也可以追加搜索根: bash deploy/check_remote_data.sh /scratch /share
cat /tmp/v2_remote_inventory.txt | tail -50    # 看一眼结果
```

输出（举例）：

```
HAVE | data/raw/grid_100km_risk_set.csv | 1394 MB | /scratch/dingchenchen/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade/data/grid_100km_risk_set.csv
HAVE | data/spatial/basemap_GS2019_1822/province_albers.shp | 32 MB | /share/data/cn_shp/2019中国地图.../省（等积投影）.shp
MISS | data/spatial/community_effort/table_effort_by_grid_year_source_100km.csv | -- | (not found)
...
Summary
  HAVE: 27 files, total 6.8 GB
  MISS: 5 files (paths written to /tmp/v2_remote_missing.txt)
```

**步骤 3a — 已有的直接 symlink（不复制，节省磁盘）**：

```bash
# 上一步自动生成的 helper
bash /tmp/v2_symlink_existing.sh        # 在 v2 项目根目录下跑，会把远端原文件 symlink 进 v2/data/raw 等
```

**步骤 3b — 缺失的从本地补推**（在本地执行）：

```bash
# 把服务器的 missing 列表拷回本地
scp <user>@<server>:/tmp/v2_remote_missing.txt /tmp/v2_remote_missing.txt

# 只 rsync 缺失项（通常只剩 community effort / WorldClim 几 MB 到几十 MB）
./deploy/rsync_missing_only.sh <user>@<server>:<dest> /tmp/v2_remote_missing.txt
```

---

## 一·B、全量推送（不推荐，备选）

如果你确定服务器上完全没有相关数据：

```bash
./deploy/rsync_to_server.sh chenchen@server23.macroecology.org:/home/chenchen/bird_hazard_v2
```

rsync 会按 3 步推送：

| 步 | 内容 | 大小估算 |
|----|------|----------|
| 1 | v2 代码 + manuscript + deploy + docs（排除 `data/raw`、`logs`、`*.pdf`、`renv/library`）| ~3 MB |
| 2 | v1 原始 CSV / xlsx（v2 里是符号链接，服务器需实文件）| ~7 GB（含 50/100 km risk_set）|
| 3a | GS(2019)1822 基础底图 shapefile | ~30 MB |
| 3b | 群落动态分析的 Combined effort + grid sf | ~5 MB |
| 3c | WorldClim 2.1 10' bio 栅格（**可选**，会被询问 y/N）| ~80 MB |

> 如果服务器没装 WorldClim，可在服务器上直接 `wget` 从 https://worldclim.org/data/worldclim21.html 拿。

---

## 二、服务器端：装 R 包 + 适配路径 + 一键跑

```bash
ssh chenchen@server23.macroecology.org
cd /home/chenchen/bird_hazard_v2

# Step 1: 装 R 包（首次约 15–25 min）
Rscript deploy/install_packages.R

# Step 2: 把脚本里硬编码的 macOS 路径改成服务器路径
Rscript deploy/setup_server_paths.R

# Step 3: 一键跑全部 phase（4–6 小时；16 核 / 64 GB）
bash deploy/run_all.sh

# 也可分阶段跑：
# bash deploy/run_all.sh --phase 1   # P0 关键修复 + Moran + spatial CV
# bash deploy/run_all.sh --phase 2   # CMIP6 集合 + MAUP + 五尺度
# bash deploy/run_all.sh --phase 3   # 出版图 + 数据字典 + 自检 + manuscript
```

每个脚本的日志写到 `logs/<script>.log`，错误不会中断整体流水线。

---

## 三、产出位置（服务器端）

```
$DEST/
├── results/tables/         # 所有 CSV 结果表（含五尺度对比）
├── results/diagnostics/    # DHARMa / Moran / spatial CV 诊断
├── results/sensitivity/    # MAUP / offset / 敏感性
├── results/forecasts/      # CMIP6 集合 + skill decay
├── figures/main/           # Fig 1–6 @ 600 dpi PDF + PNG
├── figures/supplementary/  # Fig S1–S15
├── figures/diagnostics/    # 内部 QA 图
├── data/derived/           # 网格原生气候 + effort + 风险集
├── data_dictionary/        # YAML schema + variables_master.csv
├── manuscript/manuscript_v2.md   # knitted (Word 也可加 reference_docx)
└── logs/                   # 每脚本日志 + sessionInfo
```

---

## 四、拉回本地（可选）

跑完后只拉关键产出回本地查看：

```bash
# 从服务器拉回（在本地执行）
rsync -avh chenchen@server23.macroecology.org:/home/chenchen/bird_hazard_v2/results/ \
  /Users/dingchenchen/Documents/New\ records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2/results/

rsync -avh chenchen@server23.macroecology.org:/home/chenchen/bird_hazard_v2/figures/ \
  /Users/dingchenchen/Documents/New\ records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2/figures/

rsync -avh chenchen@server23.macroecology.org:/home/chenchen/bird_hazard_v2/manuscript/ \
  /Users/dingchenchen/Documents/New\ records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2/manuscript/
```

---

## 五、常见问题

**Q1: 服务器装 sf / terra 时报 `Package 'gdal' / 'proj' not found`？**
A: root 执行 `dnf install -y gdal-devel proj-devel udunits2-devel`（CentOS / Rocky）或
`apt install -y libgdal-dev libproj-dev libudunits2-dev`（Ubuntu）。

**Q2: glmmTMB 拟合 100km 网格 5×10⁶ 行模型 OOM？**
A: 编辑 `code/40_execute_five_scale_models.R`，把 `species`-级的拟合分批；
或先 `subset` 到 species n_events ≥ 3 的物种，再拟合。

**Q3: blockCV 装不上？**
A: 它依赖 `terra` 与 `sf`。先确保 GDAL/PROJ 装好；如仍失败可在
`install_packages.R` 移除 `blockCV`，跳过 `code/26_spatial_block_cv.R`。

**Q4: 五尺度模型跑得太慢？**
A: 先用 `Rscript code/40_execute_five_scale_models.R` 单独跑（约 30–90 min on 16-core）。
如需更快，注释掉 `fit_models` 里的 M0 / M1 / M2，只保留 M3 / M4。

**Q5: 中文文件名（"省（等积投影）.shp"）在 Linux 服务器上乱码？**
A: 确保 server locale 为 `zh_CN.UTF-8` 或 `en_US.UTF-8`；
`export LC_ALL=en_US.UTF-8` 后 `Rscript` 即可。

---

## 六、停掉服务器端正在跑的任务

```bash
ssh chenchen@server23.macroecology.org \
  'pkill -f Rscript; pkill -f targets::tar_make'
```

或者只杀单个 phase：

```bash
ssh chenchen@server23.macroecology.org \
  'pgrep -fa "code/40_execute_five_scale_models" | head -5'
ssh chenchen@server23.macroecology.org 'pkill -f code/40_execute_five_scale_models'
```

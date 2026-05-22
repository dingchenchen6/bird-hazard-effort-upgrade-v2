# 多尺度风险集构建与建模（市 + 县 + 100km 网格）

## 概述

本分析在**省级模型**之外，新增三个空间尺度的危险率模型分析：

1. **Prefecture（市）水平**：基于新纪录经纬度点对应的市 + SDM潜在分布市
2. **County（县）水平**：基于新纪录经纬度点对应的县 + SDM潜在分布县
3. **100km 网格水平**：复用 `data/derived/risk_set_grid_100km_v2.csv`（已构建）

⚠️ **重要**：所有输出保存在独立目录 `outputs_multiscale/`，**不会覆盖**原有的省级模型结果。

---

## 推荐脚本：`code/51_multiscale_full.R`（最新）

> 旧脚本 `code/50_multiscale_risk_build_and_model.R` 已被 51 取代（50 中市/县被错误跳过，仅拟合 M0；保留供溯源参考）。

`51_multiscale_full.R` 复用 `code/40_execute_five_scale_models.R` 的核心函数
（`build_admin_risk()` + `fit_models()`），但所有输出路径重定向至
`outputs_multiscale/`，不动 `results/`、`figures/`、`data/derived/` 下的现有文件。

| 文件 | 说明 |
|------|------|
| `code/51_multiscale_full.R` | 主脚本 |
| `outputs_multiscale/data/derived/` | 4 个尺度的风险集（CSV） |
| `outputs_multiscale/results/tables/` | M0–M4 系数表、AIC 比较表 |
| `outputs_multiscale/figures/main/` | M4 交互森林图 |
| `outputs_multiscale/logs/` | 运行日志和 sessionInfo |

---

## 依赖包

```r
data.table, sf, glmmTMB, ggplot2
```
（服务器上已通过 `deploy/install_packages.R` 安装，参见 `renv.lock`）

---

## 服务器执行步骤

### 1. 同步代码到服务器

本地（macOS）：
```bash
cd /Users/dingchenchen/Documents/New\ records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade_v2
bash deploy/rsync_to_server.sh user@server:/path/to/v2
```
`rsync_to_server.sh` 已经包含 `code/*.R`，新增的 `51_multiscale_full.R`
会自动一起上传。同时 v1 的市/县 shp 通过 Step 3a 同步到
`data/spatial/basemap_GS2019_1822/`。

### 2. 检查数据文件

```bash
ssh user@server
cd /path/to/v2

# 必备数据
ls -la data/raw/events_100km_grid_assigned.csv
ls -la data/raw/effort_panel_upgraded.csv
ls -la data/raw/climate_metrics_province_year.csv
ls -la data/raw/hazard_risk_upgraded_complete_case.csv
ls -la data/derived/risk_set_grid_100km_v2.csv

# shapefile（任一目录有即可，脚本会自动搜索）
ls -la data/spatial/basemap_GS2019_1822/市*.shp
ls -la data/spatial/basemap_GS2019_1822/县*.shp
```

### 3. 后台执行（推荐）

```bash
cd /path/to/v2
mkdir -p outputs_multiscale/logs

nohup Rscript code/51_multiscale_full.R \
  --base-dir "$PWD" \
  --output-dir outputs_multiscale \
  > outputs_multiscale/logs/nohup.out 2>&1 &

# 查看进度
tail -f outputs_multiscale/logs/51_multiscale.log
```

如果服务器内存有限或想先验证流水线，可加 `--skip-county` 跳过最重的县级模型：
```bash
nohup Rscript code/51_multiscale_full.R \
  --base-dir "$PWD" \
  --output-dir outputs_multiscale \
  --skip-county \
  > outputs_multiscale/logs/nohup_no_county.out 2>&1 &
```

### 4. tmux 运行（更稳定）

```bash
tmux new -s multiscale
cd /path/to/v2
Rscript code/51_multiscale_full.R --base-dir "$PWD" --output-dir outputs_multiscale
# Ctrl+B  D 离开；tmux attach -t multiscale 重连
```

---

## 命令行参数

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `--base-dir` | 本地 v2 绝对路径 | v2 项目根目录 |
| `--output-dir` | `outputs_multiscale` | 输出子目录（相对 base-dir）|
| `--v1-dir` | `../bird_hazard_model_effort_upgrade` | v1 数据/shp 目录（用于 fallback）|
| `--year-min` | `2002` | 起始年份 |
| `--year-max` | `2024` | 终止年份 |
| `--skip-county` | （flag）| 跳过县级模型 |

---

## 输出结构

```
outputs_multiscale/
├── data/derived/
│   ├── risk_set_province.csv       # 省级风险集（v2 重建）
│   ├── risk_set_prefecture.csv     # 市级风险集（371 市）
│   ├── risk_set_county.csv         # 县级风险集（2901 县）
│   └── risk_set_grid_100km.csv     # 100km 网格风险集
├── results/tables/
│   ├── table_multiscale_coefficients.csv   # 4 尺度 × M0–M4 × 系数
│   └── table_multiscale_aic.csv            # AIC + dAIC（按 scale 排序）
├── figures/main/
│   ├── fig_multiscale_M4_forest.pdf
│   └── fig_multiscale_M4_forest.png        # 600 dpi
└── logs/
    ├── 51_multiscale.log
    └── 51_sessionInfo.txt
```

---

## 模型说明

### M0–M4（cloglog 逻辑 GLMM）

| 模型 | 公式（`re_form = (1|species)+(1|unit)`）|
|------|--------|
| M0 | `event ~ 1 + re_form` |
| M1 | `event ~ effort_z + re_form` |
| M2 | `event ~ climate_z + re_form` |
| M3 | `event ~ climate_z + effort_z + re_form` |
| M4 | `event ~ climate_z * effort_z + re_form`（**核心**） |

- 4 个尺度 `unit` 分别为：`province`, `unit_id`（市/县）, `grid_id`（100km）
- `climate_z` = `climate_velocity_z`（省级时间维度气候）
- `effort_z` = 市/县为 event-share 分配后的 `log_n_events_z`；网格为
  `log_n_events_z`（已由 script 40 准备）
- 族：`binomial(link="cloglog")` → 离散时间 hazard

### M4 交互（climate × effort）

- HR > 1 且显著 → 气候暴露与调查 effort **协同**驱动新纪录
- HR ≈ 1 → 无交互
- HR < 1 → 交互为负

---

## 与原 v2 流水线的关系

| 方面 | v2 原流水线 | 本多尺度分析（51） |
|------|--------------|----------------------|
| 省级模型 | `results/tables/table_five_scale_coefficients.csv` | 重新拟合一次（独立输出）|
| 风险集 | `data/derived/risk_set_grid_100km_v2.csv` | 复用；同时构建市/县 |
| 输出目录 | `data/derived/`, `results/`, `figures/main/` | **独立**：`outputs_multiscale/` |
| 脚本编号 | 01–41 | 51（替代旧 50）|
| 是否覆盖 | - | **否**，完全独立 |

---

## 故障排查

### 找不到 shapefile

脚本按以下顺序搜索市/县 shp：
1. `<v1_dir>/2019中国地图-审图号GS(2019)1822号/`
2. `<base_dir>/2019中国地图-审图号GS(2019)1822号/`
3. `<base_dir>/data/spatial/basemap_GS2019_1822/`
4. `<base_dir>/data/spatial/basemap/`
5. `<base_dir>/data/spatial/`

确保至少一处含有 `市*.shp` 和 `县*.shp`。`rsync_to_server.sh` 默认推送到
（3）`data/spatial/basemap_GS2019_1822/`。

### glmmTMB 拟合失败

- 检查 `outputs_multiscale/logs/51_multiscale.log` 中的 `failed:` 行
- 县级（2901 单位）可能因内存或共线性失败；可加 `--skip-county` 排除
- 也可先用 `--year-min 2010` 缩短时间维度做快速验证

### 内存不足

- 县级 M4（2 个 RE）可能耗内存几十 GB
- 建议先单独跑 `--skip-county`，确认市/网格 OK 后再单独补县
- 如需，可在脚本头部添加 `Sys.setenv(OMP_NUM_THREADS = 1)` 控制并行

---

## 预期运行时间（参考）

| 尺度 | 风险集构建 | 拟合 M0–M4 | 总计 |
|------|------------|-------------|------|
| Province | 数秒 | 5–15 min | ~15 min |
| Prefecture（371 单位）| ~5 min | 15–40 min | ~30–45 min |
| County（2901 单位）| ~15 min | 1–3 h | ~2–3 h |
| 100km grid | ~2 min | 30–90 min | ~60–90 min |

**总计**：3–6 小时（取决于服务器 CPU/RAM）

---

## 历史脚本

`code/50_multiscale_risk_build_and_model.R` —— 已**取代**。

50 中跳过市/县（基于过时的"shapefile 不完整"判断），且只拟合了
M0。51 已修复这两点，并复用 40 中验证过的 `build_admin_risk()`/
`fit_models()` 函数。

---

**最后更新**：2026-05-22
**当前推荐脚本**：`code/51_multiscale_full.R`
**兼容性**：R ≥ 4.0, glmmTMB ≥ 1.0, sf ≥ 1.0

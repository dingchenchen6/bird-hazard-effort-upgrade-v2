# ============================================================
# After rsync, the server's data/raw is real CSVs and data/spatial has
# basemap + community + worldclim subdirs at known paths. This script
# patches the path constants used by code/40_execute_five_scale_models.R
# (originally hard-coded to my macOS layout) so it works on the server
# without further edits. 服务器路径适配。
# Run once after rsync, on the server:
#   Rscript deploy/setup_server_paths.R
# ============================================================

v2 <- normalizePath(".", mustWork = TRUE)

patch <- function(path, pattern, replacement) {
  txt <- readLines(path, warn = FALSE, encoding = "UTF-8")
  new <- gsub(pattern, replacement, txt, fixed = TRUE, useBytes = FALSE)
  if (!identical(txt, new)) {
    writeLines(new, path, useBytes = FALSE)
    cat("  patched", path, "\n")
  } else {
    cat("  unchanged", path, "(pattern not present)\n")
  }
}

cat("== Patching code/40_execute_five_scale_models.R paths ==\n")
file_40 <- file.path("code", "40_execute_five_scale_models.R")

# v1 path  →  server-local data/raw
patch(file_40,
      "V1 <- \"/Users/dingchenchen/Documents/New records/bird-new-distribution-records/tasks/bird_hazard_model_effort_upgrade\"",
      sprintf("V1 <- \"%s\"  # rsync target: same as v2/data/raw layout", v2))

# Community-dynamics local path  →  server-local data/spatial/community_effort
patch(file_40,
      "COMM <- \"/Users/dingchenchen/Documents/New project/bird_dynamic_occupancy_analysis\"",
      sprintf("COMM <- \"%s\"", v2))

# Inside COMM the script joins file.path(COMM, \"results_v2\", \"table_effort_by_grid_year_source_100km.csv\")
# We restructure to point to the server layout instead.
patch(file_40,
      "file.path(COMM, \"results_v2\",",
      "file.path(V2, \"data\", \"spatial\", \"community_effort\",")

patch(file_40,
      "file.path(COMM, \"data\", \"derived_v2\",",
      "file.path(V2, \"data\", \"spatial\", \"community_grids\",")

# WorldClim path
patch(file_40,
      "WC   <- \"/Users/dingchenchen/Documents/New project/bird_full_community_analysis/data/external/climate/wc2.1_10m\"",
      sprintf("WC   <- \"%s\"", file.path(v2, "data", "spatial", "worldclim_10m")))

# v1 basemap inside V1 → data/spatial/basemap_GS2019_1822
patch(file_40,
      "file.path(V1, \"2019中国地图-审图号GS(2019)1822号\")",
      "file.path(V2, \"data\", \"spatial\", \"basemap_GS2019_1822\")")

# raw CSV inside V1/data → V2/data/raw
patch(file_40,
      "file.path(V1, \"data\",",
      "file.path(V2, \"data\", \"raw\",")

# Define V2 at the top if missing.
txt <- readLines(file_40, warn = FALSE, encoding = "UTF-8")
if (!any(grepl("^V2 <-", txt))) {
  insert_after <- grep("^V2 <-", txt)[1]
  if (is.na(insert_after)) {
    idx <- grep("^V1 <-", txt)[1]
    if (!is.na(idx)) {
      txt <- append(txt,
                    sprintf("V2 <- \"%s\"", v2),
                    after = idx - 1L)
      writeLines(txt, file_40, useBytes = FALSE)
      cat("  inserted V2 path constant\n")
    }
  }
}

cat("\n== Verifying basemap shp present ==\n")
shps <- list.files(file.path("data", "spatial", "basemap_GS2019_1822"),
                    pattern = "\\.shp$", full.names = TRUE)
cat(sprintf("  found %d shapefiles under data/spatial/basemap_GS2019_1822/\n",
             length(shps)))
if (length(shps) == 0L) {
  warning("Basemap shapefiles are missing on the server. Re-run rsync step 3a.")
}

cat("\n== Verifying community effort CSVs present ==\n")
for (f in c("table_effort_by_grid_year_source_100km.csv",
             "table_effort_by_grid_year_source_10km.csv")) {
  p <- file.path("data", "spatial", "community_effort", f)
  cat(sprintf("  %s : %s\n", f, if (file.exists(p)) "OK" else "MISSING"))
}

cat("\n== Verifying community grid RDS present ==\n")
for (f in c("china_grid_100km_v2.rds", "china_grid_10km_v2.rds")) {
  p <- file.path("data", "spatial", "community_grids", f)
  cat(sprintf("  %s : %s\n", f, if (file.exists(p)) "OK" else "MISSING"))
}

cat("\n== Verifying WorldClim 10m present ==\n")
for (f in c("wc2.1_10m_bio_1.tif", "wc2.1_10m_bio_12.tif",
             "wc2.1_10m_elev.tif")) {
  p <- file.path("data", "spatial", "worldclim_10m", f)
  cat(sprintf("  %s : %s\n", f, if (file.exists(p)) "OK" else "MISSING"))
}

cat("\nIf any of the above are MISSING:\n")
cat("  - re-run deploy/rsync_to_server.sh\n")
cat("  - or download from CHELSA / WorldClim mirrors directly on the server\n")
cat("\nThen execute: bash deploy/run_all.sh\n")

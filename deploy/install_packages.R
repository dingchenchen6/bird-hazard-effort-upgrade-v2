#!/usr/bin/env Rscript
# ============================================================
# Install all CRAN packages required by v2 on a fresh server.
# 服务器端一键安装。Run with: Rscript deploy/install_packages.R
# ============================================================

repo <- "https://cloud.r-project.org"

# Pinned versions from renv.lock; if a pinned version is unavailable we
# fall back to the latest CRAN.
pkgs <- c(
  # data layer
  "data.table", "arrow", "fst", "yaml", "fs", "glue", "here",
  # spatial
  "sf", "terra", "exactextractr",
  # modelling
  "glmmTMB", "DHARMa", "performance", "MuMIn", "broom.mixed",
  "lme4", "ape",
  # ML
  "xgboost", "blockCV", "pROC", "PRROC",
  # plotting
  "ggplot2", "ggtext", "patchwork", "ggridges", "ggspatial",
  "scales", "viridisLite",
  # parallel / pipeline
  "future", "future.apply", "targets", "tarchetypes",
  # reporting
  "rmarkdown", "knitr", "bookdown",
  # io
  "readxl", "peakRAM"
)

already <- rownames(installed.packages())
need <- setdiff(pkgs, already)

cat(sprintf("Total packages required : %d\n", length(pkgs)))
cat(sprintf("Already installed       : %d\n", length(pkgs) - length(need)))
cat(sprintf("To install              : %d\n", length(need)))

if (length(need) > 0L) {
  cat("Installing:\n - ", paste(need, collapse = "\n - "), "\n", sep = "")
  install.packages(need, repos = repo, Ncpus = max(1L,
                                                    parallel::detectCores() - 2L))
}

cat("\n=== Re-check ===\n")
missing <- setdiff(pkgs, rownames(installed.packages()))
if (length(missing) > 0L) {
  cat("STILL MISSING:\n - ", paste(missing, collapse = "\n - "), "\n", sep = "")
  cat("Try: install.packages(c(", paste(sprintf("\"%s\"", missing),
                                          collapse = ", "), "), repos=\"",
      repo, "\")\n", sep = "")
  quit(status = 1L)
}
cat("All packages installed.\n")

# Write a sessionInfo snapshot for the record.
si_path <- file.path("logs", "server_install_sessionInfo.txt")
if (!dir.exists("logs")) dir.create("logs", recursive = TRUE)
con <- file(si_path, "wt")
writeLines(capture.output(sessionInfo()), con)
close(con)
cat("sessionInfo() →", si_path, "\n")

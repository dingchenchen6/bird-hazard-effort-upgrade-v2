# Residual research gaps & risks (post v2)

Updated 2026-05-11. Tracks the issues that v2 *cannot* fully resolve
and must be openly disclosed in the manuscript.

## R1 — Species-shared interaction coefficient (medium)
The hazard model assumes a single climate × effort interaction slope
across all 333 species. Trait-mediated heterogeneity (dispersal
ability, thermal niche breadth) is partially absorbed by the
`(1|species)` intercept but not in the slope. **Disclosure**:
Discussion 4.5; **Mitigation**: random-slope sensitivity in Tab S5.

## R2 — Effort endogeneity (medium)
Birders may preferentially visit cells with recent records or favourable
weather → reverse causality between `effort` and `event`.
**Disclosure**: Discussion 4.5; **Mitigation**: lagged-effort
robustness check (Tab S6, planned). Instrumental-variable approach is
outside v2 scope; flagged as next-paper.

## R3 — Detection-ceiling artefacts (low–medium)
The large OLR ΔAIC (≈1857) reveals unmodelled heterogeneity. v2
re-fits OLR-augmented M4 and shows the interaction β remains within
±0.02 of the headline value. **Disclosure**: Results 3.8 + Tab S2.

## R4 — CHELSA → grid re-projection accuracy (low)
EPSG:4326 → EPSG:4524 re-projection of monthly rasters introduces
≤0.05 °C systematic bias at high latitudes. We aggregate to 50 / 100 km
cells which dilutes the artefact, but we report a CHELSA vs WorldClim
cross-check in Tab S3.

## R5 — CMIP6 ensemble selection bias (medium)
Only 5 GCMs (chosen for ESGF availability and equilibrium climate
sensitivity coverage). Adding more GCMs typically widens the IQR but
rarely moves the median. **Disclosure**: Discussion 4.5; **Mitigation**:
report ensemble disagreement per cell on Fig 5.

## R6 — Sparse southern-Xizang records (low)
Few records from extreme western Xizang → grid models can become
unstable in those cells. **Disclosure**: Fig S13 effort coverage map;
**Mitigation**: cells with <2 effort events flagged on Fig 5.

## R7 — Phylogenetic non-independence (medium)
333 species span 70+ families; the species random intercept does not
capture phylogenetic covariance. v2 adds a genus-level effort heatmap
(Fig S15) for descriptive context. A PGLMM extension is planned for
the next paper.

---

Items previously listed as P0/P1 in v1 are now resolved — see
[GAP_RESOLUTION.md](GAP_RESOLUTION.md).

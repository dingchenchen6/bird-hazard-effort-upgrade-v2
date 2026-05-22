# Cover letter — Global Ecology and Biogeography

`r format(Sys.Date(), "%Y-%m-%d")`

Dear Editor,

We are pleased to submit for your consideration our manuscript
**"Climate-velocity exposure and survey effort interactively drive
new bird distribution records across China: a multi-scale hazard
framework."**

In macroecology, separating real range shifts from increased survey
effort has long been a central challenge. Most studies treat effort
additively — as a scaling factor on top of climate signal — but this
under-represents the way that high effort can amplify the
detectability gain from any given climatic exposure. Using 12,813
species-province-year records of new bird distributions across 32
mainland provinces of China (333 species, 2002–2024), we show that
climate-velocity exposure and survey effort interact in a discrete-
time hazard model: the climate × effort interaction is positive and
significant (HR = 1.18–1.31) across four effort specifications and
three spatial scales, and explains roughly 80 % of conditional R².
Effort is a **moderator**, not a scaling factor.

Five features of the work are relevant to *Global Ecology and
Biogeography*:

1. **First hazard × effort interaction model at biogeographic scale.**
   We integrate detection effort with climate velocity in a single
   cloglog hazard family (M0–M5) and validate the interaction across
   province / 50 km / 100 km / 200 km spatial units.

2. **Multi-scale MAUP-aware design.** Most macroecological multi-scale
   claims silently inherit coarse climate proxies onto fine grids
   (we caught and corrected exactly this in our v1 pre-print). The
   v2 native-grid CHELSA aggregation removes the artefact and shows
   the interaction is genuinely scale-robust (β-elasticity < 10 %
   between adjacent scales).

3. **Spatial-block CV and Moran's I residual diagnostics.** Random
   CV inflated v1 AUC by 0.06 against 250-km spatial-block CV; we
   report both. Residual Moran's I across distance classes (50/100/
   250/500 km) demonstrate adequate spatial decorrelation in M4.

4. **CMIP6 ensemble with explicit forecast-skill decay.** Five GCMs
   × SSP245/SSP585 × 2050/2080, with median + IQR + ensemble
   disagreement maps. We further train XGBoost on 2002–2014, validate
   on 2015–2024 and report AUC vs lead-time + per-feature Population
   Stability Index, allowing the reader to see where projections are
   most and least trustworthy. This is rare in the macroecological
   literature.

5. **Complete reproducibility.** Code, lockfile (`renv.lock`),
   pipeline DAG (`_targets.R`), data dictionary and a self-check
   script (`code/37_reproducibility_selfcheck.R`) that asserts the
   manuscript numbers regenerate to defined tolerances. The full
   pipeline runs end-to-end with `targets::tar_make()` and is
   deposited at Zenodo (DOI to be minted at acceptance).

We believe this combination — interaction-aware ecology + multi-scale
validation + uncertainty communication + reproducibility — fits the
journal's scope and high bar. Conservation implications include a
concrete prioritisation scheme for survey-effort uplift in the
Hengduan Mountains, where projected hazard and ensemble disagreement
both peak.

We suggest the following editor and reviewers:

- **Suggested handling editor:** Damaris Zurell (Univ. Potsdam) or
  Janet Franklin (San Diego State Univ.).
- **Suggested reviewers** (no co-authorship in the past 5 years):
  Tim Newbold (UCL); Brian Maitner (Univ. Maryland); Wenjing Yang
  (PKU, separate research group).

The manuscript has not been submitted elsewhere; the v1 pre-print
exists as an internal report only (acknowledged in §1.2). All
authors approve submission.

We look forward to your response.

Yours sincerely,

Chen-Chen Ding
Institute of Ecology, Peking University
chenchending1992@gmail.com

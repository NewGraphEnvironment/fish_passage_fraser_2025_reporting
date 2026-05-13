# Task: Climate departure body section + appendix — FWCP Fraser (#6)

Add a climate-departure analysis for the FWCP Fraser AOI (union of seven watershed groups: **LCHL, NECR, FRAN, MORK, UFRA, TABR, WILL**), wired into the report in the same three-piece pattern that floodplain uses: a Methods paragraph in `0300-methods.Rmd`, a Results paragraph with a hidden inline-R rollup chunk in `0400-results.Rmd`, and a deep appendix `0835-appendix-climate-departure.Rmd`.

The Peace climate-departure work in `fish_passage_peace_2025_reporting#16` is the prose-structure template, but the **interpretation must be written fresh from Fraser numbers** — no Peace narrative bleed-through, no Peace references in the Rmd prose. The Fraser AOI sits at different latitude, elevation, and snowpack baseline; findings will differ in magnitude, spatial pattern, and possibly direction.

Per-sub-region analytical unit is **ecoregion** (climate-physiography zone), not WSG — same as Peace. The seven WSGs define the AOI scope; ecoregions partition the climate gradient inside it. The final piece of the appendix is a WSG × ecoregion crosswalk that bridges the ecoregion-level signal to the per-WSG prioritisation unit the report uses downstream.

The Fraser repo just merged the NECR floodplain appendix (#5 / PR #7, merge `3ab63ba`) — that's the closest convention precedent and the plan mirrors its file structure, naming, db sourcing pattern, table wrapping, and body-paragraph placement.

## Adaptations from the issue body

The issue was drafted before plan-mode exploration. Four filename/path values adapt — the abstract-naming decision below makes every climate-departure script and data filename identical across regional reports, so the same template applies in Fraser, Peace, Skeena, anywhere. The repo path is the AOI label; the filename is the kind of artefact.

| Issue body | Adapted to | Reason |
|------------|------------|--------|
| Appendix `0880-appendix-climate-departure.Rmd` | `0835-appendix-climate-departure.Rmd` | Next slot after `0830-appendix-floodplain.Rmd` |
| Snapshot at `scripts/cd_inputs_snapshot.R` | `scripts/gis/climate_departure.R` | Mirrors `scripts/gis/floodplain.R` location |
| Anchor `{#app-climate-departure}` | `{-#app-climate-departure}` | Matches `{-#app-floodplain}` (dash suppresses numbering) |
| Data prefix `cd_fraser_*` | `climate_departure*` (no AOI prefix) | Repo path says "Fraser"; AOI-neutral filenames make the script + appendix portable across regional reports |

## Phase 1 — Snapshot script: AOI, context, ecoregions

- [x] Verify `cd` >= 0.3.0 installed (`packageVersion("cd")`)
- [x] Scaffold `scripts/gis/climate_departure.R` header with WSG codes, db connection helper (mirroring `scripts/gis/floodplain.R` lines 1–47)
- [x] Build AOI = dissolved union of the 7 WSG polygons via `fresh::frs_db_conn()` + `whse_basemapping.fwa_watershed_groups_poly` query — 34,019 km² total
- [x] Source ecoregions intersecting the AOI bbox via `bcdata::bcdc_query_geodata("d00389e0-66da-4895-bd56-39a0dd64aa78")` (ecoregions are NOT in fwapg; same pattern Peace uses). 8 ecoregions returned: FAB, FAP, WRA, NCM, SRT, COH, CRM, EHM
- [x] Source context layers (towns, lakes, rivers, streams, highways) cropped to AOI bbox via fwapg. 5 of 8 town candidates found; 56 lakes >1000 ha; 339 named river polygons; 2,098 stream segments (order ≥ 7); 2,390 highway segments
- [x] Write all to `data/gis/climate_departure.gpkg` (multi-layer, 1.4 MB)
- [x] Atomic commit: "Snapshot script — AOI + context + ecoregions for climate departure (#6)"

## Phase 2 — Snapshot script: cd pipeline run

- [ ] Run `cd::cd_catalog()` + `cd::cd_extract()` on AOI to produce regional ts
- [ ] Run `cd::cd_baseline()` + `cd::cd_anomaly()` + `cd::cd_trend()` + `cd::cd_compare()` on AOI → regional outputs
- [ ] Loop per ecoregion (intersect each ecoregion polygon with AOI, then run the full pipeline) — produces a named list keyed by ecoregion code
- [ ] Build spatial tmean departure raster: `cd::cd_crop()` the tmean annual COG to AOI, mean of 2015–2025 layers minus mean of 1951–1980 layers, `terra::mask()` to AOI
- [ ] Compute WSG × ecoregion percentage table (for each of the 7 WSGs, percent area in each ecoregion)
- [ ] Save: `data/gis/climate_departure.rds`, `data/gis/climate_departure_tmean.tif`, `data/gis/climate_departure_wsg_ecoregion.csv`
- [ ] Write snapshot manifest entry (file sha + cd version + run date)
- [ ] Atomic commit: "Snapshot script — cd pipeline outputs for Fraser climate departure (#6)"

## Phase 3 — Appendix draft (0835-appendix-climate-departure.Rmd)

Mirror the Peace appendix structure (`cd/hold/9999-appendix-climate-departure.Rmd`) section-by-section but with all interpretation written fresh from Fraser numbers. **Look at the data before writing each narrative paragraph** — see Fresh-interpretation section in findings.md.

- [ ] YAML header + setup + `cd-load` chunk reading `data/gis/climate_departure.{gpkg,rds,tif,csv}` (all paths under `data/gis/`, no `system.file()`)
- [ ] `# Appendix - Climate Departure {-#app-climate-departure}`
- [ ] "Climate departure and fish passage" — framing paragraph (cold-water salmonid habitat both ways: cold-limited reaches gain growing-degree-days vs near-upper-thermal reaches lose habitat; freshet timing changes design assumptions and migration windows)
- [ ] AOI section + AOI map (`fig:cd-map-aoi`) with ecoregion fill + 7 WSGs outlined + context layers
- [ ] Recent decade vs pre-warming table (15 variables, Δ p windows + Trend p) — wrapped via `fpr::fpr_kable(scroll = gitbook_on)`
- [ ] Trends section: `cd_summary` table + tmean annual anomaly plot + prcp annual anomaly plot
- [ ] Day-night asymmetry: tmax + tmin + DTR plots; narrative reflects what Fraser tmax–tmin slopes actually show
- [ ] Snowpack section: seasonal table + 4 derived snow plots; 3-paragraph "what this means" written from the Fraser numbers
- [ ] Spatial pattern map (`fig:cd-map-tmean`) + gradient narrative (look at the raster — where is warming largest? smallest? what's the dominant gradient direction?)
- [ ] Per-ecoregion variation: tmean / prcp / swe_max / doy_50 facets (one panel per ecoregion in the AOI) + per-ecoregion rollup table
- [ ] WSG × ecoregion rollup: map of the 7 WSGs on ecoregion fill + percentage crosswalk table
- [ ] Interpretation for fish passage: 4 findings written from the Fraser numbers, with the both-ways framing on cold-limited vs near-upper-thermal reaches mapped onto the 7 WSGs via the ecoregion crosswalk
- [ ] Atomic commit: "Climate departure appendix — Fraser (#6)"

## Phase 4 — Body wiring

- [ ] Add `### Climate Departure` subsection under `## Planning — Habitat, Connectivity and Floodplain Modelling` in `0300-methods.Rmd` — one paragraph naming `cd`, ERA5-Land, 1951–1980 reference, Mann-Kendall + Theil-Sen, Welch t, with `[Appendix - Climate Departure](#app-climate-departure)` pointer
- [ ] Add hidden inline-R rollup chunk + prose paragraph for climate departure in `0400-results.Rmd` (alongside the floodplain results paragraph at line 410+) — chunk loads `data/gis/climate_departure.rds`, computes headline numbers for inline-R injection in the prose paragraph
- [ ] Verify cross-reference link from body paragraphs to `#app-climate-departure` resolves in render
- [ ] Atomic commit: "Wire climate departure Methods + Results into body (#6)"

## Phase 5 — Render verification

- [ ] Render gitbook locally — fix any chunk errors, missing labels, or layer-load issues
- [ ] Render PDF locally — confirm all `fpr::fpr_kable(scroll = gitbook_on)` tables fall back cleanly; fix any LaTeX compile errors
- [ ] Spot-check that every inline-R headline number in the Results paragraph matches the corresponding cell in the appendix tables (one decimal precision)
- [ ] Confirm chunk labels in the appendix start with `cd-` and don't collide with floodplain's `flood-*` labels
- [ ] Atomic commit (if any fixes): "Render verification fixes (#6)"

## Phase 6 — Independent review (gating)

- [ ] Spawn a fresh Explore + Plan agent (no inherited context) with a self-contained prompt: review the draft Methods paragraph, Results paragraph + rollup chunk, and appendix Rmd against the cached `data/gis/climate_departure.{rds,tif,csv}` data
- [ ] Reviewer checks: numerical accuracy (recompute spot-check values from the rds), pattern accuracy (does the spatial-pattern narrative match the actual raster?), significance handling (no over-claiming), tone and completeness (plain language, fish-passage relevant, no package-tutorial bleed), stand-alone framing (no Peace references in prose), cross-references and structure
- [ ] Reviewer writes findings to `planning/active/review-climate-departure.md` with line-level callouts: file + line + what's wrong + suggested fix
- [ ] Implementation pass addresses each finding (separate commits for substantive prose/data fixes; trivial wording fixes can batch)
- [ ] Reviewer re-checks the addressed findings and signs off (appends "Sign-off" section to the review file)
- [ ] Atomic commit: "Address review findings (#6)" (or per-finding commits if substantial)

## Phase 7 — PR + merge

- [ ] `/gh-pr-push` to create the PR (PR body summarises the three pieces + lists the reviewer sign-off file path)
- [ ] Watch CI — gitbook + PDF render workflows
- [ ] `/gh-pr-merge`
- [ ] `/planning-archive`

## Validation

- [ ] `Rscript scripts/gis/climate_departure.R` runs end-to-end and produces the four files in `data/gis/` plus the manifest entry
- [ ] Tests / code-check clean on each commit
- [ ] PWF checkboxes match landed work
- [ ] No `system.file()` calls in the new files; no `cd::cd_compare()` calls passing explicit windows; no references to the Peace report in the Rmd prose
- [ ] Reviewer sign-off present in `planning/active/review-climate-departure.md`
- [ ] `/planning-archive` on completion

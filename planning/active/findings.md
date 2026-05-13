# Findings — Climate departure body section + appendix — FWCP Fraser (#6)

## Issue context

Apply the climate-departure template to the FWCP Fraser AOI. Three pieces — Methods paragraph in `0300-methods.Rmd`, Results paragraph (with hidden inline-R rollup chunk) in `0400-results.Rmd`, deep appendix `0835-appendix-climate-departure.Rmd`. The Peace work is the structure template; the Fraser interpretation is written fresh.

Source drafts in the `cd` repo:
- `cd/hold/main-body-climate-departure.Rmd` — Peace body paragraphs (structure to mirror)
- `cd/hold/9999-appendix-climate-departure.Rmd` — Peace appendix (structure to mirror, content fresh)
- `cd/hold/render_preview.Rmd` — preview pattern

## Conventions discovered (Fraser repo)

### Appendix file pattern (mirror NECR floodplain #5 / PR #7)

- Path: `0835-appendix-climate-departure.Rmd` (next slot after `0830-appendix-floodplain.Rmd`)
- YAML: `output: html_document` plus `editor_options: chunk_output_type: console`
- Heading + anchor: `# Appendix - Climate Departure {-#app-climate-departure}` (the leading dash on `{-#…}` suppresses section numbering)
- Setup chunk hidden via `include = FALSE` carries `library()` calls
- Data-load chunk visible (no `include = FALSE`), uses paths under `data/gis/...` — no `system.file()`

### Body Methods placement

`0300-methods.Rmd` lines 66–75 has a `### Floodplain Delineation` subsection under `## Planning — Habitat, Connectivity and Floodplain Modelling`. The climate-departure Methods subsection (`### Climate Departure`) lands as a sibling under the same `## Planning…` heading.

### Body Results placement

`0400-results.Rmd` lines 410–435 has a hidden inline-R rollup chunk (loads gpkg layers, computes headline metrics into variables: `aoi_area_km2`, `fp_area_ha`, `fp_pct_aoi`, etc.) followed by a single paragraph of prose with inline R expressions referencing those variables, closed by the cross-reference link `[Appendix - Floodplain Delineation](#app-floodplain)`. Mirror for climate departure: the chunk loads `data/gis/climate_departure.rds`, computes tmean / vpd / snowpack signal headline numbers, the paragraph quotes them inline and points at `#app-climate-departure`.

### Snapshot script pattern

`scripts/gis/floodplain.R` is the precedent. Same location for climate departure: `scripts/gis/climate_departure.R`. WSG polygons sourced via `fresh::frs_db_conn()` + `whse_basemapping.fwa_watershed_groups_poly` query. Multi-layer geopackage output to `data/gis/`. Manifest entry written to (TBD — confirm during Phase 1 — likely `data/cd_inputs_snapshot_manifest.txt` or equivalent; mirror what floodplain did).

### gitbook-vs-PDF table wrapping

`fpr::fpr_kable(scroll = gitbook_on)` — the `gitbook_on` flag is defined in `index.Rmd` line 74. No bespoke helper needed; every table in the appendix wraps via `fpr::fpr_kable()` with `scroll = gitbook_on` so PDF rendering falls back to no-scroll automatically.

### Bibliography

rbbt-driven via `params$update_bib` in `index.Rmd` line 64. When the parameter is TRUE the build regenerates `references.bib` from `rbbt::bbt_write_bib()`. No manual bib management in this PR — cite keys land in the prose, rbbt does the rest as long as Zotero is running with Better BibTeX enabled.

### Filename abstraction

Repo path identifies the AOI (`fish_passage_fraser_2025_reporting`). Filenames should be AOI-neutral so the same template applies in every regional report:

- `scripts/gis/climate_departure.R`
- `data/gis/climate_departure.gpkg` (multi-layer: aoi, wsgs, ecoregions, towns, lakes, rivers, streams, highways)
- `data/gis/climate_departure.rds` (named list: `regional` + `ecoregion` keyed list)
- `data/gis/climate_departure_tmean.tif`
- `data/gis/climate_departure_wsg_ecoregion.csv`

## Fresh-interpretation discipline

Load-bearing: before writing **any** narrative paragraph, look at the data.

- **Trends table:** every slope, every MK p-value, every Welch p-value, every recent-vs-baseline percent change. Note which signals are significant and which are not, where the significance threshold cuts.
- **Spatial map:** the actual gradient pattern. Where is warming largest? Smallest? East-west? South-north? Elevation-stratified? Don't assume it mirrors Peace.
- **Per-ecoregion facets:** which ecoregions sit at extremes for tmean, prcp, swe_max, doy_50. Which cluster, which diverge.
- **WSG × ecoregion crosswalk:** which of the 7 WSGs sit cleanly in one ecoregion vs straddle multiple. Map the ecoregion climate signal onto each WSG.
- **Snowpack seasonal table:** the summer-SWE / spring-snowmelt redistribution may not be the dominant signal here. Read what is.
- **Day-night asymmetry:** same direction as Peace? Same magnitude? Different?

If a Peace finding doesn't hold in Fraser, drop it. If a finding shows up in Fraser that wasn't visible in Peace, write it in. No Peace references in the Rmd prose.

## Risks and mitigations

1. **Ecoregion source table unknown.** Try PostgreSQL `whse_terrestrial_ecology.erc_ecoregions_sp` first; fall back to `bcdata::bcdc_get_data("ecoregions-ecoregion-boundaries")` (or equivalent slug) if the db query fails. Document the working source in `scripts/gis/climate_departure.R` header.
2. **cd pipeline runtime.** Running `cd_extract` per-ecoregion (4–6 ecoregions likely) means multiple full STAC fetches. Run once during Phase 2, cache to `data/gis/climate_departure.rds`. Same pattern Peace uses.
3. **Reviewer surfaces a load-bearing accuracy issue late.** Phase 6 review is gating — do not merge until findings are addressed. Substantial issues may bounce back into Phase 3 or Phase 2.
4. **PDF table rendering regressions.** Phase 5 renders PDF locally before opening the PR. Every table chunk uses `fpr::fpr_kable(scroll = gitbook_on)`.

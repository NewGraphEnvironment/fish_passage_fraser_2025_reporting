# Progress — Climate departure body section + appendix — FWCP Fraser (#6)

## Session 2026-05-13

- Archived prior PWF for #5 (NECR floodplain, merged via PR #7) into `planning/archive/2026-05-issue-5-necr-floodplain/`
- Plan-mode exploration of Fraser repo conventions — confirmed NECR floodplain (PR #7) as the closest precedent; identified four filename/path adaptations from the issue body (appendix slot `0835-`, snapshot at `scripts/gis/climate_departure.R`, anchor `{-#app-climate-departure}`, AOI-neutral filename prefix `climate_departure*`)
- Plan approved by user
- Created branch `6-climate-departure-appendix` off main
- Scaffolded PWF baseline with approved 7-phase breakdown
- Refined findings.md with Peace REPORT (PR #17, merged 2026-05-12) as the primary tone reference — `cd/hold/` drafts demoted to secondary. Two-paragraph Methods structure (audience intro + technical), 4-finding Results block with bolded leads + closing both-ways framing, direct `kableExtra::kable_styling() |> kableExtra::scroll_box()` for tables (no `gitbook_on` conditional — Peace's PDF build survives the raw pattern)
- Phase 1: wrote `scripts/gis/climate_departure.R` (Phase 1 portion — AOI build, context layers, ecoregions). Ran end-to-end. Produces `data/gis/climate_departure.gpkg` with 8 layers (aoi, wsgs, ecoregions, towns, lakes, rivers, streams, highways), 1.4 MB. AOI = 34,019 km² across 7 WSGs; 8 ecoregions intersect (FAB, FAP, WRA, NCM, SRT, COH, CRM, EHM)
- Phase 2: extended `scripts/gis/climate_departure.R` with the cd pipeline. First run failed at the spatial-tmean step (`mean(SpatRaster)` didn't S4-dispatch — got `mean.default` returning NA, then `terra::mask()` couldn't accept numeric). Fixed by using `terra::app(x, fun = "mean")` explicitly. Also added a checkpoint that saves `climate_departure.rds` before the spatial-tmean step so a re-run doesn't lose the ~10 min of cd extracts. Second run clean.
- Phase 2 produced: `data/gis/climate_departure.rds` (403 KB; regional ts/bl/ano/trn/cmp/cmp_pct + per-ecoregion list keyed by code), `data/gis/climate_departure_tmean.tif` (4 KB, range +1.10 to +2.02 °C across the AOI), `data/gis/climate_departure_wsg_ecoregion.csv` (7 WSG rows), `data/climate_departure_inputs_snapshot_manifest.txt`
- Fraser headline numbers (regional, annual): tmean +1.64 °C (p < 0.001), tmax +1.46, tmin +1.78 (day-night asymmetry present, gap 0.32 °C), VPD +0.34 hPa (p = 0.002), prcp +28 mm ≈ +3 % (p = 0.46, not significant), snowmelt midpoint shifted 11.8 days earlier (p < 0.001). Warming about 0.2 °C less than Peace; freshet-timing signal comparable.
- The "WARNING: Error exit, tauk2. IFAULT = 12" lines (2× on WRA) are Mann-Kendall internals signaling insufficient variance on specific series — non-fatal, just produces NA p-values for affected rows.
- Next: Phase 3 — draft `0835-appendix-climate-departure.Rmd` from the Fraser numbers, mirroring the Peace REPORT's tone + section structure

# Task: Three site maps 404 on the live site; port the generated maps from the template (#23)

## Problem

Three of Fraser's four site appendices ship without a map. `lfpr_map_site()` and its prep script were
built under template#219 **for these exact four Fraser sites**, landed in
`fish_passage_template_reporting`, and never came back to the report they were built for. Same debt as
template#222, running in the template-to-report direction.

**The live symptom is not what the issue body says.** Checked against the rendered HTML rather than
assumed: the three broken chunks are `eval = F`, so no image is ever requested — the 404s recorded in
the issue were requests for files nobody requests. What a reader gets on Stony, Yuzkli and
Trib-to-Fraser is a dead cross-reference followed by the *source code of the disabled chunk*:

```html
<p>... in the Willow River watershed group (Figure <a href="#fig:map-126158"><strong>??</strong></a>).</p>
<pre class="sourceCode r"><code> my_caption <- "Map of Stony"
 knitr::include_graphics("fig/gis/map_stony.jpeg")</code></pre>
```

Tabor is the only one carrying a real `<img>` — a 2.5 MB JPEG hand-exported from a QGIS layout that no
clone can regenerate. Correcting the issue body is part of the work.

## What exploration settled

**No tunnel needed for any phase.** The maps render from committed caches; the #19 UAV burn reads the
STAC index over HTTPS. The database is not involved.

**The four template caches already fit Fraser** — built 2026-08-03, `species = bt`, model run 133, units
`126158`, `196085+203582`, `196332`, `203581+196076`. Copy, do not regenerate.

**Fraser's data layer needs no edit — `0110` and `0120` stay untouched**, the opposite of the Skeena
port. Verified by query: `wshds` (`sf`, 6 rows, every mapped id), `habitat_confirmation_tracks` (`sf`,
11 rows), `pscis_assessment_svw` (`sf`, 1314 rows). CRS `NA` is expected and `lfpr_crs_bc()` assigns
rather than transforms. `wshd_study_areas` is not read by `0420`, so Fraser's sqlite-vs-parquet
divergence from the template does not matter here.

**`xref_tracks_site.csv` already fits.** `lfpr_tracks_site()` hard-errors on any unmapped `name_new`;
Fraser's 11 track labels match its 11 rows exactly, including the three filed under ids that exist in no
PSCIS or form table (`126185_us/ds` → 126158, `205214_us/ds` → 203581, `205215_us` → 203582).

## Phase 0 — Tag hygiene

- [x] Delete the 11 foreign template tags, verifying each is non-ancestor and present on `template` first
- [x] Confirm local tags equal `git ls-remote --tags origin` — 7 tags, `v0.0.2` → `v0.4.0`, `v0.5.0` free

## Phase 1 — Port the machinery (network-free)

- [x] `git checkout template/main -- scripts/02_reporting/0410-map-site-prep.R scripts/02_reporting/0420-map-site.R`
- [x] `git checkout template/main -- data/gis/gq_reg_fish_passage.csv data/gis/xref_map_labels.csv data/gis/xref_tracks_site.csv`
- [x] Confirm `0410`'s `map_units` needs no edit (unlike Skeena, where it did) — it is already
      `126158`, `196085+203582`, `196332`, `203581+196076`
- [x] `scripts/packages.R` — add `tmap`, `terra`, `maptiles`, `png`, `stars` to `pkgs_cran`;
      `newgraphenvironment/gq`, `newgraphenvironment/flooded`, `newgraphenvironment/fresh` to `pkgs_gh`
- [x] `index.Rmd` `{r source}` — add `source("scripts/02_reporting/0420-map-site.R")` after `0130-tables.R`.
      **The step Skeena skipped**; without it the map chunks error on `lfpr_map_site` not found
- [x] **Verify:** a fresh `Rscript` sources `0420` and all eight `lfpr_*` entry points resolve; the
      three sidecar CSVs parse at 10 / 3 / 11 rows

## Phase 2 — Bring the caches

- [x] `git checkout template/main -- data/gis/map_126158* data/gis/map_196076* data/gis/map_196085* data/gis/map_196332*`
      — 16 files, 22 MB (`map_196085.gpkg` alone is 12.4 MB, the 145.6 km² Tabor watershed)
- [x] **Verify:** all four `_meta.rds` read `species = bt`, `model_run_id = 133`, built 2026-08-03, units
      matching the appendices; all four `.gpkg` open with the expected layers, `railway` present on
      196076 and 196085 only; DEMs and basemaps in EPSG:3005, 3-band
- [x] Record the weight cost on #1 rather than letting it be discovered later — commented with the
      per-unit breakdown and where to look first if `data/` gets a diet

## Phase 3 — Wire the four appendices

- [ ] Replace the `knitr::include_graphics()` chunk in each `0840-appendix-*.Rmd` with the template pair,
      options `fig.cap = my_caption, fig.width = 9, fig.height = 7, dpi = 150, out.width = photo_width`,
      no `eval`. `fig.width`/`fig.height` drive the bbox aspect; `dpi = 150` overrides the global `60`.
      Paired sites pass a vector — `c(196085, 203582)` and `c(203581, 196076)`
- [ ] Keep every existing chunk label so the prose cross-references resolve untouched
- [ ] `git rm fig/gis/map_tabor.jpeg`
- [ ] **Verify:** no `>??<` in the rendered appendix pages; `fig/gis` appears nowhere in `docs/`

## Phase 4 — Build and cartographic self-review

- [ ] `scripts/run_gitbook.R`
- [ ] Read all four PNGs against the 7-point cartography checklist. **Tabor hardest** — 145.6 km² across
      a paired crossing, the widest extent of the four
- [ ] `scripts/run_pagedown.R` (`render_book(envir = globalenv())`)

## Phase 5 — #19, the UAV appendix publishing Peace imagery

Folded in at the user's request. Needs no tunnel.

Confirmed against the STAC index: the bucket **does** hold Fraser imagery, so the table is repopulated
rather than dropped — `fraser/morkill/2024` (3 assets) and `fraser/nechacko/2024` (12), five sites
(`199256_kenneth_hwy16`, `199171_burnt_cabin_gala`, `199173_necr_trib_dog`,
`199174_necr_trib_dog_settlement`, `chilako_mud1`). The bucket spells it `nechacko`. All 2024 — the 2025
season is not represented, which is consistent with how Skeena's table reads but worth stating.

- [ ] Drive the region from `params$project_region`, as in Skeena — verified that Fraser's two
      vocabularies agree (`fraser`)
- [ ] Run `api1` + `uav-clean-burn` over the **full BC bbox the chunk uses**, not the reduced one used
      for scoping — LCHL and LSAL sit outside that box and would be silently dropped
- [ ] Guard the rendering chunk so an absent or empty `project_uav` degrades visibly rather than
      inheriting whatever the ancestor committed
- [ ] **Verify:** `SELECT DISTINCT region FROM project_uav` returns `fraser` only; `docs/app-uav.html`
      names no Peace watershed group
- [ ] File the vocabulary fix against the template (below)

**The vocabulary trap.** The bucket's `region` segment is a basin name and is not reliably the same
vocabulary as `params$project_region`:

| Repo | `params$project_region` | bucket `region` |
|---|---|---|
| Skeena | `skeena` | `skeena` — agrees |
| Fraser | `fraser` | `fraser` — agrees |
| Peace | `peace` | **`mackenzie`** — does not |

Peace's appendix also hardcodes `project_region <- "skeena"` yet its committed table holds `mackenzie`
rows, so that chunk has never once produced the table sitting beside it. The region belongs in an
explicitly-named param in the bucket's own vocabulary.

## Phase 6 — Correct the issue, release, deploy

- [ ] Rewrite issue #23's Problem section — dead cross-reference plus echoed dead code, not a broken
      image. The 404 evidence in it is misleading
- [ ] NEWS entry + `v0.5.0` in `index.Rmd` and `DESCRIPTION`
- [ ] PR → merge → tag `v0.5.0` → watch Pages
- [ ] **Verify live:** the three appendix pages render a map; `map_tabor.jpeg` is gone from the site

## Out of scope

- **#13** floodplain overlay on the site maps — explicitly queued behind this
- **skeena#9** — Skeena has `0410`/`0420` and the sidecars (commit `b88ea24`) but is missing the
  `index.Rmd` source line, the caches and the map chunks. This branch establishes the recipe; Skeena's
  remaining half genuinely needs the tunnel
- The UAV-footprint and hydrometric-station `lfpr_*` layers (skeena#9)
- The dead `eval = F` `setup-<id>` chunks in each appendix, which source a `scripts/tables.R` that does
  not exist — noted, not touched

## Validation

The honest check is the rendered output, not the source:

- [ ] `grep -c '>??<' docs/*.html` → 0 across the four appendix pages
- [ ] `grep -r 'fig/gis' docs/` → no hits
- [ ] Four `<img src="fig/background/map-*-1.png">`, one per appendix page
- [ ] Both formats build clean from a fresh `Rscript`
- [ ] Cartographic read of each PNG before anyone else sees it
- [ ] `/code-check` clean on each commit
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion

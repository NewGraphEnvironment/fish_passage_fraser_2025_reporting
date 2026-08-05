# Progress — Three site maps 404 on the live site (#23)

## Session 2026-08-05

- Plan-mode exploration across three repos — template (map machinery inventory), Fraser (current state),
  Skeena (how far its port got). Phases approved by user.
- Corrected the issue's diagnosis against rendered HTML: dead cross-reference plus echoed dead code, not
  a broken image. The 404 evidence in the issue body is meaningless — those files are never requested.
- Verified the port needs **no database tunnel**: caches are copied, and the #19 UAV burn reads the STAC
  index over HTTPS.
- Confirmed Fraser's `wshds` / `habitat_confirmation_tracks` / `pscis_assessment_svw` already satisfy
  `0420-map-site.R`, so `0110` and `0120` stay untouched — the opposite of the Skeena port.
- **#19 folded into scope** at the user's request. STAC query confirms `fraser` imagery exists
  (morkill + nechacko, 2024), so `project_uav` is repopulated rather than dropped.
- Created branch `23-site-maps-port-from-template` off `main` at `265484c`.
- **Phase 0 complete.** Deleted 11 foreign template tags that a `git fetch template` had pulled in
  during exploration; `v0.5.0`, this repo's next release name, had been squatted. Local tags now equal
  origin's 7.
- Restored `data/bcfishpass.sqlite` after read-only inspection dirtied it via readwritesqlite log churn.
- **Phase 1 complete.** `0410`/`0420` and the three sidecar CSVs ported verbatim from `template/main`;
  `0410`'s `map_units` needed no edit, unlike the Skeena port. Mapping packages added to
  `scripts/packages.R`, and `0420` wired into `index.Rmd` after `0130-tables.R`. Verified from a clean
  `Rscript`: all eight `lfpr_*` entry points resolve and the sidecars parse at 10 / 3 / 11 rows.
- **Phase 2 complete.** Four map caches ported, 16 files / 22 MB. All verified `species = bt`,
  `model_run_id = 133`, built 2026-08-03, units matching the appendices; layers as expected with
  `railway` on 196076 and 196085 only; DEMs and basemaps EPSG:3005. Weight cost recorded on #1 with a
  per-unit breakdown — `map_196085.gpkg` is 12.4 MB of the 22, the 145.6 km² Tabor watershed.
- **Phase 3 complete.** All four `include_graphics()` chunks replaced with the `lfpr_map_credit` +
  `lfpr_map_site` pair; chunk labels kept so the prose cross-references resolve untouched. Tabor JPEG
  deleted. Smoke-tested all four standalone before touching the book — every one renders from the
  caches, including the two paired units.
- Two differences from the template's reference PNG remain open — no keymap inset, no eDNA diamond.
  Suspected device-size artefact of the smoke harness (`fig.retina = 2` means the real build draws at
  2700×2100, twice the harness). Settle it on the real build in Phase 4.
- **Phases 4 and 5 complete.** Gitbook and PDF both build 393/393. All four maps render. Checked against
  the template's reference renders — 126158 byte-identical, the other three differing only where this
  repo's own data does. The keymap and eDNA diamond the smoke test seemed to lack are present; the
  harness was drawing at half the device size.
- One real cartographic defect, inherited: South Yuzkli's cached basemap leaves a ragged edge and 0.14 %
  bare white, measured identical in the template. Filed template#226. Not blocking — it replaces a dead
  cross-reference.
- `project_uav` re-burned: 18 Peace rows out, 15 Fraser rows in. Region now driven from
  `params$project_region`, and the render chunk guarded against an empty table. Vocabulary fix filed as
  template#225, since Peace's `project_region` is `peace` while its imagery is under `mackenzie`.
- Issue #23 retitled and its Problem section rewritten; the correction recorded as a comment rather than
  silently overwritten.
- **Weight is roughly double what the plan estimated.** 22 MB of caches plus ~28 MB of rendered PNGs,
  which land twice because `output_dir: "docs"` makes the rendered book a tracked artifact. ~45 MB net
  after the Tabor JPEG comes out. Recorded on #1.
- Next: Phase 6 — v0.5.0, PR, merge, tag, verify live.

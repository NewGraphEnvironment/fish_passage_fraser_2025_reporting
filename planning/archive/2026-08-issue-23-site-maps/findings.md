# Findings — Three site maps 404 on the live site (#23)

## The issue body is wrong about the symptom

Checked the rendered HTML rather than trusting the issue. The three broken chunks are `eval = F`, so
**no image is ever requested**. The 404s recorded in the issue were requests for files nobody requests —
evidence of nothing.

What a reader actually gets, from `docs/tributary-to-stony-lake---126158---appendix.html:435-439`:

```html
<p>PSCIS crossing 126158 is located on Tributary To Stony Lake ... in the Willow River watershed group
   (Figure <a href="#fig:map-126158"><strong>??</strong></a>).</p>
<p><br></p>
<div class="sourceCode"><pre class="sourceCode r"><code> my_caption <- "Map of Stony"
 knitr::include_graphics("fig/gis/map_stony.jpeg")</code></pre></div>
```

A dead cross-reference, then the source of the disabled chunk echoed into the page (gitbook has
`echo = TRUE`), with no figure. One `>??<` on each of the three pages; Tabor is the only page with a
real `<img>`.

## Cache compatibility — verified, not assumed

| Cache | species | model_run_id | built | unit |
|---|---|---|---|---|
| `map_126158` | bt | 133 | 2026-08-03 | 126158 |
| `map_196076` | bt | 133 | 2026-08-03 | 203581+196076 |
| `map_196085` | bt | 133 | 2026-08-03 | 196085+203582 |
| `map_196332` | bt | 133 | 2026-08-03 | 196332 |

Fraser's `model_species` is `bt`. The four cached units are Fraser's four appendices. The template's
`0410` `map_units` list is already Fraser's — unlike the Skeena port, where it was the one edit needed.

## Fraser's data layer already satisfies `0420` — no `0110`/`0120` change

| Global | Class | CRS | Rows |
|---|---|---|---|
| `wshds` | `sf` | `NA` | 6 — 126158, 196076, 196085, 196332, 203581, 203582 |
| `habitat_confirmation_tracks` | `sf` | `NA` | 11 |
| `pscis_assessment_svw` | `sf` | `NA` | 1314 |

CRS `NA` is expected — `0420`'s header documents it and `lfpr_crs_bc()` assigns rather than transforms.
`wshd_study_areas` is not read by `0420`, so Fraser reading it from sqlite where the template reads a
parquet is irrelevant here.

`xref_tracks_site.csv` is the load-bearing sidecar: `lfpr_tracks_site()` hard-errors on any `name_new`
missing from it. Fraser's 11 track labels match its 11 rows exactly, including the three filed under ids
present in no PSCIS or form table — `126185_us/ds` → 126158, `205214_us/ds` → 203581, `205215_us` →
203582, digit transpositions reconciled by hand under template#219.

## Stray peer-repo tags — reproduced live

A `git fetch template` during exploration pulled 11 template tags into this repo: `v0.0.3` and `v0.5.0`
… `v0.14.0`. None reachable from HEAD, all present on the `template` remote. **`v0.5.0` — this repo's
next release name — was squatted**, and tagging would have failed with `already exists` while
DESCRIPTION, NEWS and `git describe` all looked correct, because a stray is invisible to `git describe`.

Recurs on every fetch. Not a one-time cleanup.

## UAV region is a different vocabulary from `params$project_region`

The bucket's first path segment is a basin name:

| Repo | `params$project_region` | bucket `region` |
|---|---|---|
| Skeena | `skeena` | `skeena` — agrees |
| Fraser | `fraser` | `fraser` — agrees |
| Peace | `peace` | **`mackenzie`** — does not |

Peace's `0740-appendix-uav-imagery.Rmd:70` hardcodes `project_region <- "skeena"` while its committed
`project_uav` holds `mackenzie` rows — that chunk has never produced the table sitting beside it. The
Skeena fix used `params$project_region`, correct there and for Fraser but silently empty for Peace.

STAC index holdings for `fraser` (queried 2026-08-05, bbox -125.0/52.0 to -119.5/55.5):

```
fraser/morkill/2024/199256_kenneth_hwy16
fraser/nechacko/2024/199171_burnt_cabin_gala
fraser/nechacko/2024/199173_necr_trib_dog
fraser/nechacko/2024/199174_necr_trib_dog_settlement
fraser/nechacko/2024/chilako_mud1
```

15 assets, all 2024 — the 2025 season is not represented. The bucket spells it `nechacko`. That bbox
excludes LCHL and LSAL, so the burn must use the full BC bbox the chunk already uses.

The S3 bucket denies anonymous listing (403); the STAC API at `images.a11s.one` is the only index, and a
full-province `items_fetch()` takes over five minutes.

## The port reproduces the template's renders

The four maps built here were checked against the template's committed reference PNGs rather than just
eyeballed. `map-126158-1.png` is **byte-identical**; the other three differ only where Fraser's own
`pscis_assessment_svw` and `form_edna` rows differ from the template's. Geometry is identical to two
decimal places on every measure taken.

That comparison also settled the two things the smoke test appeared to be missing — the keymap inset and
the eDNA diamond are both present in the real build. The harness drew at 1350×1050 where knitr's
`fig.retina = 2` gives 2700×2100, and inset grobs are sized against the device.

## One real cartographic defect, inherited

South Yuzkli (196332) renders a ragged staircase edge along the right and bottom of the frame where the
cached basemap runs out — bare white inside the map panel. Not introduced here: measured at **0.14 % of
the map panel in both this repo's render and the template's**, identical.

`0410-map-site-prep.R` pads the tile request by a fixed 10 % because Web Mercator → BC Albers rotates the
quad (template commit `8d81b44`), and that pad is not enough at the smallest extent. The fix belongs in
the prep script and needs a database and network re-run, so it is filed upstream rather than patched
here — template#226.

Note the earlier read of the 203581 map as having "white bands" was wrong: those are ~40 px top and
bottom of 2100, uniform, and present identically in the template. That is the inner margin, not a
letterbox.

## `pgrep -f 'Rscript ...'` never matches a running Rscript

`Rscript foo.R` execs the R binary, so the process command line is:

```
/Library/Frameworks/R.framework/Resources/bin/exec/R --no-echo --no-restore --file=scripts/run_pagedown.R
```

The string `Rscript` appears nowhere in it. A `while pgrep -f 'Rscript scripts/run_pagedown'; do sleep;
done` wait loop therefore exits immediately, and every check after it reads the *previous* build's
artifacts while the real build is still running. That produced a confident but wrong "PDF 16.1 MB,
builds clean" here, plus a phantom "Version 0.13.0" read from a file mid-rewrite.

Wait on `pgrep -f 'file=scripts/run_pagedown.R'`. Better still, verify the artifact rather than the
process — compare the file's mtime before and after, and read the version out of the PDF itself with
`pdftotext -f 1 -l 1`.

Note `stat -f %m` is BSD syntax and fails on this machine, where `-f` means filesystem info. Use
`stat -c %Y` or just `ls -la`.

## Incidental

`rws_connect()` on `data/bcfishpass.sqlite` dirties the file even for read-only inspection —
`readwritesqlite_log` churn, same byte count, binary diff. Restore with `git checkout --` before
committing, or it rides along in an unrelated commit.

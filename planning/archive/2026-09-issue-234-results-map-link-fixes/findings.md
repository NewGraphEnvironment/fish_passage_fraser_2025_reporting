# Findings — sync the results-map link fixes to Fraser (template#234)

## Measured starting state

`scripts/links_check.R` (run from the template, against Fraser's committed `docs/`) reports **49 broken links**:

| Cause | Count |
|---|---|
| `sum/cv/<id>.html` — pages never generated | 16 |
| `sum/bcfp/<id>.html` — pages never generated | 16 |
| Photo links built from `my_crossing_reference` | 12 |
| Malformed UAV viewer URLs (`http:/23cog...`) | 3 |
| `attach-maps.html`, reachable only from orphan pages | 1 |

18 distinct photo URLs are emitted; `data/photos/` holds 17 real folders; only 6 links resolve. The 12 dead ones all point at modelled-crossing ids — `19703257`, `24403467`, `5400047` and so on.

## Four things that make this not a straight copy

### `attach-bayes.html` is a live chapter here

Peace's fix deleted four orphan pages, `attach-bayes.html` among them. **In Fraser it is real** — source `2500-Attachment_water_temp_modelling.Rmd`, anchor `{-#attach-bayes}`, rebuilt with every other page. Applying Peace's delete list unchanged would remove a published chapter.

Only two pages here are genuine orphans: `docs/ai-disclosure.html` and `docs/changelog.html`, both dated May 19 against a fresh build, neither with a source Rmd. They link to each other and to `attach-maps.html`, whose source sits parked in `hold/2200-Attachment_maps.Rmd` and is never rendered — which is why the link is dead while the page is simply absent.

### The malformed UAV URLs are a snapshot regression, not Fraser's bug

`http:/23cog.s3.amazonaws.com/...` — single slash after the scheme — appears in no `.R` or `.Rmd` in the repo. It is frozen inside `data/snapshots/fp_sites_tracking.parquet`, as pre-built anchor HTML in the `link_uav1` column, and surfaces through `0730-appendix-site-assessment-data.Rmd` which dumps the frame with `escape = FALSE`.

The parquet is copied verbatim from the template by `scripts/fp_inputs_snapshot.R`, and **the template's copy carries the identical string**. The generator (`scripts/db-load.Rmd:496`) uses `ngr::ngr_str_link_url()` correctly — it faithfully wrapped a bad `url_uav_ortho` value from `data/inputs_raw/uav_tracking.csv`, which exists in none of the four repos.

There is a template commit `b7ffeee update the uav urls to correct the single slash issue!`. **This was fixed once and regressed through the snapshot.** Out of scope here; filed separately in Phase 5.

### Promoting Skeena's eDNA script would regress Fraser

Skeena's `edna_map.R` is the region-generic version to promote (region from `params$gis_project_name`), and the diff against Fraser's `edna_map_fraser.R` is *only* genericization — seven substitutions, no logic differences.

But it reads `params$` at top level with no `exists()` guard, so `Rscript scripts/edna_map.R` fails on line 29. Fraser's current script has **zero** `params$` reads and runs standalone today. Promotion has to add the front-matter read that `0210` and `fds_prep_for_submission.R` already use.

The output name also changes from `edna_unbc_results_2025_fraser_map.html` to `..._map.html`, and two files link the old name: `0400-results.Rmd:596` and `0837-appendix-edna.Rmd:153`. Left with the Skeena pass (#230).

### `scripts/packages.R` must not be overwritten

Fraser's has diverged deliberately: it declares `leafpop`, `english` and `bcmaps` (from #30, which fixed headless builds) and reads `params$update_packages` more defensively than the template's `exists("params") && isTRUE(...)`. Copying the template's version would undo that fix.

## Confirmed insert points

| File | Where |
|---|---|
| `index.Rmd:51` | `update_html_map_tables: FALSE` after `update_bcfishpass` |
| `index.Rmd:114` | `source(...0190...)` after `0130-tables.R` |
| `scripts/run_gitbook.R:62` | check hook between `render_site()` and the auto-open block |
| `scripts/02_reporting/0130-tables.R:934-937` | the `case_when` `photo_link` to replace |

`docs/sum/` does not exist and is not gitignored — nothing in `.gitignore` touches `docs/`.

Fraser's `index.Rmd:18` hardcodes `Version 0.6.3 DRAFT`, where template and Peace read `desc::desc_get_version()`. Worth converting while releasing so it cannot drift again.

## Reference — the proven commits

- Peace: `f15a8ca` (check) → `c5361a4` (fixes, 51 → 0) → `5103429` (wire in, release 0.16.0), merged `1484a71` PR #45
- Template: `a88ff3c`, merged `79ee683` PR #233, closing #61 / #231 / #232

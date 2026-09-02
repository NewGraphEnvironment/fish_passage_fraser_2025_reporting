# template#234 — sync the results-map link fixes to Fraser

**Complete.** PR #36, merged `397f276`, released **v0.7.0**. Verified live on the published site.

**49 broken links to 3.** The three that remain are the malformed UAV viewer URLs, which are not this repo's to fix — they are frozen in `data/snapshots/fp_sites_tracking.parquet`, copied from the template whose parquet carries the identical string. Tracked as template#235.

| Cause | Before | After |
|---|---|---|
| `sum/cv/` + `sum/bcfp/` pages never generated | 32 | 0 |
| Photo links built from `my_crossing_reference` | 12 of 18 | 0 |
| Reference reachable only from orphan pages | 1 | 0 |
| Malformed UAV viewer URLs | 3 | 3 — template#235 |

## The two judgement calls worth remembering

**`attach-bayes.html` was left in place.** Peace's equivalent fix deleted four orphan pages, that one among them. Here it is a live chapter — `2500-Attachment_water_temp_modelling.Rmd`, referenced from three others. Copying Peace's delete list unchanged would have removed published content. Verified live at HTTP 200 after release, alongside the orphan correctly returning 404.

**`scripts/packages.R` was not touched.** Fraser's has diverged deliberately, carrying the `leafpop` / `english` / `bcmaps` declarations from #30 and a more defensive `params` read than the template's. Overwriting it would have undone that fix.

Both are recorded on template#234 so the Skeena pass starts with them.

## Also landed

`index.Rmd` now reads the version via `desc::desc_get_version()` instead of repeating it, matching template and Peace, so the title block cannot drift from the released version.

## Build note

`rbbt` could not refresh the bibliography — this shell is headless and `launchctl managername` returns `Background`, so no GUI app can start. The failure surfaces as `TypeError: can't access dead object`. Built with `update_bib: FALSE` against the committed `references.bib` and restored the param to `TRUE` before committing; no citations changed. Whether a bib refresh works depends on whether Zotero happens to be running, not on the repo.

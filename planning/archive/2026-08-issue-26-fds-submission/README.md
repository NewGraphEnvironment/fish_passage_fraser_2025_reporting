# Issue #26 — Submit the 2025 habitat confirmation data to the Province (FDS)

**Status: built and released, not yet submitted.** Archived to free `planning/active/`, not because the work is finished. Issue #26 stays **open** until the submission actually happens.

Peace 2025 sits at exactly the same point — see `fish_passage_peace_2025_reporting` `planning/archive/2026-08-issue-23-fds-submission/`. Both workbooks exist; neither is recorded as sent.

## What landed

`data/permit_submission/PG25-983997.xlsx`, built programmatically by
`scripts/03_permit_submission/fds_prep_for_submission.R` and released in **v0.6.0**. 11 sites, locations and habitat only — **no fish were sampled**, so Steps 2 and 3 are empty. DFO licence `XR 463 2025` in the header block.

This was the first exercise of the no-fish path, and the first time the DFO header field was ever populated (Peace passed `NA`).

## What is still outstanding

- [ ] Run the provincial QA tool (Windows, Excel ≤ 2010) — optional but recommended
- [ ] **Submit `PG25-983997`** via the WLRS SPO FDS SharePoint site
- [ ] Capture the confirmation in `data/permit_submission/`
- [ ] **Close out `WL25-993485`** (Williams Lake / Cariboo) in the provincial portal as a nil return — no data was collected under it

## Why it is worth reading

The findings file records what the work turned up, some of it counter-intuitive:

- **The port source was Peace, not the template.** The issue said to port from template v0.15.0, which was a generation behind — no `has_fish`, no `dir_workbook`, no header block, no workbook writer. Three of the issue's own test-plan items could not be met from it.
- **Fraser has zero `_ef` sites**, so the unconditional `stopifnot(sum(is_ef(...)) > 0)` aborted the run. The pooled backup `data/backup/2025/form_fiss_site_2025.csv` misleads here — its 8 `_ef` sites belong to Peace. Fraser-only is 11 sites, none electrofishing.
- **`00000NA`** — a missing watershed group code had been pasted into that literal string, reading as a real waterbody id rather than a gap. 3 of 11 rows here; Peace submitted it on all six of its Step 4 rows.
- **Do not re-run `0205_fiss_wrangle.R`** — `delete_dsn = TRUE` against geopackages whose `source` column pools all three regions.
- The gradient `AVERAGE(...)/100` **is correct** against the cell's `0.0%` number format. Committed as a fix once and retracted; do not re-fix.

## Follow-on

Generalised into the template at v0.16.0 (#228): a season is now configured from `index.Rmd` via `permit_id` and `permit_id_dfo`, so `fds_prep_for_submission.R` is identical across the fish passage repos.

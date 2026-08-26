# Task: Sync the results-map link fixes to Fraser 2025

`fish_passage_template_reporting#234` — work happens in
`~/Projects/repo/fish_passage_fraser_2025_reporting`. Skeena follows in its own pass.

## Context

The link fixes and the build-time link check landed in Peace 2025 (v0.16.0) and the
template (v0.17.0, closing #61/#231/#232). Fraser is still unfixed and published, with
**49 broken links** measured against its current `docs/`. The fix set is proven — this is
a transplant from the template, not a redesign.

Exploration turned up four things that make it not a straight copy.

**Fraser's `planning/active/` is occupied.** It holds the #26 FDS PWF, committed and never
archived — the same state Peace was in. Archive first, recording that the provincial
submission is still outstanding.

**`attach-bayes.html` is LIVE in Fraser.** Peace's fix deleted four orphan pages including
that one. In Fraser it is a real chapter (`2500-Attachment_water_temp_modelling.Rmd`,
anchor `{-#attach-bayes}`) and must **not** be deleted. Only `ai-disclosure.html` and
`changelog.html` are orphans here (both May 19, no source Rmd). Copying Peace's delete list
blindly would remove a published chapter.

**The 3 malformed UAV URLs are not Fraser's to fix.** `http:/23cog...` — single slash after
the scheme — is baked into `data/snapshots/fp_sites_tracking.parquet`, in a pre-built
anchor in the `link_uav1` column. No Fraser code generates it; the parquet is copied from
the template, whose copy carries the identical defect. There is even a template commit
`b7ffeee update the uav urls to correct the single slash issue!` — so this is a
**regression via the snapshot**, and the real source is an `url_uav_ortho` column in a CSV
that exists in none of the four repos. Out of scope: file separately.

**Promoting Skeena's eDNA script would regress Fraser.** Skeena's `edna_map.R` is the
region-generic one to promote, but it reads `params$` at top level with no guard, so
`Rscript scripts/edna_map.R` fails. Fraser's current `edna_map_fraser.R` has zero `params$`
reads and runs standalone today. The promotion has to add the front-matter read that
`0210` and `fds_prep_for_submission.R` already use, and the output filename changes, which
two Rmds reference.

## Phase 1: Clear the decks

- [x] Archive the #26 FDS PWF to `planning/archive/`, README recording that the workbook is
      built and released but the provincial submission and confirmation are outstanding —
      same treatment Peace's #23 got. Leave issue #26 open.
- [x] Branch off main

## Phase 2: Port the fix set from the template

Files, with insert points confirmed by exploration:

- [x] `scripts/links_check.R` — copy from template (new file)
- [x] `scripts/02_reporting/0190-build-html-map-tables.R` — replace the 31-line pre-fix
      version with the template's 86-line one
- [x] `scripts/02_reporting/0130-tables.R:934-937` — replace the `case_when` `photo_link`
      with the template's `pscis_crossing_id` form
- [x] `index.Rmd` — add `update_html_map_tables: FALSE` after `update_bcfishpass` (line 51);
      add `source('scripts/02_reporting/0190-build-html-map-tables.R')` after line 114
- [x] `scripts/run_gitbook.R` — insert the 12-line check hook between the `render_site` call
      (line 62) and the auto-open block

Do **not** touch `scripts/packages.R`. Fraser's has diverged deliberately — it carries
`leafpop`, `english`, `bcmaps` from #30 and a more defensive `params` read than the
template's. Overwriting it would undo a fix.

## Phase 3: Generate, verify, prune

- [x] Flip `update_html_map_tables: TRUE`, build, confirm `docs/sum/` populates (32 pages
      expected — 16 `cv`, 16 `bcfp`), flip back to FALSE
- [x] Commit `docs/sum/`
- [x] Delete **only** `docs/ai-disclosure.html` and `docs/changelog.html`. Leave
      `attach-bayes.html` alone — it is a live chapter here
- [x] Run the check: expect 49 → 3, the remainder being the UAV parquet URLs
- [x] Confirm the 12 dead photo links now resolve against the 17 real `data/photos/` folders

## Phase 4: Release Fraser

- [x] Bump 0.6.3 → 0.7.0 with NEWS
- [x] Replace the hardcoded `| Version 0.6.3 DRAFT` in `index.Rmd:18` with
      `` `r desc::desc_get_version()` ``, as template and Peace do, so it cannot drift again
- [x] Rebuild gitbook, print PDF, executive summary PDF
- [ ] PR, merge, tag, verify published links resolve live

## Phase 5: File the UAV regression separately

- [ ] Issue: the malformed `http:/23cog...` URLs are frozen in
      `data/snapshots/fp_sites_tracking.parquet` in both Fraser and the template, were
      fixed once in `b7ffeee` and regressed via the snapshot, and the upstream
      `url_uav_ortho` source is not in any of the four repos

## Out of scope

The eDNA consolidation (#230) stays with the Skeena pass, where the canonical script lives
and can be verified. Doing it in Fraser first would mean promoting a script that currently
cannot run standalone, and renaming an output that `0400-results.Rmd:596` and
`0837-appendix-edna.Rmd:153` both link to.

## Verification

- [x] `Rscript scripts/links_check.R` reports 3 (the UAV parquet URLs), down from 49
- [ ] Photo and `sum/` hrefs resolve from a fresh clone, checked live after release
- [x] `attach-bayes.html` still present and reachable
- [ ] `/code-check` clean on each commit
- [ ] `/planning-archive` on completion

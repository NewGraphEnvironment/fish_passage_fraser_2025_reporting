# Task: Submit the 2025 habitat confirmation data to the Province (FDS) (#26)

The 2025 habitat confirmation data has not been submitted to the Province. This repo
carries none of the FDS workflow — only the retired, still-Skeena-2023
`fds_prep_for_submission_2023.Rmd`, and `0210`/`0220` in their pre-fix state (they
reference `data/habitat_confirmations.xls`, which the 2025 pipeline no longer produces).

Two permits were issued. `PG25-983997` (Prince George / Omineca) is the one the data goes
under; `WL25-993485` (Williams Lake / Cariboo) needs closing out as a nil return. A DFO
licence, `XR 463 2025`, also applies.

**No fish were sampled.** The submission is locations and habitat only — Steps 2 and 3
stay empty. Submitting anyway records where we were and what was assessed: the same class
of evidence `fish_passage_template_reporting#199` argues is worth harvesting from other
parties.

## Phase 1: Sync and branch

- [x] `git pull --ff-only` in `fish_passage_peace_2025_reporting` (41 behind, clean FF)
- [x] Branch `26-submit-2025-habitat-confirmation-data-fds` off Fraser `main`
- [x] Commit PWF baseline

## Phase 2: Port the FDS workflow from Peace

Copy from `fish_passage_peace_2025_reporting` at the freshly-pulled `main`:

- [ ] `data/templates/FDS_Template2026-03-11.xlsx` (3.7 MB) — nothing runs without it
- [ ] `scripts/03_permit_submission/fds_prep_for_submission.R`; delete
      `fds_prep_for_submission_2023.Rmd` (its per-season values stay in git history —
      the year in that filename is what let it be copied forward and go stale)
- [ ] `scripts/01_prep_inputs/0210_fiss_export_to_template.Rmd` (fixed version)
- [ ] `scripts/01_prep_inputs/0220_fish_data_tidy.R` (fixed version — port for parity and
      to stop the drift, even though it is not run this season)
- [ ] Fix `scripts/01_prep_inputs/README.md` if it still names `habitat_confirmations.xls`

**Do not run, and do not port a run of, `0205_fiss_wrangle.R`.** It writes back to the
field-form gpkgs with `sf::st_write(delete_dsn = TRUE)`, and its `source` column pools all
three regions — running it from this repo destructively rewrites three Mergin projects.
Issue #26 step 3 says to run `0205 → 0210 → 0220`; that is wrong. Peace deliberately did
not re-run it, which is why the watershed refresh lives in the submission script instead.

## Phase 3: Wire Fraser's parameters

- [ ] Add to `index.Rmd` params, with the comment Peace carries: `permit_id: "PG25-983997"`
- [ ] Set `hdr_permit_dfo <- "XR 463 2025"` in `fds_prep_for_submission.R` (Peace has
      `NA_character_` with a comment naming Skeena's `XR 470 2025`)
- [ ] Confirm `hdr_title` picks up `"Restoring Fish Passage in the Fraser Region - 2025"`
      from the front matter

## Phase 4: Make the no-fish / no-ef season run

- [ ] Relax `stopifnot(sum(is_ef(step_4$local_name)) > 0)` — a season with no small
      electrofishing sites is legitimate, not a data fault. Downgrade to a message so the
      ef-drop count still reports. Write it to stay correct for Peace/Skeena, since this
      is the file that gets back-ported.
- [ ] Start the bcfishpass SSH tunnel on `:63333` with a long hold (`sleep 1200`, not the
      `sleep 10` commented in `~/.Renviron`) — the step_1 watershed/TWC refresh queries
      `bcfishpass.crossings_vw`
- [ ] Run `0210` → four-CSV prep; confirm `has_fish` reports "no fish data found"
- [ ] Reconcile step_1 (11 locations) and step_4 (11 habitat rows, 0 dropped) against the
      report's own site list
- [ ] Review the missing-watershed-code gap report; resolve any gaps in QGIS against
      `whse_fish.wdic_waterbody_route_line_svw`, or let TWCs assign
- [ ] Decide on `waterbody_id = 00000NA` in step_4 — Peace shipped this defect (the
      `00000NA` fix was applied to step_1 only; step_4's value comes straight through from
      `0210`). Fix here rather than submit it twice.

## Phase 5: Build and review the workbook

- [ ] Set `dir_workbook <- fs::path("hold")` and build the draft
- [ ] Open it: dropdowns, sheet protection and Step 4 formulas intact; Steps 2 and 3 empty;
      Step 1 header block filled including the DFO field; gradient displays as percent
      (the template's `AVERAGE(...)/100` with numFmt `0.0%` is correct — do not override,
      see the retraction in Peace's `75fb638`)
- [ ] Flip `dir_workbook <- dir_out` and rebuild in place

## Phase 6: QA and submit

- [ ] Run the provincial QA tool (Windows, Excel ≤2010; optional but recommended). Any fix
      made there must be made in the repo copy too, or the two diverge
- [ ] Submit `PG25-983997` via the WLRS SPO FDS SharePoint site
      (`https://bcgov.sharepoint.com/sites/WLRS-FDS`, access via `fishdatasub@gov.bc.ca`)
- [ ] Capture the confirmation in `data/permit_submission/`
- [ ] Close out `WL25-993485` in the provincial portal as a nil return — no data collected
      (Archer, Slough, Rucheon creeks). Portal action, no code.

## Phase 7: Report wiring and release

- [ ] Point `2400-Attachment_data.Rmd` at `data/permit_submission/<permit_id>.xlsx`. It
      currently links to `data/habitat_confirmations.xls`, which does not exist — a live
      broken link in the published book. Use the no-fish wording: drop Peace's PIT-tagging
      clause and its raw-fish-data paragraph.
- [ ] Bump `DESCRIPTION` 0.2.1 → 0.3.0 and add the NEWS.md entry
- [ ] `index.Rmd` `date:` still reads `Version 0.0.1` — stale against DESCRIPTION/NEWS
- [ ] Rebuild the book; confirm the attachment link resolves

## Out of scope — separate issue, after Fraser *and* Skeena

Back-porting to `fish_passage_template_reporting`. That is not just Fraser's changes: the
template is behind by Peace's entire workbook-writer generation, plus Fraser's no-fish and
no-ef fixes on top. One issue covering both, filed once Skeena 2025 is also done, so the
template lands one coherent generation instead of three partial ports.

## Validation

- [ ] `0210` runs with no `habitat_confirmations.xls` present
- [ ] Step CSV row counts reconcile against the report's own source
- [ ] Workbook opens with dropdowns, protection and Step 4 formulas intact
- [ ] Steps 2 and 3 empty; Step 1 and Step 4 populated
- [ ] Every site carries a watershed code, or a TWC where none exists
- [ ] Submitted under `PG25-983997`; confirmation captured
- [ ] `WL25-993485` closed out as a nil return
- [ ] `/code-check` clean on each commit
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion

# Findings — Submit the 2025 habitat confirmation data to the Province (FDS) (#26)

## The port source is Peace, not the template

Issue #26 says to port from `fish_passage_template_reporting` v0.15.0. That version is a
generation behind. Template v0.15.0's `fds_prep_for_submission.R` writes four CSVs for
manual paste-special and has **no** `has_fish`, **no** `dir_workbook`, **no** `hdr_*`
header block, **no** workbook writer, and **no** watershed/TWC refresh — so three of the
issue's own test-plan items cannot be met from it.

`fish_passage_peace_2025_reporting` `origin/main` has all of it. The template received the
early paste-based port (`e1d800b`, `95daae2`); Peace then advanced past it in

```
69108dc Add fds_prep_2025.R and the four sheets ready to paste
4c72138 Consolidate to one submission script, unversioned in the filename
29c6720 Build the submission workbook programmatically, drafting to hold/
75fb638 Retract the gradient override; surface missing watershed codes
27d8d7b Refresh watershed codes, assign TWCs, and make the script portable
4ad5593 Fill the Step 1 header block from the report and permit
3490efb Blank electrofisher settings on visual observation rows
a6c8aa5 Promote the reviewed workbook to the submission directory
```

without porting back. Read `27d8d7b` first — it is what lets the script move between repos
unchanged (template resolved by glob, sheet geometry derived from the workbook, fish
sheets optional).

This is exactly the drift issue #26 step 7 warns about, running in the opposite direction
from what the issue assumes.

## Fraser has zero `_ef` sites, so the script aborts as written

Fraser's 11 sites are `203581`, `196076`, `196085`, `203582`, `126158`, `196332` (us/ds).
None matches `_ef[0-9]*$`. `fds_prep_for_submission.R` carries an unconditional

```r
stopifnot(sum(is_ef(step_4$local_name)) > 0)
```

which stops the run.

### The trap that produced a wrong first read

`data/backup/2025/form_fiss_site_2025.csv` is the **pooled all-regions** backup — 26 rows,
8 `_ef`, including Peace's `125179` / `198692` monitoring sites (named in
`fish_passage_peace_2025_reporting#23`). Reading it suggests Fraser has ef sites. It does
not.

| File | Rows | `_ef` sites |
|---|---|---|
| `data/backup/2025/form_fiss_site_2025.csv` (pooled) | 26 | 8 |
| `data/backup/2025/sern_fraser_2024/form_fiss_site_2025.csv` (Fraser) | 11 | 0 |

The pipeline's real input is the Fraser Mergin gpkg at
`~/Projects/gis/sern_fraser_2024/data_field/2025/form_fiss_site_2025.gpkg`.

## The no-fish path

`has_fish` is a file-existence check, not a param:

```r
path_step_2 <- "data/inputs_raw/fish_data_coll.csv"
path_step_3 <- "data/inputs_raw/fish_data_ind.csv"
has_fish <- fs::file_exists(path_step_2) && fs::file_exists(path_step_3)
```

`0220` is not run for Fraser, so neither file exists and `has_fish` resolves FALSE on its
own. Downstream: `step_2_submission` and `step_3_submission` are `NULL`, the two fish CSVs
are not written, and `sheet_spec` self-prunes so the workbook writer never touches Steps 2
and 3.

With zero `_ef` sites the step_4 drop is a no-op — all 11 sites submit habitat — and
step_2's comment inheritance and electrofisher-settings blanking are skipped with it.

## Verified, needs no work: the DFO header field

Peace passed `hdr_permit_dfo <- NA_character_`, and `put_by_label()` returns early on `NA`,
so the DFO label lookup has never actually run. Checked it against the template directly:

| Sheet | Row | Col | Label |
|---|---|---|---|
| Step 1 (Ref. and Loc. Info) | 25 | 2 | `DFO  PERMIT NUMBER:` (double space) |

`grepl("^DFO", ...)` matches it uniquely, so `put_by_label("^DFO", "XR 463 2025", 3)` lands
correctly with no code change.

## Do not re-run `0205_fiss_wrangle.R`

Issue #26 step 3 says to run `0205 → 0210 → 0220`. That is wrong. `0205` writes back to the
field-form gpkgs with `sf::st_write(delete_dsn = TRUE)`, and its `source` column pools all
three regions — running it from this repo destructively rewrites three Mergin projects.
Peace deliberately did not re-run it, which is why the watershed refresh was moved into
`fds_prep_for_submission.R`.

## Gotchas inherited from Peace's #23

1. **`readxl` lies about row geometry** — it skips leading blank rows, reporting headers at
   15/23/18/20. `tidyxl::xlsx_cells()` gives absolute addresses: headers 32/24/19/21, data
   33/25/20/22. Corroborated by the template's own VLOOKUP range `$33:$625`.
2. **The gradient "bug" is a false alarm — do not re-fix it.** `Average Gradient (%)`
   carries Excel numFmt `0.0%`, and a percent-formatted cell multiplies by 100 for display,
   so the template's `AVERAGE(...)/100` is correct: stored `0.028` renders `2.8%`. Peace
   committed an override (`f5006c6`) then retracted it (`75fb638`).
3. **`00000NA` residual defect.** The fix was applied to step_1 only; step_4's
   `waterbody_id` comes straight through from `0210`, and Peace's submitted
   `step_4_stream_site_data.csv` carries `00000NA` on all six rows. Fix here rather than
   submit it twice.
4. **`openxlsx::loadWorkbook()` fails on legacy `.xls`** (`subscript out of bounds`),
   succeeds on `.xlsx`. Step 2's data-validation count moves 33 → 35 on re-serialize,
   reproducible against the untouched template — openxlsx, not the script.
5. **Template facts** — 8 sheets, 101 validations stored as inline literal lists,
   `sheetProtection password="dbeb"` on 7 of 8, no macros. Province accepts `.xls` or
   `.xlsx`. The QA tool is optional ("strongly recommended"), Windows + Excel ≤2010 only.

## Repo state at start

- Fraser `main` at `d22bf2d`, clean, v0.2.1. `planning/active/` empty.
- `index.Rmd` has no `permit_id` (also missing `derive_params`, `species_of_interest`).
- `index.Rmd` `date:` reads `Version 0.0.1` — stale against DESCRIPTION/NEWS.
- `2400-Attachment_data.Rmd` links to `data/habitat_confirmations.xls`, which does not
  exist in the repo — a live broken link in the published book.
- No `data/templates/`, no `data/permit_submission/`.
- The local Peace checkout was 41 commits behind `origin/main` (clean fast-forward).

## Issue context

<full body of fish_passage_fraser_2025_reporting#26 — see `gh issue view 26`>

Relates to NewGraphEnvironment/fish_passage_template_reporting#128
Relates to NewGraphEnvironment/fish_passage_template_reporting#132
Relates to NewGraphEnvironment/fish_passage_fraser_2025_permit#3

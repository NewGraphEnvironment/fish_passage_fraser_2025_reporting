# Prepare the Fish Data Submission sheets for the provincial permit submission.
#
# Consumes the four step CSVs produced by 0210_fiss_export_to_template.Rmd and
# 0220_fish_data_tidy.R, applies the submission-only transforms, and writes the
# result to data/permit_submission/. Nothing here touches the workbook - the
# outputs are what gets pasted into a copy of the blank provincial template.
#
# Usage (from repo root):
#   Rscript scripts/03_permit_submission/fds_prep_for_submission.R
#
# ---------------------------------------------------------------------------
# MANUAL STEPS AROUND THIS SCRIPT
# ---------------------------------------------------------------------------
#
# 1. Copy the blank template to data/permit_submission/<permit_id>.xlsx.
#    Blank lives at data/templates/FDS_Template2026-03-11.xlsx.
#
# 2. Fill the Step 1 header block by hand:
#      Project Title              same as the report title
#      Company/Agency             Other
#      Company/Agency (Other)     New Graph Environment Ltd.
#      Spreadsheet Recorder(s)    whoever assembled it
#      Project Type               Research
#      PROVINCIAL PERMIT NUMBER   params$permit_id
#      Reviewed and verified by a Registered Professional Biologist    Yes
#      Biologist's Name           Allan Irvine
#      Registration Number        2775
#      Province of Registration   British Columbia
#
# 3. Run this script, then paste the four CSVs in. Data starts at rows
#    33 / 25 / 20 / 22 for Steps 1-4.
#
#    Step 4 self-populates five AVERAGE() and five VLOOKUP() columns - leave
#    those alone, EXCEPT `Average Gradient (%)`. See the note at the foot of
#    this script.
#
# 4. QA. The provincial QA tool ships in the same zip as the template and runs
#    only on Windows, Excel 2010 or earlier. It is optional but recommended.
#    The historical route is: copy the workbook to OneDrive, open on a Windows
#    machine, run the tool, record issues, copy back. Anything fixed there must
#    be fixed in the repo copy too or the two diverge.
#
# 5. Submit via the WLRS SPO FDS SharePoint site
#    (https://bcgov.sharepoint.com/sites/WLRS-FDS; access via
#    fishdatasub@gov.bc.ca), plus DFO if the permit requires it. Capture the
#    confirmation in the repo.
#
# ---------------------------------------------------------------------------
#
# Replaces fds_prep_for_submission_2023.Rmd. That version also rebuilt watershed
# codes and reference numbers because the 2023 workflow keyed off a hand-filled
# habitat_confirmations.xls; 0205/0210 now produce both upstream, so only the
# submission-shaping transforms remain here. Its per-season values are in git
# history rather than duplicated in a second file - the year in that filename is
# what let it be copied forward into the 2024 and 2025 repos unchanged.

suppressMessages({
  library(dplyr)
})

params <- rmarkdown::yaml_front_matter("index.Rmd")$params

dir_out <- fs::path("data/permit_submission")
fs::dir_create(dir_out)

# Where the built workbook lands.
#
# Point at hold/ while a rebuild is under review, and at dir_out once it is
# confirmed - it overwrites in place either way. The report's data attachment
# links to dir_out, so that is where the submitted artifact has to live.
# dir_workbook <- fs::path("hold")   ## <- use while reviewing a rebuild
dir_workbook <- dir_out

path_workbook <- fs::path(dir_workbook, paste0(params$permit_id, ".xlsx"))

# Step 1 header block ------------------------------------------------------
#
# Values for the referencing and sign-off block above the data. Written by this
# script rather than typed, so a rebuild cannot lose them. Layout verified
# against the submitted SM24-882238 and PG24-879256 workbooks: labels sit in
# columns B and F, values in C and K.
#
# Project title comes from the report front matter - past submissions used the
# report title verbatim. Permit number comes from params. The rest are either
# organisation constants or change per submission, so they are set here.
hdr_recorder     <- "Allan Irvine"          # who assembled this spreadsheet
hdr_permit_dfo   <- "XR 463 2025"           # DFO licence for Fraser 2025; Peace 2025 had none (NA)
hdr_rpbio_name   <- "Allan Irvine"
hdr_rpbio_reg    <- "2775"
hdr_rpbio_prov   <- "British Columbia"

hdr_title <- rmarkdown::yaml_front_matter("index.Rmd")$title

# Newest shipped template, rather than a pinned filename - the province reissues
# it periodically and the column sets have been stable across reissues.
path_template <- sort(fs::dir_ls("data/templates", regexp = "FDS_Template.*\\.xlsx$"),
                      decreasing = TRUE)[1]
stopifnot(length(path_template) == 1, !is.na(path_template))

rd <- function(p) readr::read_csv(p, show_col_types = FALSE)

step_1 <- rd("data/inputs_extracted/form_fiss_loc_tidy.csv")
step_4 <- rd("data/inputs_extracted/form_fiss_site_tidy.csv")

# A season with no fish sampled still submits locations and habitat - it records
# where we were and what was assessed. 0220_fish_data_tidy.R produces nothing in
# that case, so the fish sheets are optional and left empty in the workbook.
path_step_2 <- "data/inputs_raw/fish_data_coll.csv"
path_step_3 <- "data/inputs_raw/fish_data_ind.csv"
has_fish <- fs::file_exists(path_step_2) && fs::file_exists(path_step_3)

step_2 <- if (has_fish) rd(path_step_2) else NULL
step_3 <- if (has_fish) rd(path_step_3) else NULL

if (!has_fish) message("no fish data found - submitting locations and habitat only")

# Which sites are small electrofishing sites -------------------------------
#
# Site naming is <crossing_id>_<location>_ef<n>. The 2023 script used
# grepl("ef", local_name), a bare substring match that would also catch any name
# happening to contain those letters. Anchor it instead.
is_ef <- function(x) grepl("_ef[0-9]*$", x)

# A season with no small electrofishing sites is legitimate, not a data fault -
# Fraser 2025 has none, and every one of its sites submits habitat. So this is not
# a stopifnot. But an anchored regex is exactly what a naming change breaks
# silently, and the failure is invisible: ef habitat rows would be submitted as
# conforming 100 m sites. Separate the two cases.
n_ef <- sum(is_ef(step_4$local_name))

if (n_ef == 0) {
  looks_ef <- grepl("ef", step_4$local_name, ignore.case = TRUE)
  if (any(looks_ef)) {
    stop("no local_name matches _ef[0-9]*$, but these look like ef sites - ",
         "site naming has drifted from <crossing_id>_<location>_ef<n>:\n  ",
         paste(step_4$local_name[looks_ef], collapse = "\n  "), call. = FALSE)
  }
  message("no small electrofishing sites this season - all ", nrow(step_4),
          " habitat sites submitted")
}

# step_4 - carry the site id into comments, then drop the ef sites -----------
#
# Per fish_passage_template_reporting#27: locations and all fish data for the
# small ef sites are submitted; only their habitat rows are withheld, because a
# return-visit shocking site is not a conforming 100 m habitat site (RISC recce
# standard - at least the greater of 100 m or 10x bankfull width).
#
# The alias is moved into comments first so the province's copy can still be
# cross-referenced back to our reports.
step_4_commented <- step_4 |>
  mutate(
    comments = dplyr::case_when(
      is.na(comments) | !nzchar(trimws(comments)) ~ paste0("Site ", local_name, "."),
      TRUE ~ paste0("Site ", local_name, ". ", comments)
    )
  )

step_4_submission <- step_4_commented |>
  filter(!is_ef(local_name))

# step_2 - inherit the comments from the dropped step_4 rows -----------------
#
# Once the ef rows leave step_4, step_2 is the only sheet carrying their
# comments, so append them there rather than lose them.
comments_from_step_4 <- step_4_commented |>
  select(reference_number, comments_site = comments)

# Electrofisher settings belong only to electrofishing rows. The site-level gear
# columns are carried onto every row upstream, so a visual observation ends up
# reporting a voltage and an enclosure it never had. The template scopes each of
# these to electrofishing in its own definitions - "used during the
# electrofishing pass" (voltage), "prevent fish escaping capture during
# electrofishing" (enclosure), "the company which manufactured the
# electrofishing equipment" (make). Blank them for anything else.
#
# Haul/Pass is deliberately left alone: the template defines it as "the number of
# the Haul (Traps or Nets) or Pass (Electrofishing)", so it is not gear-specific.
cols_ef_only <- c("ef_seconds", "site_length", "avg_wetted_width_m", "enclosure",
                  "voltage", "frequency", "pulse", "make", "model")

step_2_submission <- if (!has_fish) NULL else {
  step_2 |>
    left_join(comments_from_step_4, by = "reference_number") |>
    mutate(
      comments = dplyr::case_when(
        is.na(comments_site) ~ comments,
        is.na(comments) | !nzchar(trimws(comments)) ~ comments_site,
        TRUE ~ paste(comments_site, comments)
      )
    ) |>
    select(-comments_site) |>
    mutate(across(any_of(cols_ef_only),
                  ~ dplyr::if_else(grepl("electrofish", sampling_method, ignore.case = TRUE),
                                   .x, NA)))
}

# step_1 - refresh watershed codes, then assign TWCs where none exists ------
#
# Two reasons this happens here rather than in 0205_fiss_wrangle.R:
#
#  - 0205 writes back to the field-form gpkgs with delete_dsn = TRUE, and the
#    `source` column pools all three regions, so running it from one repo
#    destructively rewrites three Mergin projects. Not worth it for a lookup.
#  - The gpkg's watershed data is only as fresh as the last 0205 run. Querying
#    here means the submission always carries current codes.
#
# The template's own rules, from the cell comments on Step 1 (F32 and G32):
#
#   "If there is no Watershed Code results for your waterbody, then leave this
#    field blank and fill out the TWC# field."
#   "For TWCs, leave WSC code and Waterbody ID blank. Do not use the WSC of the
#    parent stream."
#   "identify the waterbody by creating a numeric TWC (maximum 5 digits). All
#    the sites on a waterbody must be given the same #."
#
# "Same waterbody" is keyed on blue_line_key, the FWA stream identifier, so two
# crossings on one stream share a TWC.

parse_ws_code <- function(code) {
  dplyr::case_when(
    stringr::str_length(code) != 45 ~ NA_character_,
    TRUE ~ stringr::str_c(
      stringr::str_sub(code, 1, 3), "-",  stringr::str_sub(code, 4, 9), "-",
      stringr::str_sub(code, 10, 14), "-", stringr::str_sub(code, 15, 19), "-",
      stringr::str_sub(code, 20, 23), "-", stringr::str_sub(code, 24, 27), "-",
      stringr::str_sub(code, 28, 30), "-", stringr::str_sub(code, 31, 33), "-",
      stringr::str_sub(code, 34, 36), "-", stringr::str_sub(code, 37, 39), "-",
      stringr::str_sub(code, 40, 42), "-", stringr::str_sub(code, 43, 45)
    )
  )
}

ids <- step_1 |>
  mutate(site = as.integer(sub("_.*$", "", alias_local_name))) |>
  distinct(site) |>
  filter(!is.na(site)) |>
  pull(site)

wsc <- fpr::fpr_db_query(query = glue::glue("
  SELECT DISTINCT ON (a.stream_crossing_id)
    a.stream_crossing_id, a.blue_line_key, a.watershed_group_code,
    b.watershed_code_50k
  FROM bcfishpass.crossings_vw a
  LEFT OUTER JOIN whse_basemapping.fwa_streams_20k_50k b
    ON a.linear_feature_id = b.linear_feature_id_20k
  WHERE a.stream_crossing_id IN ({glue::glue_collapse(ids, sep = ', ')})
  ORDER BY a.stream_crossing_id, b.match_type;")) |>
  # watershed_group_code comes from crossings_vw, not from the 50k join, so it
  # survives a missing 50k code. 0205 filtered on code length before selecting
  # both, which discarded an available group code alongside the missing one.
  mutate(wsc_parsed = parse_ws_code(watershed_code_50k))

step_1_submission <- step_1 |>
  mutate(site = as.integer(sub("_.*$", "", alias_local_name))) |>
  select(-watershed_code_45_digit, -waterbody_id_identifier) |>
  left_join(wsc |> select(site = stream_crossing_id, blue_line_key,
                          watershed_group_code, wsc_parsed),
            by = "site") |>
  # A TWC is required only where no 45-digit code exists; one number per stream.
  group_by(blue_line_key) |>
  mutate(needs_twc = all(is.na(wsc_parsed))) |>
  ungroup() |>
  mutate(
    twc_number = dplyr::if_else(needs_twc,
                                as.character(dense_rank(dplyr::if_else(needs_twc, blue_line_key, NA_integer_))),
                                NA_character_),
    watershed_code_45_digit = wsc_parsed,
    # Blank for TWC sites, per the template: do not use the parent stream's WSC.
    waterbody_id_identifier = dplyr::if_else(
      needs_twc | is.na(watershed_group_code), NA_character_,
      paste0("00000", watershed_group_code))
  ) |>
  select(any_of(names(step_1)))

# step_4 - take the waterbody id from step_1 rather than the geopackage ------
#
# step_4's waterbody_id arrives from 0210, i.e. from whatever 0205 last wrote to
# the field-form geopackage. Two problems with submitting that: it is as stale as
# the last 0205 run, and where the group code was missing, paste0() had already
# turned it into the literal string "00000NA" - which looks like a real waterbody
# id rather than a gap. Peace 2025 submitted "00000NA" on all six of its step_4
# rows for exactly this reason; the 00000NA fix was applied to step_1 only.
#
# step_1 has just been re-resolved from bcfishpass above, so carry its value
# across on reference_number. The two sheets then agree by construction, and a
# genuine gap stays blank instead of reading as data.
step_4_submission <- step_4_submission |>
  select(-waterbody_id) |>
  left_join(
    step_1_submission |> select(reference_number, waterbody_id = waterbody_id_identifier),
    by = "reference_number"
  ) |>
  select(any_of(names(step_4)))

# step_3 passes through unchanged - every fish is submitted.
step_3_submission <- step_3

# Write ---------------------------------------------------------------------
readr::write_csv(step_1_submission, fs::path(dir_out, "step_1_ref_and_loc_info.csv"), na = "")
readr::write_csv(step_4_submission, fs::path(dir_out, "step_4_stream_site_data.csv"), na = "")
if (has_fish) {
  readr::write_csv(step_2_submission, fs::path(dir_out, "step_2_fish_coll_data.csv"), na = "")
  readr::write_csv(step_3_submission, fs::path(dir_out, "step_3_individual_fish_data.csv"), na = "")
}

message(
  "permit ", params$permit_id, " - rows:\n",
  "  step_1 ", nrow(step_1_submission), " (all sites)\n",
  "  step_2 ", if (has_fish) nrow(step_2_submission) else "- (no fish sampled)", "\n",
  "  step_3 ", if (has_fish) paste(nrow(step_3_submission), "(all fish)") else "- (no fish sampled)", "\n",
  "  step_4 ", nrow(step_4_submission), " of ", nrow(step_4),
  " (dropped ", sum(is_ef(step_4$local_name)), " ef sites)"
)

# Build the workbook --------------------------------------------------------
#
# Writes the four sheets into a copy of the blank provincial template, so no
# copy-paste-special is required. The CSVs above remain the reviewable
# intermediate, and still support the manual route if this is ever distrusted.
#
# One rule, enforced by `col_skip` below: derived columns are left alone so the
# workbook computes them itself - the VLOOKUP pulls from Step 1 on every sheet,
# Step 2's Soak Time, and all five of Step 4's AVERAGE columns.
#
# That includes `Average Gradient (%)` (Step 4, col 44), whose formula is
# AVERAGE(...)/100. The /100 is correct and must not be overridden: that cell
# carries Excel number format `0.0%`, and a percent-formatted cell multiplies by
# 100 for display. So 0.028 displays as 2.8%, which is what the measurements
# (2.0, 3.5, ...) average to. Writing 2.8 into it would display as 280.0%.
# See fish_passage_template_reporting#217.

sheet_spec <- list(
  list(sheet = "Step 1 (Ref. and Loc. Info)",   dat = step_1_submission),
  list(sheet = "Step 2 (Fish Coll. Data)",      dat = step_2_submission),
  list(sheet = "Step 3 (Individual Fish Data)", dat = step_3_submission),
  list(sheet = "Step 4 (Stream Site Data)",     dat = step_4_submission)
)
sheet_spec <- Filter(function(x) !is.null(x$dat), sheet_spec)

# 0210 builds step_1 and step_4 by binding onto the template's own empty sheet,
# so their names already match. 0220 does not, so the fish sheets need a map
# from our column name to the template's. Folding that into 0220 would delete
# this - see fish_passage_template_reporting#216.
col_rename <- list(
  "Step 2 (Fish Coll. Data)" = c(
    haul_number_pass_number = "pass_number", ef_length_m = "site_length",
    ef_width_m = "avg_wetted_width_m", stage = "life_stage",
    total_number = "total_num", min_length_mm = "min_length",
    max_length_mm = "max_length"),
  "Step 3 (Individual Fish Data)" = c(
    haul_number_pass_number = "pass_number", length_mm = "length",
    weight_g = "weight")
)

fs::dir_create(dir_workbook)
cells <- tidyxl::xlsx_cells(path_template)
wb <- openxlsx::loadWorkbook(path_template)

# Header row and formula columns are read from the template rather than pinned,
# so a reissued template with shifted rows or new derived columns still works.
# The header is the row carrying the most text cells; the formula columns are
# whichever cells hold a formula in the first data row.
sheet_geometry <- function(sheet) {
  d <- cells |> filter(sheet == !!sheet)
  row_header <- d |> filter(!is.na(character)) |> count(row) |>
    slice_max(n, n = 1, with_ties = FALSE) |> pull(row)
  list(
    row_header = row_header,
    col_skip   = d |> filter(row == row_header + 1, !is.na(formula)) |> pull(col)
  )
}

for (sp in sheet_spec) {
  geo <- sheet_geometry(sp$sheet)
  hdr <- cells |>
    filter(sheet == sp$sheet, row == geo$row_header, !is.na(character)) |>
    arrange(col)
  nms <- janitor::make_clean_names(trimws(hdr$character))
  map <- col_rename[[sp$sheet]]

  for (i in seq_len(nrow(hdr))) {
    if (hdr$col[i] %in% geo$col_skip) next   # derived - let the workbook compute it
    nm <- nms[i]
    if (!is.null(map) && nm %in% names(map)) nm <- unname(map[[nm]])
    if (!nm %in% names(sp$dat)) next         # field we do not collect - left blank
    openxlsx::writeData(wb, sheet = sp$sheet, x = sp$dat[[nm]],
                        startRow = geo$row_header + 1, startCol = hdr$col[i],
                        colNames = FALSE)
  }
}

# Header block. Written by label rather than by fixed address: each label is
# located in column B (or F for the sign-off side) and the value goes in the
# same row, so a template that shifts these rows still fills correctly.
sheet_1 <- "Step 1 (Ref. and Loc. Info)"
hdr_cells <- cells |> filter(sheet == sheet_1, col %in% c(2, 6), !is.na(character))

put_by_label <- function(label, value, col_value) {
  if (is.na(value)) return(invisible(NULL))
  hit <- hdr_cells |> filter(grepl(label, character, ignore.case = TRUE, fixed = FALSE))
  if (nrow(hit) != 1) {
    warning("header label not uniquely found, skipped: ", label, call. = FALSE)
    return(invisible(NULL))
  }
  openxlsx::writeData(wb, sheet = sheet_1, x = value,
                      startRow = hit$row[1], startCol = col_value, colNames = FALSE)
}

put_by_label("^Project Title",             hdr_title,           3)
put_by_label("^Company/Agency$",           "Other",             3)
put_by_label("^Company/Agency \\(Other\\)", "New Graph Environment Ltd.", 3)
put_by_label("^Spreadsheet Recorder",      hdr_recorder,        3)
put_by_label("^Project Type",              "Research",          3)
put_by_label("^PROVINCIAL PERMIT NUMBER",  params$permit_id,    3)
put_by_label("^DFO",                       hdr_permit_dfo,      3)
put_by_label("^The information in this submission", "Yes",     11)
put_by_label("^Biologist's Name",          hdr_rpbio_name,     11)
put_by_label("^Registration Number",       hdr_rpbio_reg,      11)
put_by_label("^Province of Registration",  hdr_rpbio_prov,     11)

openxlsx::saveWorkbook(wb, path_workbook, overwrite = TRUE)
message("\nworkbook written: ", path_workbook,
        if (identical(as.character(dir_workbook), "hold")) "  (DRAFT - review, then flip dir_workbook)" else "")
# Gaps worth seeing before the workbook is reviewed -------------------------
#
# Sites whose watershed code did not resolve. Some crossings have no entry in
# whse_basemapping.fwa_streams_20k_50k, so the 20k -> 50k cross-reference
# returns nothing and both the code and the waterbody id are missing. These
# need a manual lookup - the documented route is QA in QGIS against
# whse_fish.wdic_waterbody_route_line_svw.
gaps <- step_1_submission |>
  filter(is.na(watershed_code_45_digit) | is.na(waterbody_id_identifier)) |>
  select(alias_local_name, waterbody_id_identifier, watershed_code_45_digit)

if (nrow(gaps) > 0) {
  message("\n!! ", nrow(gaps), " of ", nrow(step_1_submission),
          " sites are missing a watershed code / waterbody id:")
  message(paste0("     ", gaps$alias_local_name, collapse = "\n"))
} else {
  message("\nall sites carry a watershed code and waterbody id")
}

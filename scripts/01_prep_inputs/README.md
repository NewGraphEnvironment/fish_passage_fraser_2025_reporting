Workflows for pre-processing of field data so it aligns with our reporting and fits the requirements for data submission.

These are designed to be self sufficient scripts with everything in them necessary to do there specific task with a clean working environment.

<br>

# Pre-Processing Inputs

Workflows for pre-processing of field data so it aligns with our reporting and fits the requirements for PSCIS uploads.

These are often two-way workflows where we use output CSV spreadsheets to update our raw input datasheets through a manual copy-paste-special. 

These are designed to be self-sufficient scripts with everything in them necessary to do their specific task with a clean working environment.


### 0110-photos.Rmd

- Resizes and renames all Mergin photos
- Resizes and renames all OneDrive photos
- Moves and organizes all photos into site-specific directories and ensures compliance with PSCIS size requirements
- Removes duplicate photos

### 0120_pscis_backup.Rmd

- Creates a backup of raw PSCIS data before the data is QAed. 

### 0130_pscis_wrangle.Rmd

- Imports the QAed cleaned data and further cleans it, then burns to a new geopackage
- After the data has been submitted to the province, it adds PSCIS ids to the form and burns back to PSCIS geopackage
- This script is still a WIP and there is an issue about what still needs to be added here https://github.com/NewGraphEnvironment/fish_passage_template_reporting/issues/56 

### 0140_pscis_export_to_template.Rmd

- Prepares PSCIS data for copy and paste into PSCIS submission spreadsheet
- Exports PSCIS data to a csv for cut and paste into PSCIS submission spreadsheet
- Determines the replacement structure, size, and type and burns it to a csv for copy and paste into PSCIS submission spreadsheet


### 0150_pscis_export_submission.R

- Moves photos and files to OneDrive for PSCIS submission
- QAs photos before submission

### 0200_fiss_backup.Rmd

- Creates a backup of raw FISS site data before the data is QAed. 

### 0205_fiss_wrangle.Rmd

- Imports the QAed FISS site data and further cleans it:
    - Adds the watershed codes
    - Calculates the average of the numeric columns
    - General cleaning
- Burns it back to a new geopackage

### 0210_fiss_export_to_template.Rmd

- Shapes the QAed FISS site data to the provincial Fish Data Submission template, taking
  the column names from the blank at `data/templates/FDS_Template2026-03-11.xlsx`
- Writes `data/inputs_extracted/form_fiss_loc_tidy.csv` (Step 1) and
  `form_fiss_site_tidy.csv` (Step 4), and assigns the `reference_number` that keys every
  other sheet

### 0220_fish_data_tidy.R

- Joins PIT tag data to the raw fish data
- Writes `data/inputs_raw/fish_data_coll.csv` (Step 2) and `fish_data_ind.csv` (Step 3)
- Runs **after** `0210` — it takes reference numbers from `form_fiss_loc_tidy.csv`
- Skipped in a season with no fish sampled. `fds_prep_for_submission.R` detects the absence
  of these two files and submits locations and habitat only

Up to and including 2024 these fed a hand-filled workbook NewGraph called
`habitat_confirmations.xls`. From 2025 the four CSVs go to
`scripts/03_permit_submission/fds_prep_for_submission.R`, which writes them straight into a
copy of the blank provincial template — there is no copy-and-paste step and no
`habitat_confirmations.xls`.


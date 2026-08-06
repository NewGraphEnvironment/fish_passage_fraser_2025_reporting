# fish_passage_fraser_2025_reporting 0.6.1 (2026-08-05)

* Declare everything the book loads in `scripts/packages.R`. `leafpop` (interactive map popups), `english` (inline prose), `bcmaps` (UAV appendix) and `cd` (climate departure appendix) were used in rendered chunks but declared nowhere, so a fresh clone could not build. Also set a CRAN mirror when the session has none — `Rscript` starts with `repos` unset, which made the pak check fail outright while RStudio masked it — and read `params$update_packages` defensively, since several scripts source this file before defining `params` ([Issue #30](https://github.com/NewGraphEnvironment/fish_passage_fraser_2025_reporting/issues/30))

# fish_passage_fraser_2025_reporting 0.6.0 (2026-08-05)

* Build the provincial Fish Data Submission workbook for the 2025 habitat confirmations, at `data/permit_submission/PG25-983997.xlsx` under scientific fish collection permit PG25-983997, with DFO licence XR 463 2025. No fish were sampled, so the submission carries site locations and habitat measurements only and Steps 2 and 3 are empty. Ports the workflow from Peace 2025 rather than the reporting template, which is a generation behind and writes CSVs for manual copy-paste-special ([Issue #26](https://github.com/NewGraphEnvironment/fish_passage_fraser_2025_reporting/issues/26))
* Point the data attachment at the permit submission workbook. It previously linked to `data/habitat_confirmations.xls`, which the 2025 pipeline no longer produces and which has never existed in this repository — a live broken link in the published report
* Support a season with no small electrofishing sites. The submission script aborted on an unconditional check that at least one `_ef` site exists; Fraser 2025 has none. The check now distinguishes a legitimately ef-free season from site naming that has drifted away from the anchored pattern, which would otherwise submit electrofishing habitat rows as conforming 100 m RISC sites
* Take Step 4's waterbody identifier from Step 1 rather than the field-form geopackage. A missing watershed group code had been pasted into the literal string `00000NA`, which reads as a real waterbody identifier rather than a gap; 3 of 11 rows were affected. Step 1 is re-resolved from bcfishpass at submission time, so the two sheets now agree by construction
* Make `0210_fiss_export_to_template.Rmd` runnable in a clean session — it used dplyr unqualified without attaching it, and needs `knit_root_dir` set or knitr moves the working directory to the Rmd's own folder

# fish_passage_fraser_2025_reporting 0.5.0 (2026-08-05)

* Draw a site map in every site appendix. Three of the four appendices had shipped without one: the map chunks were disabled, so the page carried a dead cross-reference and, below it, the source code of the disabled chunk with no figure beneath. The fourth pointed at a JPEG hand-exported from a QGIS print layout that no copy of this repository could regenerate. All four maps are now generated in R from data committed to the repository, so they rebuild from a fresh clone with no database and no network ([Issue #23](https://github.com/NewGraphEnvironment/fish_passage_fraser_2025_reporting/issues/23)).
* Correct the drone imagery appendix, which had been publishing the Peace region's imagery. Eighteen records from the Parsnip and Carp watershed groups appeared under a Fraser heading for three releases, because the region was written into the code as a literal in a step that only runs by hand, and the resulting table was carried forward from the report this one was branched from. The appendix now lists the fifteen orthomosaics registered for the Fraser region, flown in 2024 in the Morkill and Nechacko watershed groups ([Issue #19](https://github.com/NewGraphEnvironment/fish_passage_fraser_2025_reporting/issues/19)).
* Note one known limitation of the new maps: on the South Yuzkli Creek map the shaded relief backdrop stops short of the frame edge along the right and bottom, leaving a thin ragged margin. The map content is complete and correctly placed; only the backdrop is short. Tracked for repair in the shared reporting template ([Issue #226](https://github.com/NewGraphEnvironment/fish_passage_template_reporting/issues/226)).

# fish_passage_fraser_2025_reporting 0.4.0 (2026-08-04)

* Point the environmental DNA laboratory methods at UNBC's technical report for these samples, which is now committed to the repository and published with the report rather than cited from elsewhere. The methods had been a single sentence citing a 2023 protocol report for samples analysed under a 2026 one, and stated none of the rules a reader needs in order to interpret the tables. Four are now stated because the results cannot be read without them: the four-droplet call threshold and what happens to two- and three-droplet results, the two elutions analysed per filter, the lambda and ePlant controls run on samples returning no detections, and that the bull trout assay does not distinguish Bull Trout from Dolly Varden.
* Report environmental DNA results as detected or not detected. The report had carried a third tier for results of one to three positive droplets, shown as its own column in the results summary, the eDNA appendix, the four site appendices and the Bittner memo. The laboratory retests any sample returning two or three droplets and calls it negative where the additional droplets do not reach four, so that tier is simply negative and presenting it separately implied a result the analysis does not support.
* Withdraw the claim that non-detections could not be interpreted because amplification controls were not reported. The controls are run on samples returning no detections, test the extract rather than any single species assay, and where they indicated inhibition or degradation the laboratory combined elutions, cleaned and retested. All eight of this report's all-negative samples carry a control result. The claim had reached the executive summary, the results chapter and the eDNA appendix.
* Add the 2025 scientific fish collection licence and permit submission records to `data/permit_submission/`.

# fish_passage_fraser_2025_reporting 0.3.1 (2026-08-02)

* Remove a claim that the report provides preliminary top remediation priorities by watershed group. No such section, table or ranking exists anywhere in the report — priorities appear only per site, in prose, within the individual site appendices. The surrounding reasoning for why a single definitive ranking is not achievable is retained in both the executive summary and the recommendations.
* Remove a claim that 2025 field activities revisited sites whose habitat confirmations were documented in earlier reporting, and that those earlier reports were updated with 2025 data. Neither is true for this region: none of the seven crossings covered here appear anywhere in the 2023 report, and that report was last edited on 2025-07-23, roughly seven weeks before the 2025 field season began. The sentence also hardcoded 2024 as the field year. It was inherited template prose, accurate for the Peace region and never checked against Fraser.
* Correct the eDNA sample count in the executive summary. It reported every row of the sampling form as a sample collected from a stream — 38 samples across 16 streams — but five of those rows are field and office blanks run as protocol controls, and the three office blanks carry no stream name, adding a phantom stream. Now reports 33 samples across 15 streams with the blanks named separately, matching the results chapter and the eDNA appendix. Counts derive from the same blank filter the eDNA table uses.
* Name the effectiveness monitoring streams and their general area in the executive summary — Tabor Creek and Bittner Creek, near Prince George — rather than giving PSCIS crossing numbers alone. Stream names and the site count derive from the monitoring form.
* Trim the effectiveness monitoring bullet in the executive summary looking-ahead list.

# fish_passage_fraser_2025_reporting 0.3.0 (2026-08-02)

* Integrate the 2025 UNBC environmental DNA results — 33 real environmental samples, 2 field blanks and 3 office blanks across the region, with 36 of 146 site-by-target combinations returning confirmed detections. Adds a per-species summary to Results, a thematic appendix, per-site detection tables in every site appendix, and an interactive map scoped to the region. Corrects three samples recorded against the wrong crossing.
* Rewrite the Recommendations chapter for the Fraser region. It carried the Peace region's recommendations unedited, referencing the FWCP Peace Region, McLeod Lake, Fern Creek and Arctic grayling. Restructured into named thematic subsections led by effectiveness monitoring, and replaces the "rankings are inherently subjective" framing with the reasoning behind it. The executive summary's looking-ahead bullets are aligned to match.
* Add a Bittner Creek monitoring appendix documenting three years of evidence that disagree — a landowner reporting no salmon in thirty years, eight juvenile chinook salvaged in 2023, and no eDNA detections in 2025 — and the two upstream constraints still unaddressed.
* Move amalgamated data tables out of the body into thematic appendices: Assessment Data Summary, Fish Species, UAV Imagery and Collaborative GIS Layers. Results drops from 799 to 634 lines and Background from 626 to 601.
* Order the appendices by first body reference, matching the Peace report's tiering, and add named links to the four per-site appendices, which previously had no inbound reference at all.
* Wire the First Nations background into the report as its own section, restoring nine citations that were invisible while the block was commented out.
* Split the build into `run_gitbook.R` and `run_pagedown.R`, fixing a bug where the gitbook shipped the Phase 1 appendix twice, and setting a CRAN mirror so non-interactive builds work at all.
* Read `fp_sites_tracking` from a committed parquet snapshot rather than querying postgres, so the report builds from a fresh clone with no database access.
* Derive scope statements from the data rather than restating them in prose — the fish-species caption from the cached table's own columns, and the climate-departure extent from the analysis geopackage.
* Fix six inline expressions using `cat()`, which returned NULL and dropped the project year from the rendered text entirely.
* Remove placeholder text from the acknowledgement, which was publishing `[Nations]` and two further bracketed placeholders.
* Migrate citation keys to xciter's canonical bibliography — the last repo in the family still carrying the per-profile "title-words" keys.
* Correct the report version on the title page, which read 0.0.1 through two releases.
* Fix Table 4.5, Summary of Phase 2 habitat confirmation details, which has been rendering with no data rows. `stringr::str_like()` became case sensitive in stringr 1.5.0, so a filter looking for lowercase 'upstream' stopped matching the "Upstream" values the table is built from. Adds a total for the surveyed length and states in the caption that the lengths are upstream reaches only, since the table totals 3,140 m while the text total of 4.3 km includes downstream reaches.
* Correct the stated extent of the habitat confirmation work. The text claimed assessments were completed across all eight project watershed groups; they were completed in Tabor River and Willow River. The site count, watershed groups and surveyed length are now derived in `0130-tables.R` so the executive summary and results chapter cannot disagree. The surveyed total previously used `round(-3)/1000`, reporting 4,280 m as "approximately 4 km" and anything under 500 m as 0 km.
* Move the Fisheries and Oceans Canada stock assessment data to its own appendix. At 1,486 rows and 51 columns it is a wide reference table rather than background prose, and being gated on `gitbook_on` it left print readers with a reference to a table that was not there. The print version now points at the appendix online.
* Note in the environmental DNA sections that non-detections from samples without reported amplification controls are not evidence of absence. Detections are unaffected. Adds recommendations at Bittner Creek for resampling with rainbow trout on the assay panel, triplicate sampling as a method test, and confirming with the laboratory whether the control results exist.
* Regenerate `references.bib` from Zotero rather than hand-editing it, and set `update_bib` back to TRUE.
* Update the model named in the assistance note to Claude Opus 5.
* Credit the Habitat Conservation Trust Foundation. The title block now names HCTF with the project number CAT26-0-636 alongside the Ministry of Transportation and Infrastructure, and the header carries the combined SERNbc and HCTF logo used in the Skeena reporting.
* Set out the funding history in the introduction and executive summary: the 2023 work was supported internally by SERNbc and through the Ministry of Transportation and Infrastructure and produced the region's 2023 report, while the project is now also supported by HCTF alongside Skeena fish passage restoration planning as the Northern British Columbia Fish Passage Restoration project (CAT26-0-636). Corrects "Morkhill" to Morkill.
* Derive the print version's PDF filename rather than hardcoding it. The introduction pointed print readers at `fish_passage_peace_2024_reporting.pdf`, a file from a different region's repository.

# fish_passage_fraser_2025_reporting 0.2.1 (2026-05-14)

* Add `update_bcfishpass` YAML switch for build portability and post-release freezing — three refresh triggers (YAML flip, missing version file, or `force_bcfishpass_rebuild`); otherwise builds read cached files with no DB connection. Migrate `bcfishpass_crossings_vw` from sqlite to parquet (zstd-9; sqlite shrunk substantially). Source `0100-load-bcfishpass-data.R` from `index.Rmd` so the switch affects builds. Ports the pattern from Peace v0.5.1 and template v0.2.0 ([Issue #186 in template](https://github.com/NewGraphEnvironment/fish_passage_template_reporting/issues/186))

# fish_passage_fraser_2025_reporting 0.2.0 (2026-05-13)

* Add climate-departure appendix for the FWCP Fraser AOI (union of 7 watershed groups: LCHL, NECR, FRAN, MORK, UFRA, TABR, WILL). Snapshot script `scripts/gis/climate_departure.R` builds AOI + 8 ecoregions and runs the `cd` pipeline; appendix `0835-appendix-climate-departure.Rmd` with recent-vs-pre-warming, trend, day-night, snowpack, spatial-pattern, per-ecoregion, and WSG×ecoregion sections; body methods/results paragraphs with inline metrics. Filenames are AOI-neutral for portability across regional reports.

# fish_passage_fraser_2025_reporting 0.1.0 (2026-05-13)

* Add floodplain delineation appendix for Nechako River Watershed Group (NECR) using chinook accessible stream network. Build script, appendix with summary table and maps, body methods/results paragraphs with inline metrics. Rename Planning section header.

# fish_passage_fraser_2025_reporting 0.0.2 (2026-05-11)

* Add standalone PDF executive summary: `_executive_summary_pdf.Rmd` wrapper, `scripts/build_exec_pdf.R`, PDF download link in gitbook chapter. Strip `[@citekey]` refs from previous-work lists; fix hardcoded PDF name to derive from `_bookdown.yml`.

# fish_passage_reporting_template 0.0.1

- *2025-02-13*  
  - Added 2025 data process scripts (01_prep_inputs).
  - Added of 2025 reporting scripts (02_reporting).
  - Added 2024 Peace data so report builds
  - Updated script readmes




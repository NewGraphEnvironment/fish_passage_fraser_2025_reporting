# Culvert Data and Model Data popup pages for the results interactive map.
#
# Every site in the map links to `sum/cv/<id>.html` and `sum/bcfp/<id>.html`.
# These are those pages. They were previously built by hand - the header read
# "Let's just make the HTML tables when we need to" - and the result was that
# nobody did: `docs/sum/` did not exist in any repo and all 34 links in the
# published Peace 2025 report were dead. See template#231.
#
# Sourced from `index.Rmd` and gated on `params$update_html_map_tables`, the
# same shape as `update_bcfishpass`: flip the switch to regenerate, otherwise
# the committed pages are used as they stand. The underlying culvert and
# modelling data change rarely, so regenerating on every build would rewrite
# hundreds of files to no purpose.
#
# The output is committed. That is the point - `docs/` is what GitHub Pages
# serves, so a page that exists only on the machine that built it is a dead
# link for every reader.
#
# Sourced after 0130, and builds a page for exactly the sites the map links to -
# the union of `tab_map_phase_1` and `tab_map_phase_2`. It previously read an
# object called `pscis_all`, which nothing in the reporting chain creates; it
# exists only in `scripts/tutorials/road_tenure.Rmd`. So this script could not
# run at all, which is the other half of why `docs/sum/` never existed.
#
# Keying off the map objects rather than a wider site list also means the set of
# pages and the set of links cannot drift apart.

if (!exists("params") || is.null(params$update_html_map_tables)) {
  stop("params$update_html_map_tables must be set in index.Rmd. Example: update_html_map_tables: FALSE")
}

if (isTRUE(params$update_html_map_tables)) {

  # Clear before rebuilding so ids that no longer exist do not linger. Guarded
  # because fs::file_delete() errors on a path that is not there, which meant
  # this script could not run at all from a clean checkout.
  #
  # Note the tradeoff: the pages are committed, so a run that clears these and
  # then fails leaves the working tree worse than it started. `git restore
  # docs/sum` puts it back. Building to a temp directory and swapping would be
  # better, but fpr::fpr_table_bcfp_html() and fpr::fpr_table_cv_html() write to
  # hardcoded docs/sum/ paths, so that needs a change in fpr first.
  reset_dir <- function(path) {
    if (fs::dir_exists(path)) fs::dir_delete(path)
    fs::dir_create(path, recurse = TRUE)
  }

  # Every pscis id the results map emits a link for.
  ids_mapped <- unique(c(
    tab_map_phase_1 |> sf::st_drop_geometry() |> dplyr::pull(pscis_crossing_id),
    tab_map_phase_2 |> sf::st_drop_geometry() |> dplyr::pull(pscis_crossing_id)
  ))
  ids_mapped <- ids_mapped[!is.na(ids_mapped)]

  # fpr::fpr_table_cv_html() takes a site id but reads the site data from a
  # global called `pscis_all` - an undeclared dependency, which is why this
  # script failed even once the id list was fixed. fpr::fpr_import_pscis_all()
  # is not the answer here: it reads the PSCIS template workbooks, which for
  # this season carry 10 rows and a single non-NA id. The report's own
  # `form_pscis` is the populated source and carries every column the detailed
  # culvert table uses, so bind it to the name fpr expects.
  pscis_all <- form_pscis |> sf::st_drop_geometry()

  # bcfishpass HTML to link from map ----------------------------------------
  reset_dir("docs/sum/bcfp")

  bcfishpass |>
    sf::st_drop_geometry() |>
    # Sites with no bcfishpass info are excluded so purrr::map does not bail
    dplyr::filter(stream_crossing_id %in% ids_mapped) |>
    dplyr::pull(stream_crossing_id) |>
    purrr::map(fpr::fpr_table_bcfp_html, scroll = FALSE)

  # culvert HTML to link from map -------------------------------------------
  reset_dir("docs/sum/cv")

  # Be sure to run options(knitr.kable.XXX = '--') in the setup chunk of index.Rmd first
  purrr::map(ids_mapped, fpr::fpr_table_cv_html)

  message("html map tables rebuilt: ",
          length(fs::dir_ls("docs/sum/bcfp")), " model, ",
          length(fs::dir_ls("docs/sum/cv")), " culvert")

} else {
  message("html map tables: using committed docs/sum/ (set update_html_map_tables: TRUE to rebuild)")
}

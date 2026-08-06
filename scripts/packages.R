# A session started by Rscript has no repository set (`@CRAN@`), which makes
# install.packages() and available.packages() below fail outright. RStudio sets a
# mirror for you, so this only ever bites headless builds.
if (!nzchar(getOption("repos")[[1]]) || identical(unname(getOption("repos")[[1]]), "@CRAN@")) {
  options(repos = c(CRAN = "https://cloud.r-project.org"))
}

# Several scripts source this file BEFORE they define `params` - see
# 01_prep_inputs/0220_fish_data_tidy.R, which sources on line 2 and reads the
# report front matter on line 7. Read it defensively so that still works.
update_packages <- isTRUE(tryCatch(params$update_packages, error = function(e) FALSE))

# ensure pak is installed, and up to date from CRAN when we are already updating
if (!requireNamespace("pak", quietly = TRUE)) {
  install.packages("pak")
} else if (update_packages) {
  # available.packages() is a network round trip, and it used to run on every
  # source() of this file rather than only when updating.
  current <- packageVersion("pak")
  latest <- package_version(available.packages()["pak", "Version"])
  if (current < latest) {
    pak::pak("pak")  # uses pak to update itself = no popup
  }
}

pkgs_cran <- c(
  'tidyverse',
  'knitr',
  'bookdown',
  'rmarkdown',
  'pagedown',
  'RPostgres',
  'sf',
  "kableExtra",
  "leafem",
  "leaflet",
  "pdftools",
  # reads data/snapshots/*.parquet in the Assessment Data Summary appendix, so
  # the report builds from a fresh clone with no database connection
  "arrow",
  # site maps - scripts/02_reporting/0420-map-site.R
  "tmap",
  "terra",
  "maptiles",
  "png",
  "stars",
  # popupTable()/popupImage() on the interactive maps - 0400-results.Rmd
  "leafpop",
  # as.english()/ordinal() in inline prose - 0400-results.Rmd, site appendices
  "english",
  # bc_bound() - 0740-appendix-uav-imagery.Rmd
  "bcmaps"
)

pkgs_gh <- c(
  "newgraphenvironment/fpr",
  "newgraphenvironment/ngr",
  # site maps - gq carries the symbology registry, flooded the DEM fetch,
  # fresh the AOI clip
  "newgraphenvironment/gq",
  "newgraphenvironment/fresh",
  "newgraphenvironment/flooded",
  # climate departure appendix - 0710-appendix-climate-departure.Rmd
  "newgraphenvironment/cd",
  "newgraphenvironment/staticimports",
  "newgraphenvironment/fishbc@updated_data",
  "poissonconsulting/readwritesqlite", #https://github.com/poissonconsulting/readwritesqlite/issues/47
  "paleolimbot/rbbt"
)

pkgs_all <- c(pkgs_cran,
              pkgs_gh)


# install or upgrade all the packages with pak
if (update_packages) {
  lapply(pkgs_all, pak::pkg_install, ask = FALSE)
}

# load all the packages
# Strip @branch suffix before basename - see #150
pkgs_ld <- c(pkgs_cran,
             basename(pkgs_gh) |> stringr::str_remove("@.*"))

lapply(pkgs_ld,
       require,
       character.only = TRUE)

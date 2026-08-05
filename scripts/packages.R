# ensure pak is installed and up to date from CRAN
if (!requireNamespace("pak", quietly = TRUE)) {
  install.packages("pak")
} else {
  # Only run this if an update is needed
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
  "stars"
)

pkgs_gh <- c(
  "newgraphenvironment/fpr",
  "newgraphenvironment/ngr",
  # site maps - gq carries the symbology registry, flooded the DEM fetch,
  # fresh the AOI clip
  "newgraphenvironment/gq",
  "newgraphenvironment/fresh",
  "newgraphenvironment/flooded",
  "newgraphenvironment/staticimports",
  "newgraphenvironment/fishbc@updated_data",
  "poissonconsulting/readwritesqlite", #https://github.com/poissonconsulting/readwritesqlite/issues/47
  "paleolimbot/rbbt"
)

pkgs_all <- c(pkgs_cran,
              pkgs_gh)


# install or upgrade all the packages with pak
# install or upgrade all the packages with pak
if(params$update_packages){
  lapply(pkgs_all, pak::pkg_install, ask = FALSE)
}

# load all the packages
# Strip @branch suffix before basename - see #150
pkgs_ld <- c(pkgs_cran,
             basename(pkgs_gh) |> stringr::str_remove("@.*"))

lapply(pkgs_ld,
       require,
       character.only = TRUE)

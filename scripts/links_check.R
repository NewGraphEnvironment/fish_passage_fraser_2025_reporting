# Check that links in the rendered report actually resolve.
#
# Three dead-link defects reached published reports and were only found by
# someone clicking: photo links built from the wrong id, the sum/cv + sum/bcfp
# popup pages never being generated, and the eDNA map never being committed.
# Each had a different cause; what they shared is that nothing said so. The
# report rendered fine, the page looked right, and the link only failed for a
# reader - on the published site, not on the machine that built it.
#
# So the test here is not "does the file exist on this machine" but "is it in
# the repository", because that is what GitHub Pages serves. An untracked file
# is the eDNA-map failure exactly: present locally, absent for everyone else.
#
# Usage (from repo root):
#   Rscript scripts/links_check.R          # repo-internal links only, no network
#   Rscript scripts/links_check.R --external   # also HEAD external URLs (slow)
#
# Exits non-zero if anything is broken, so it can gate a build.

suppressMessages({
  library(dplyr)
})

check_external <- "--external" %in% commandArgs(trailingOnly = TRUE)

dir_docs <- "docs"
if (!dir.exists(dir_docs)) stop("no ", dir_docs, "/ - build the book first", call. = FALSE)

params    <- rmarkdown::yaml_front_matter("index.Rmd")$params
repo_name <- params$repo_name

# Everything git knows about, as a lookup. Membership in this set is the test.
tracked <- system2("git", c("ls-files"), stdout = TRUE)
tracked <- unique(tracked)

pages <- list.files(dir_docs, pattern = "[.]html$", recursive = TRUE, full.names = TRUE)
message("checking ", length(pages), " rendered pages")

# --- collect every href/src ------------------------------------------------
#
# Two passes, because the DOM is not enough. Leaflet popups are serialised as
# JSON inside a <script> tag, so their links are never parsed as attributes -
# and those popups are precisely where the dead photo and sum/ links live. A
# DOM-only check reports this report as almost clean while 49 links are broken.
#
# The raw pass also has to cope with how the popup markup is written:
# `paste0('<a href =', 'sum/cv/', id, '.html ', 'target="_blank">')` produces
# `href =sum/cv/203597.html ` - a space after `=`, and no quotes.
harvest_dom <- function(page) {
  doc <- tryCatch(xml2::read_html(page), error = function(e) NULL)
  if (is.null(doc)) return(NULL)
  vals <- xml2::xml_text(xml2::xml_find_all(doc, "//@href | //@src"))
  if (!length(vals)) return(NULL)
  tibble::tibble(page = page, link = vals)
}

harvest_raw <- function(page) {
  txt <- paste(readLines(page, warn = FALSE), collapse = "\n")
  # PCRE lookbehind must be fixed width and `href *= *` is not, so match the
  # attribute name too and strip it afterwards.
  href_hits <- unlist(regmatches(
    txt, gregexpr('href *= *\\\\?["\']?[^"\'<>\\\\ ]+', txt, perl = TRUE)))
  href_hits <- sub('^href *= *\\\\?["\']?', "", href_hits)

  hits <- c(
    href_hits,
    # any raw.githubusercontent url, wherever it appears
    unlist(regmatches(txt, gregexpr('https://raw\\.githubusercontent\\.com/[^"\'<>\\\\ )]+', txt, perl = TRUE)))
  )
  if (!length(hits)) return(NULL)
  # keep things that look like a file or a directory, not JS expressions
  hits <- hits[grepl("[.][A-Za-z0-9]{2,5}$|/$", hits)]
  if (!length(hits)) return(NULL)
  tibble::tibble(page = page, link = hits)
}

harvest <- function(page) dplyr::bind_rows(harvest_dom(page), harvest_raw(page))

links <- purrr::map_dfr(pages, harvest) |>
  distinct(page, link) |>
  # anchors, mail, js and data URIs are not files
  filter(!grepl("^(#|mailto:|javascript:|data:|tel:)", link), nzchar(link)) |>
  # strip fragment and query - they are not part of the path on disk
  mutate(path_part = sub("[#?].*$", "", link)) |>
  filter(nzchar(path_part))

# --- classify --------------------------------------------------------------
#
# raw.githubusercontent links into THIS repo are resolvable offline: they map
# to a path in this working tree. That is the photo-link failure, and it should
# not need a network round trip to catch.
raw_prefix <- paste0("https://raw.githubusercontent.com/NewGraphEnvironment/", repo_name, "/")

links <- links |>
  mutate(
    kind = case_when(
      startsWith(path_part, raw_prefix)      ~ "repo_raw",
      grepl("^[a-zA-Z][a-zA-Z0-9+.-]*://", path_part) ~ "external",
      startsWith(path_part, "/")             ~ "site_absolute",
      TRUE                                   ~ "relative"
    )
  )

# Map each repo-internal link to the file it claims to be.
to_repo_path <- function(kind, path_part, page) {
  if (kind == "repo_raw") {
    # .../<repo>/<branch>/<path in repo>
    rest <- sub(raw_prefix, "", path_part, fixed = TRUE)
    return(sub("^[^/]+/", "", rest))           # drop the branch segment
  }
  if (kind == "site_absolute") {
    return(file.path(dir_docs, sub("^/", "", path_part)))
  }
  # relative to the page it appears on
  fs::path_norm(file.path(dirname(page), path_part))
}

internal <- links |>
  filter(kind %in% c("repo_raw", "relative", "site_absolute")) |>
  mutate(
    repo_path = purrr::pmap_chr(list(kind, path_part, page), to_repo_path),
    repo_path = utils::URLdecode(repo_path),
    exists_on_disk = file.exists(repo_path) | dir.exists(repo_path),
    in_git         = repo_path %in% tracked
  )

# A directory link (trailing slash, or a dir with index.html) is fine.
internal <- internal |>
  mutate(
    ok = exists_on_disk & (in_git | dir.exists(repo_path))
  )

broken <- internal |> filter(!ok)

# --- report ----------------------------------------------------------------
report <- function(df, title) {
  if (!nrow(df)) return(invisible(NULL))
  message("\n", title, " (", nrow(df), ")")
  df |>
    mutate(where = sub(paste0("^", dir_docs, "/"), "", page)) |>
    count(link, reason, name = "pages") |>
    arrange(desc(pages)) |>
    purrr::pwalk(function(link, reason, pages) {
      message(sprintf("  %-6s %s   [%s, on %d page%s]",
                      "", link, reason, pages, ifelse(pages == 1, "", "s")))
    })
}

broken <- broken |>
  mutate(reason = case_when(
    !exists_on_disk ~ "file does not exist",
    !in_git         ~ "exists locally but is NOT tracked by git - absent on the published site",
    TRUE            ~ "unknown"
  ))

n_ext <- sum(links$kind == "external")
message(sprintf("links: %d internal, %d external%s",
                nrow(internal), n_ext,
                if (check_external) "" else " (external not checked - pass --external)"))

report(broken, "BROKEN")

# --- optional external pass ------------------------------------------------
ext_broken <- tibble::tibble()
if (check_external) {
  ext <- links |> filter(kind == "external") |> distinct(path_part)
  message("\nchecking ", nrow(ext), " external urls ...")
  codes <- vapply(ext$path_part, function(u) {
    out <- suppressWarnings(system2("curl", c("-s", "-o", "/dev/null", "-w", "%{http_code}",
                                              "-L", "--max-time", "20", shQuote(u)),
                                    stdout = TRUE))
    suppressWarnings(as.integer(out[1])) %||% 0L
  }, integer(1))
  ext_broken <- ext |> mutate(code = codes) |> filter(is.na(code) | code >= 400)
  if (nrow(ext_broken)) {
    message("\nEXTERNAL BROKEN (", nrow(ext_broken), ")")
    purrr::pwalk(ext_broken, function(path_part, code) message(sprintf("  HTTP %s  %s", code, path_part)))
  }
}

n_bad <- nrow(broken) + nrow(ext_broken)
if (n_bad > 0) {
  message("\n", n_bad, " broken link(s)")
  quit(save = "no", status = 1)
}
message("\nall links resolve")

# Site maps ported from the template (#23, #19) — v0.5.0

Three of the four site appendices had shipped without a map since the report began. `lfpr_map_site()`
and its prep script were built under template#219 **for these exact four Fraser sites**, landed in
`fish_passage_template_reporting`, and never came back — the template-to-report half of the drift the
branch-into-repo workflow produces. This port brought them home and, at the same time, fixed the UAV
appendix that had been publishing the Peace region's imagery under a Fraser heading for three releases.

The port itself was small because the pieces already fit: `0410`'s `map_units` list was already this
repo's four units, the caches were built with `species = bt` against this repo's `model_species`, and
`wshds` / `habitat_confirmation_tracks` / `pscis_assessment_svw` already satisfied `0420`, so `0110` and
`0120` were untouched. The one step that mattered was the `index.Rmd` source line — the step the
parallel Skeena port skipped, without which every map chunk errors on `lfpr_map_site` not found.

**Three things were found wrong and corrected on the record rather than quietly:**

1. **The issue's own diagnosis.** It claimed broken images, citing 404s under `fig/gis/`. Those 404s
   proved nothing — the chunks were `eval = F`, so no image was ever requested. Readers actually saw a
   dead `(Figure ??)` followed by the source of the disabled chunk echoed into the page. Issue retitled
   and rewritten, with a comment recording the change.
2. **The weight, understated by half.** ~45 MB net, not ~21 MB — rendered figures are committed twice
   because `output_dir: "docs"` makes the published book a tracked artifact. That makes tracked `docs/`
   a larger lever than the map caches if this repo ever needs a diet. Recorded on #1.
3. **A false build verification.** "PDF 16.1 MB, builds clean" reached a commit message from a check
   that had raced the build and measured the previous artifact. `pgrep -f 'Rscript foo.R'` can never
   match, because Rscript execs as `R --file=foo.R`. Wait on the artifact, not the process name — see
   `findings.md`.

**Outcome:** v0.5.0, tagged and deployed. All four appendices draw a generated map, live and verified;
no broken cross-references anywhere in the rendered output; `project_uav` holds this region's 15 assets.
Merged as PR #25 (`f8c0000`), with a follow-up `e552c4d` removing the orphaned JPEG copy under `docs/`
that the release had missed — found by checking the live URL rather than the local tree.

**Left open, both filed upstream:**

- template#226 — South Yuzkli's cached basemap stops short of the frame, leaving a ragged edge and
  0.14 % bare white. Measured identical in the template's own render, so inherited with the caches. The
  fixed 10 % tile pad in `0410` does not cover the Albers rotation at the smallest extent.
- template#225 — the UAV region is a bucket vocabulary, not `params$project_region`. It agrees for
  Fraser and Skeena and does not for Peace, whose imagery is filed under `mackenzie`, so the fix applied
  here would silently empty that report.

Also still open: **skeena#9**, which has the scripts and sidecars but not the `index.Rmd` source line,
the caches, or the map chunks. This branch is the recipe for it; Skeena's remaining half needs the
database tunnel because its caches have never been generated.

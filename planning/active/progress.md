# Progress — Submit the 2025 habitat confirmation data to the Province (FDS) (#26)

## Session 2026-08-05

- Plan-mode exploration across three repos (Fraser target, template, Peace reference) —
  phases approved by user
- Established the port source is Peace `origin/main`, not template v0.15.0 as the issue
  says; the template is a generation behind (no workbook writer, no `has_fish`, no header
  block, no TWC refresh)
- Established Fraser has 11 sites and **zero** `_ef` sites, so the unconditional
  `stopifnot(sum(is_ef(...)) > 0)` will abort — the pooled all-regions backup misleads here
- Verified the template's DFO header label matches `^DFO` uniquely, so `XR 463 2025` lands
  with no code change
- Fast-forwarded `fish_passage_peace_2025_reporting` 41 commits to `a70f0dc`
- Created branch `26-submit-2025-habitat-confirmation-data-fds` off Fraser `main`
- Scaffolded PWF baseline from issue #26 with approved phases
- Next: Phase 2 — port the FDS workflow from Peace

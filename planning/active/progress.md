# Progress — sync the results-map link fixes to Fraser (template#234)

## Session 2026-08-26

- Explored Fraser against the template's fixed state; four findings changed the plan (see findings.md), two of which would have caused damage if Peace's fix had been copied unchanged
- **Phase 1 complete** — archived the #26 FDS PWF, recording that the provincial submission and the `WL25-993485` nil return are still outstanding; issue #26 left open. Branch `234-sync-results-map-link-fixes` created
- Next: Phase 2, port the fix set from the template

- **Phases 2–4 complete.** Ported the fix set, generated and committed 32 `docs/sum/` pages, removed the two genuine orphans (left `attach-bayes.html`, a live chapter here). **49 → 3.** All three artifacts rebuilt; released 0.7.0. Commits `5cf1981`, and the release commit following.
- `rbbt` could not reach Zotero for the bib refresh — this shell is headless (no login keychain, no TTY), the trap CLAUDE.md records. Built with `update_bib: FALSE` and **restored it to TRUE** before committing, since no citations changed. Skeena's build earlier in this session *did* refresh, so this is a property of whether the app is running, not of the repo.
- Remaining 3 are the UAV parquet urls — Phase 5, filed separately.

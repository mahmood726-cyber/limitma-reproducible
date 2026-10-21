# Equivalence of the archived page files with allmeta v1.8.0

allmeta v1.8.0: tag `v1.8.0`, commit `1cb3f8409c7af75ed41f7e1811f9c502f900fc79`, DOI 10.5281/zenodo.23515177.
The primary page was validated at commit `e431057` (PR #117, on top of the corrections `4a053dd`, PR #115). The two
1.1.0 tiers were copied from `9b232cc` (branch feat/limitma-leave-one-out-limit). All three commits are ancestors of v1.8.0.
Version 1.1.0 of this archive re-pins every snapshot file to its v1.8.0 bytes (`git cat-file blob 1cb3f84:<path>`, no newline
conversion) and repeats the app-side capture and replays on those bytes.

## Snapshot comparison

330 snapshot files represent allmeta paths: 293 under `app/` (inventoried in `app/app-sha256.json`; the archive-authored
`app-sha256.json`, `request-assets.json` and `optional-missing-requests.json` are not allmeta files) and 37 under
`v1_1/allmeta/` (listed in `v1_1/PROVENANCE.json`). `app/allmeta-LICENSE` and `app/allmeta-README.md` represent allmeta
`LICENSE` and `README.md`.

- 237 were byte-identical to v1.8.0 (204 in `app/`, 33 in `v1_1/`). No snapshot file is absent from v1.8.0.
- 78 differed only in line endings: the archived `app/` copy was taken from a Windows working tree (CRLF), while git
  stores LF. Removing CR from the archived bytes gives the v1.8.0 blob exactly. They are listed at the end; all now carry
  the v1.8.0 (LF) bytes. NON-ENGINE.
- 15 differed in content. Each diff is `git diff e431057 1cb3f84 -- <path>` (for `app/`) or
  `git diff 9b232cc 1cb3f84 -- <path>` (for `v1_1/`):

| File | Difference from v1.8.0 | Class |
|---|---|---|
| `app/limit-ma/index.html` | v1.6.0-v1.8.0 page: Run button, analysis-lifecycle notices and plot selector; bias-sensitivity panel (`#alm-plus`) and leave-one-out panel; strict input parser that refuses malformed rows with line numbers instead of dropping them; numeric axis ticks on the funnel plot; one-click BCG example | ENGINE (parser feeds the fit; new estimators in the page) |
| `app/limit-ma/validate/adapter.js` | in-page Validate adapter excludes the new `#alm-plus` panel from the primary DOM contract | NON-ENGINE (validation harness; no result computed) |
| `app/shared/alm-validate.js` | Validate panel: fails closed on unknown comparison kinds/invalid tolerances, stricter accounting, relabelled buttons and status text, R version display | NON-ENGINE (validation panel) |
| `app/hub/shared/chart-download.js` | loads the vendored jsPDF lazily for PDF export | NON-ENGINE (export) |
| `app/hub/shared/csv-upload.js` | optional app-supplied parser hook; default parser unchanged and limit-ma passes none | NON-ENGINE |
| `app/hub/shared/results-export.js` | export-bar CSS gains `flex-wrap:wrap;max-width:100%` | NON-ENGINE (layout) |
| `app/shared/build-info.js` | v1.8.0 build stamp (version, sha, build time) | NON-ENGINE (display) |
| `app/shared/canonical-datasets.js` | adds `toEffectSeLabelText` for the one-click example | NON-ENGINE (example input loader) |
| `app/shared/hero-examples.js` | adds the `effect-se-label` example adapter | NON-ENGINE (example input loader) |
| `app/allmeta-README.md` | allmeta README gains a paragraph on the screen workflow suite | NON-ENGINE (docs) |
| `app/limit-ma/validate/README.md` | button name in the text (Replay published corpus) | NON-ENGINE (docs) |
| `v1_1/allmeta/limit-ma/index.html` | strict input parser (as above), funnel axis ticks, refusal clears the plus/diagnostic text, `window.__almLimitParse`, one-click example adapter | ENGINE (parser) |
| `v1_1/allmeta/shared/ma-core.js` | FE model: I-squared now Q-based (`max(0,100(Q-df)/Q)`) instead of tau-squared based | ENGINE |
| `v1_1/allmeta/shared/alm-validate.js` | R version display string | NON-ENGINE (display) |
| `v1_1/allmeta/limit-ma/validate/loo/README.md` | kept: the archive's portable copy with machine paths replaced by placeholders (`PROVENANCE.json` `substitutions`); undoing them gives the v1.8.0 blob exactly (its git blob is unchanged since 9b232cc) | not replaced (documented portable fixture) |

The archive's own `app/limit-ma/index.html` blob is the same at the earlier re-cut candidate e61378c and at v1.8.0. After
e61378c, v1.8.0 changed two shared files that limit-ma loads (`<script>` tags in `limit-ma/index.html`):
`hub/shared/results-export.js` (export-bar CSS only: NON-ENGINE) and `hub/shared/analysis-lifecycle.js` (when the
"results are stale" notice is shown after a change event that only commits already-run inputs; it still returns
the wrapped run's result unchanged: NON-ENGINE).

The v1.8.0 page loads 16 files that the v1 snapshot did not contain. They were added at their v1.8.0 bytes
(found by logging every request of the page in Chrome; with them the page loads with no missing request and no page error):

| Added file | SHA-256 |
|---|---|
| `app/hub/shared/plot-export.js` | `c8423a5ead0fdf213a7798eee68245407e4e4a95f0b25c83b020b57ba4c1d0f1` |
| `app/hub/shared/analysis-lifecycle.js` | `e8a5ff3fd7908469013e17a881083def5451f30a075f34584db8b9c086652afa` |
| `app/shared/ma-core.js` | `ec80f783258b3d49eaa6cabdd19bb794ddeead3db891602f694861188a303058` |
| `app/shared/trimfill.js` | `887cd6ccba1b33addcebdb788cabc7c6eee540128393dedaf4db1e650e2425ac` |
| `app/shared/selmodel.js` | `a220342e16b8b23f6eb75f41b3262470044a8283ab3cc77cf731e8077b91e343` |
| `app/limit-ma/plus-opt.js` | `7bc638d767e5beb7b84140d9f01ded510b5f58d2249855e0d7838223854720f7` |
| `app/limit-ma/loo-limit.js` | `df6a91a2ff86db682d75effbe5c404382517e30f6bacb65e28bba69ae20ac089` |
| `app/limit-ma/plus-selmodel.js` | `28b493e7d9b25a401ce0be1d540f41b562c8d3d101074dbf7673cce659b8c60d` |
| `app/limit-ma/plus.js` | `20f34a929183a5e7cdb34262d8c63634f345094bd9fe04aa1b8cf775c51f8bd6` |
| `app/limit-ma/plus-ui.js` | `70f969793a1130a1f1d6e54452d48ae30f51f46112ee012aae766cbe3b5f83b6` |
| `app/limit-ma/validate/plus-pins.js` | `7231af78c28335223a69466ba25d9b042c0d32fb1c0a070806e9fc427fac5b94` |
| `app/limit-ma/validate/plus-adapter.js` | `45dfc3190d3997961d004180594243c5a60306f2995148b907744fa127950a8a` |
| `app/limit-ma/validate/MANIFEST-plus.json` | `4a0888e71b19e8c01e010076412a98443e7161c241e2395e4cadf13c603742e3` |
| `app/limit-ma/validate/plus/corpus.json` | `bf68cae8b7f7ae93ed6d5621851858346908c47bc7d1480111bb7485af4f03ca` |
| `app/limit-ma/validate/plus/reference.json` | `e4caaee58963a1fe4535c1f7ae681aa6d2277018a28dcfdb90ee7eeaec999df7` |
| `app/hub/shared/vendor/jspdf.min.js` | `98ccf17aa10c20bb1301762618fcc9b6ab3a4e7f26b6071d64d0b41154df3875` |

ENGINE files changed, so equivalence rests on the execution check below, not on the byte comparison.

## Check by execution

21 Oct 2026, Windows, Node v24.13.0, Chrome 156.0.8078.47, Playwright from the allmeta test tree.

1. Primary page capture. `bench/run-app.cjs` (run from `data/` as `node ../bench/run-app.cjs ../app <out>`) was run on
   the re-pinned `app/` (v1.8.0 bytes and the 16 added files). It reported 169 app configurations, 169 valid, 0 refused,
   0 page errors. The capture has SHA-256 `c093633fb122af2923702b97d0329477a0d099afc490ba2a3b79b0e3704e9eda` and is
   **byte-identical** to the archived `results/app-patched.json`. (Control: the same run on the archived e431057 bytes
   gave the same SHA-256.) Every comparison in `validate.R` and `analysis/` that reads this capture, including
   55,524/55,525 with the one documented R non-convergence, therefore applies unchanged to v1.8.0.
2. Leave-one-out tier. `node v1_1/run/loo_replay_compare.cjs v1_1/allmeta` on the v1.8.0 bytes:
   `LOO NODE REPLAY 31514/31514 checks; 5304/5304 rows; 156 refused (manifest 31514)`, i.e. **31,514/31,514**, equal to
   the archived count.
3. Bias-sensitivity tier. `node v1_1/run/plus_replay.cjs v1_1/allmeta` on the v1.8.0 bytes:
   `PLUS NODE REPLAY 15928/15928 numerical/status/refusal checks (manifest 16097 = 15928 + 169 render)`, i.e.
   **15,928/15,928**, equal to the archived count.
4. Browser suite of the 1.1.0 tiers (README-plus command; Playwright 1.59.1, Chrome 156, `PW_CHANNEL=chrome`), run in a tree of
   `limit-ma/`, `shared/`, `hub/` (and, for the two parity specs, `funnel-plot/` and `pubbias-tests/`) extracted from 1cb3f84.
   The tree's `limit-ma/` and `shared/` files are the same bytes as `app/` above. Because one call of the tool is limited to 10 minutes,
   the 141 tests were run in parts (`file:line` selections):
   - `limit-ma-plus.spec.mjs`: all 95 tests passed, including the in-page sensitivity replay `LIMIT PLUS 16097/16097 failed 0`
     (15,928 numerical/status/refusal + 169 rendering checks; axis coverage 500/507 checked), 72 mutation detectors, and every
     geometry, paint, style and label mutation test with `missed: []`.
   - `validate-limit-ma.spec.mjs`: 16/16 passed; in-page primary replay `LIMIT CORPUS 55524/55525`, each of the 11 table mutations
     detected in 168 configurations.
   - `trimfill-parity.spec.mjs`, `selmodel-parity.spec.mjs`: 5/5 passed (`SELMODEL EXACT 169 configurations; two contexts; 3380 scalar comparisons`).
   - `validate-integration.spec.mjs`: the 2 limit-ma tests passed. Its other 23 tests concern other allmeta pages, which this archive
     does not contain; they were not run.
The R reference tiers were not re-run: the R references do not depend on the app.

## Line-ending-only files (78)

- `app/allmeta-LICENSE`
- `app/hub/app-style.css`
- `app/hub/shared/a11y-landmarks.js`
- `app/hub/shared/axis-controls.js`
- `app/hub/shared/glossary.json`
- `app/hub/shared/reset-undo.js`
- `app/hub/shared/tooltips.js`
- `app/hub/shared/url-state.js`
- `app/r-shiny/shinylive/webr/R.js`
- `app/r-shiny/shinylive/webr/R.js.bak`
- `app/r-shiny/shinylive/webr/esbuild.d.ts`
- `app/r-shiny/shinylive/webr/library.js.metadata`
- `app/r-shiny/shinylive/webr/repo/bin/emscripten/contrib/4.5/PACKAGES`
- `app/r-shiny/shinylive/webr/repo/upstream-manifest.json`
- `app/r-shiny/shinylive/webr/vfs/etc/fonts/fonts.conf`
- `app/r-shiny/shinylive/webr/vfs/etc/ssl/cert.pem`
- `app/r-shiny/shinylive/webr/vfs/usr/lib/R/doc.js.metadata`
- `app/r-shiny/shinylive/webr/vfs/usr/lib/R/library/base/demo.js.metadata`
- `app/r-shiny/shinylive/webr/vfs/usr/lib/R/library/base/help.js.metadata`
- `app/r-shiny/shinylive/webr/vfs/usr/lib/R/library/base/html.js.metadata`
- `app/r-shiny/shinylive/webr/vfs/usr/lib/R/library/compiler/help.js.metadata`
- `app/r-shiny/shinylive/webr/vfs/usr/lib/R/library/compiler/html.js.metadata`
- `app/r-shiny/shinylive/webr/vfs/usr/lib/R/library/datasets/help.js.metadata`
- `app/r-shiny/shinylive/webr/vfs/usr/lib/R/library/datasets/html.js.metadata`
- `app/r-shiny/shinylive/webr/vfs/usr/lib/R/library/grDevices/afm.js.metadata`
- `app/r-shiny/shinylive/webr/vfs/usr/lib/R/library/grDevices/demo.js.metadata`
- `app/r-shiny/shinylive/webr/vfs/usr/lib/R/library/grDevices/enc.js.metadata`
- `app/r-shiny/shinylive/webr/vfs/usr/lib/R/library/grDevices/fonts.js.metadata`
- `app/r-shiny/shinylive/webr/vfs/usr/lib/R/library/grDevices/help.js.metadata`
- `app/r-shiny/shinylive/webr/vfs/usr/lib/R/library/grDevices/html.js.metadata`
- `app/r-shiny/shinylive/webr/vfs/usr/lib/R/library/grDevices/libs.js.metadata`
- `app/r-shiny/shinylive/webr/vfs/usr/lib/R/library/graphics/demo.js.metadata`
- `app/r-shiny/shinylive/webr/vfs/usr/lib/R/library/graphics/help.js.metadata`
- `app/r-shiny/shinylive/webr/vfs/usr/lib/R/library/graphics/html.js.metadata`
- `app/r-shiny/shinylive/webr/vfs/usr/lib/R/library/grid/doc.js.metadata`
- `app/r-shiny/shinylive/webr/vfs/usr/lib/R/library/grid/help.js.metadata`
- `app/r-shiny/shinylive/webr/vfs/usr/lib/R/library/grid/html.js.metadata`
- `app/r-shiny/shinylive/webr/vfs/usr/lib/R/library/methods/help.js.metadata`
- `app/r-shiny/shinylive/webr/vfs/usr/lib/R/library/methods/html.js.metadata`
- `app/r-shiny/shinylive/webr/vfs/usr/lib/R/library/parallel.js.metadata`
- `app/r-shiny/shinylive/webr/vfs/usr/lib/R/library/splines/help.js.metadata`
- `app/r-shiny/shinylive/webr/vfs/usr/lib/R/library/splines/html.js.metadata`
- `app/r-shiny/shinylive/webr/vfs/usr/lib/R/library/stats/demo.js.metadata`
- `app/r-shiny/shinylive/webr/vfs/usr/lib/R/library/stats/doc.js.metadata`
- `app/r-shiny/shinylive/webr/vfs/usr/lib/R/library/stats/help.js.metadata`
- `app/r-shiny/shinylive/webr/vfs/usr/lib/R/library/stats/html.js.metadata`
- `app/r-shiny/shinylive/webr/vfs/usr/lib/R/library/stats4/help.js.metadata`
- `app/r-shiny/shinylive/webr/vfs/usr/lib/R/library/stats4/html.js.metadata`
- `app/r-shiny/shinylive/webr/vfs/usr/lib/R/library/tcltk.js.metadata`
- `app/r-shiny/shinylive/webr/vfs/usr/lib/R/library/tools/help.js.metadata`
- `app/r-shiny/shinylive/webr/vfs/usr/lib/R/library/tools/html.js.metadata`
- `app/r-shiny/shinylive/webr/vfs/usr/lib/R/library/translations.js.metadata`
- `app/r-shiny/shinylive/webr/vfs/usr/lib/R/library/translations/DESCRIPTION`
- `app/r-shiny/shinylive/webr/vfs/usr/lib/R/library/utils/doc.js.metadata`
- `app/r-shiny/shinylive/webr/vfs/usr/lib/R/library/utils/help.js.metadata`
- `app/r-shiny/shinylive/webr/vfs/usr/lib/R/library/utils/html.js.metadata`
- `app/r-shiny/shinylive/webr/vfs/usr/lib/R/library/utils/misc.js.metadata`
- `app/r-shiny/shinylive/webr/vfs/usr/lib/R/library/webr/help.js.metadata`
- `app/r-shiny/shinylive/webr/vfs/usr/lib/R/library/webr/html.js.metadata`
- `app/r-shiny/shinylive/webr/vfs/usr/lib/R/share.js.metadata`
- `app/r-shiny/shinylive/webr/vfs/usr/share/gdal.js.metadata`
- `app/r-shiny/shinylive/webr/vfs/usr/share/proj.js.metadata`
- `app/r-shiny/shinylive/webr/vfs/usr/share/udunits.js.metadata`
- `app/r-shiny/shinylive/webr/vfs/var/cache/fontconfig/CACHEDIR.TAG`
- `app/r-shiny/shinylive/webr/webr-worker.js`
- `app/r-shiny/shinylive/webr/webr-worker.js.map`
- `app/r-shiny/shinylive/webr/webr.cjs`
- `app/r-shiny/shinylive/webr/webr.cjs.map`
- `app/r-shiny/shinylive/webr/webr.mjs`
- `app/r-shiny/shinylive/webr/webr.mjs.map`
- `app/shared/app-flow.js`
- `app/shared/autosave.js`
- `app/shared/citation.js`
- `app/shared/forced-colors.css`
- `app/shared/ma-studies-v1.js`
- `app/shared/truthcert-export.js`
- `app/shared/truthcert-ui.js`
- `app/shared/webr-runner.js`

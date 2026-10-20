# Limit meta-analysis in the browser: validation against the R package metasens

This archive validates the allmeta limit meta-analysis page, source **4a053dd (PR #115)**, with the validation button added in **e431057 (PR #117)**; both commits are in allmeta v1.4.0 (https://doi.org/10.5281/zenodo.23404527). It contains the full primary comparison: **55,524 of 55,525 checks pass; 1 documented R non-convergence**. It is not a complete primary-oracle pass or a release certification.

## Reproduce

With **R 4.6.0, meta 8.5-0, metasens 1.5-3, metadat 1.6-0, metafor 5.2-1**, plus jsonlite and digest installed, run from this directory:

```sh
Rscript validate.R
python analysis/make_outputs.py
python analysis/verify_archive.py
python analysis/test_safeguards.py
```

The Python outputs require matplotlib and Pillow. No command downloads packages. Set `R_LIBS_USER` to the installed paper-package library (or semicolon-separated libraries on Windows). The validator prepends it to `.libPaths()`, prints the paths and loaded versions, and fails loudly on a mismatch. A user `.Renviron` can override the environment; set `R_ENVIRON_USER` to an empty file if needed. No machine-specific path is required. The command runtime and actual command results are recorded in the parent REPORT.md.

`validate.R` checks SHA-256 of its complete input set, requires unique identifiers and exact coverage, refits **every configuration**, and computes every R quantity including the independent clipped-curve oracle from the round-6 reference. It compares against the archived page output, prints a per-quantity table and `55524/55525 checks pass`, writes `outputs/validate_R_table.csv`, and reports `55,524/55,525 pass; 1 documented, 0 unexpected`. A changed/disappearing refusal, unexpected failure, wrong versions or coverage mismatch exits nonzero. Table rendering and the app's SVG coordinates are archived browser evidence in this command; no browser is launched. All R statistical values and R curve coordinates are freshly recomputed.

To use the archived page, serve `app/` with a local HTTP server and open `limit-ma/index.html`. The button compares current inputs using bundled webR 0.5.5, **meta 8.3-0 / metasens 1.5-3**, and displays the paper versions alongside. Its full replay uses the page's own code on all configurations with the pinned R corpus, without URL or history writes. Nothing is fetched from an external origin. File mode supports selecting the two corpus files for offline replay. Live R requires HTTP(S).

## Evidence and scope

The corpus builder programmatically enumerated package documentation and stored effect/variance columns. It retains at least three finite effects with strictly positive finite variances; identical vectors within a dataset are deduplicated. It yields **169 configurations, 113 datasets, 9852 effect rows** (rows reused across definitions are counted repeatedly). `data/corpus.json` records definitions, aliases, source and omitted rows. `data/coverage.json`, `inventory.json`, `construction-attempts.json`, and `bench/documentation/` preserve decisions and exclusions. `dat.metap` contains p-values without suitable effect/variance data and is excluded. Source-row positions are not trial or bibliographic identifiers. Network, longitudinal and multilevel examples test arithmetic while ignoring dependence; these are not clinical pooled analyses.

Reference calls are `meta::metagen(TE,seTE,method.tau='DL',method.random.ci='classic',level=.95,level.ma=.95,method.tau.ci='')` and `metasens::limitmeta(m,method.adjust='beta0')`. The contract covers FE/RE/limit estimates, SEs, normal CIs, tau/tau-squared, alpha.r/beta.r/slope, Q/Q.small/Q.resid/G-squared, every shrunken study estimate, table rendering, study points and the visible clipped regression curve. Numerical tolerance is **1e-9 relative to max(1,abs(R))**. Status and cardinality checks also appear in the denominator. Missing, invalid or duplicate evidence is never treated as undefined; explicit null G-squared is permitted only for a genuinely undefined diagnostic.

Only **DL + beta0** is validated. No p-values are displayed or compared; R p-values are reference-only metadata. There is no alternative model selector. Plotting-only changes do not alter estimates.

## Corrections and remaining refusal

The original page passed **44,772/55,525** checks; the corrected page passes **55,524/55,525**. The historical before total uses `results/reference-before.json` (source `reference.json.round5`); the final after total uses `results/reference.json` with round-6 clipped visible-curve probes. Both denominators contain the same quantities and counts, but the curve probe positions differ. Comparing the old app geometry to the final clipped reference instead gives 43,876/55,525; that is not the historical before result. The regression curve had used `limit + beta.r * SE`; it now renders `beta.r + alpha.r * sqrt(SE² + tau²)` and clips the sampled curve. The patch also honors the SE-axis minimum, disables unsupported log-axis controls, clears stale output on insufficient input and rejects singular equal-SE input. The core statistical estimates were unchanged. `bench/fix.patch` and the before/after UI evidence preserve these corrections.

`dat.hartmannboyce2018::001` remains a failed status comparison. R raises `Fisher scoring algorithm did not converge. See 'help(rma)' for possible remedies.` during metasens' internal REML fit of shrunken data, despite the main metagen model using DL. The app returns finite results. A separate global-DL diagnostic passes **158/158** export checks; this is diagnostic only and never replaces the primary refusal. `expected/documented_differences.json` keys the exact reason and phase.

## Layout and provenance

- `app/`: byte-identical page, loaded assets, full webR runtime and dependency archives; `app-sha256.json` inventories bytes.
- `bench/`: original run scripts and documentation, with machine paths replaced by placeholders. These historical scripts expect the original flat run layout; use root `validate.R` for one-command validation.
- `data/`, `results/`: source inputs and historical R/browser results, including the diagnostic refusal run.
- `analysis/`, `expected/`: strict comparison, negative safeguards, figures and fixed paper contract.
- `outputs/`: two tables, PNG/TIFF figure pairs, sizes, source-backed numbers and reproduction report.
- `INPUT_SHA256.json` pins validator inputs; `SOURCE_SHA256.json` pins the complete source inventory. The verifier supports a later `.git` directory. Refresh source hashes after filling the explicit commit placeholder, then verify again.

| Component | Static | Dynamic/source-backed |
|---|---|---|
| Model contract | DL, beta0, normal 95% CI, 1e-9 tolerance | All estimates and diagnostics from R/page computation |
| Corpus | Archived package data and documented construction rules | Enumerated rows, dimensions and coverage checks |
| Figures and tables | Sizes, typography, expected cardinalities | Strict comparison of real archived outputs |
| Refusal | Exact keyed reason from source run | Fresh R must reproduce it; no invented app refusal |
| Browser validation | Pinned reference and package binaries | Current page outputs, live R, comparisons and verdicts |

MIT licensed. Derived from [allmeta](https://github.com/mahmood726-cyber/allmeta) and allmeta v1.4.0, DOI **10.5281/zenodo.23404527**. No new archive DOI is claimed.

## Layer 1.1.0 (local; not released) [ARCHIVE DOI: limitma-reproducible v1.1.0 — pending release]

Version 1.1.0 adds `v1_1/` and leaves every v1 file, count and denominator above unchanged (only `validate.R` gains a
hook at its end, and the metadata/verifier carry the new version). Two tiers that the paper cites but v1 lacked are
copied byte-exactly from allmeta commit 9b232cc (branch feat/limitma-leave-one-out-limit); `v1_1/PROVENANCE.json`
lists commit, path and SHA-256 of all 37 copied files (one README has machine paths replaced by placeholders; the
check undoes them and requires the git-blob SHA-256).

- **Leave-one-out limit estimate** (`v1_1/allmeta/limit-ma/validate/loo/`): 165 configurations (4 <= k <= 200),
  5,304 deletions, 156 of them refused by R exactly as by the page. metasens 1.5.3 `limitmeta()` has no subset or
  influence argument and meta 8.5.0 `metainf()` does not accept a `limitmeta` object; R composes the same analysis in
  a short `metagen`/`limitmeta` loop (`generate.R`), which is the reference. 31,514 checks.
- **Bias-sensitivity panel** of allmeta v1.7.0 (`v1_1/allmeta/limit-ma/validate/plus/`, files identical at 9b232cc
  except one button label): RE, limit, trim-and-fill, PET, PEESE, conditional PET-PEESE, 3PSM, Egger, Peters,
  Q-small/Q-resid, shift, G² against meta 8.5.0, metasens 1.5.3, metafor 5.2.1. 16,097 checks = 15,928
  numerical/status/refusal checks + 169 per-configuration rendering checks (DOM text, SVG geometry, computed styles).

`Rscript validate.R` now runs v1 and then `v1_1/validate_v1_1.R` in a fresh R process. With
`ARCHIVE_V1_1_ONLY=1` it runs only the v1 input preflight and the 1.1.0 layer. The layer, failing closed:
1. asserts R 4.6.0, meta 8.5.0, metasens 1.5.3, metafor 5.2.1, metadat 1.6.0, jsonlite 2.0.0, node >= 18, and
   sets/prints LC_COLLATE and LC_CTYPE (English_United States.utf8);
2. checks the SHA-256 of every copied file and of the tiers' own pins (the LOO MANIFEST pins `corpus.json` in its
   CRLF form while git stores LF; only that exact LF->CRLF equivalence is accepted);
3. regenerates **both R references in full** with the tiers' own unchanged generators and compares them with the
   stored ones: LOO `generate.R` -> 5,304/5,304 rows, file byte-identical; plus `generate-plus.R`,
   `generate-peters.R`, `generate-peters-or.R` -> 46,821/46,821 stored values (every R reference value
   bit-identical; the regenerated input corpus is jsonlite's 15-digit re-serialisation, equal within 4.9e-15);
4. replays the page engine in node as the LOO tier's own `replay.cjs` does: LOO **31,514/31,514**; plus
   **15,928/15,928** (`v1_1/run/plus_replay.cjs`, helpers taken verbatim from `plus-adapter.js`). The 169 rendering
   checks need a browser; they are taken from the archived browser run `plus/evidence-replay.json` (16,097/16,097)
   and are labelled as archived, not recomputed.

Runtime of the 1.1.0 layer on the reference desktop: about 31 minutes (LOO regeneration 20 min, plus regeneration
10 min, node replays 1 min). `ARCHIVE_V1_1_PLANT=loo|plus|loo-rref|plus-rref` plants one defect (an app estimate or
a stored R value moved by 1e-8 relative) and runs only the targeted stage; each such run exits nonzero.
Tolerances are the tiers' own (1e-9 relative to max(1,|R|); selection model 1e-6 / 1e-4 for SE and CI).

# Limit meta-analysis in the browser: validation against the R package metasens

This archive validates the allmeta limit meta-analysis page, source **4a053dd (PR #115)**, with the validation button added in **e431057 (PR #117)**; both commits are in allmeta v1.4.0. It contains the full primary comparison: **55,524 of 55,525 checks pass; 1 documented R non-convergence**. It is not a complete primary-oracle pass or a release certification.

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

MIT licensed. Derived from [allmeta](https://github.com/mahmood726-cyber/allmeta) and allmeta v1.3.0, DOI **10.5281/zenodo.23330389**. No new archive DOI is claimed.

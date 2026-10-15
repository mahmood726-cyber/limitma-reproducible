# Limit meta-analysis validation

Verdict: **NOT A COMPLETE PRIMARY-ORACLE PASS**. The audit and local patch are complete; this is not a release certification.

Source commit: `bdf777fb074804e09de59ac63db55f0ad90b2241`. Original files were copied read-only, hashed in `source-manifest.json`, and executed as a complete page in installed Chrome. Only the copies in this folder were changed. No network installation or external data retrieval was used.

Runtime: R version 4.6.0 (2026-04-24 ucrt); meta 8.5.0; metasens 1.5.3; metafor 5.2.1; metadat 1.6.0; jsonlite 2.0.0. Package version dots are the normalized R packageVersion representation (meta 8.5-0, metasens 1.5-3).

## Scope and reference

The actual page fixes the method to DL heterogeneity and `method.adjust="beta0"`; it has no alternative statistical-method selector. Its table shows fixed-effect, DL random-effects, and limit estimates, SEs, and normal 95% CIs. Its result export additionally exposes tau/tau², alpha.r, beta.r (also aliased as slope), Q, Q.small, Q.resid, G², and the vector of shrunken study estimates. The plotted points are effect versus raw SE. There is no displayed radial plot and no displayed/exported p-value; R p-values are retained as reference-only metadata and are not counted as app checks.

`reference.R` calls `meta::metagen(te, se, method.tau="DL", method.random.ci="classic", level=.95, level.ma=.95, method.tau.ci="")` followed by `metasens::limitmeta(m, method.adjust="beta0")`. Every comparison uses the page itself through its input, Fit button, export hook, table DOM, and SVG. No numerical app method was reimplemented in the runner.

All numerical checks use `abs(app-reference)/max(1,abs(reference)) <= 1e-9`. These are closed-form calculations; no iterative tolerance was substituted. Integer lengths, coverage, and status are also checked. Both sides must explicitly refuse for a refusal match. Invalid or missing evidence never passes. `verify.py` tests missing configurations, duplicate keys, null estimates, and missing study vectors.

## Corpus and exclusions

Package-provided illustrative examples retain their package provenance; this audit does not claim every metadat dataset represents an independent clinical study.

Programmatic enumeration found 114 datasets. 113 datasets contribute 169 unique configurations and 9852 input effect rows across configurations (rows reused across definitions are counted repeatedly). Only datasets/configurations with at least three finite effects and strictly positive finite variances enter the app corpus.

The builder evaluates documented effect-size preparations, captures `escalc` and documented `meta` conversions, and uses stored effect/variance columns. R settings reset before each dataset. The recorded definitions are the original documentation expressions; the builder explicitly uses inverse-variance per-study conversion for metabin/metaprop and DL without a tau CI during input construction, rather than reproducing unrelated example pooling methods. Repeated preparations producing the same vector within a dataset are deduplicated and their definitions retained in `aliases`. Different transformed outcomes/variance definitions remain separate when their vectors differ. Rma subgroup/moderator fits are not separate method configurations; the full available effect vector is used. Network, longitudinal, and multilevel datasets are numerical test vectors, not clinical pooled analyses: dependence and differing treatment contrasts are not modelled by this app.

Explicit additional transformations are disclosed in each corpus definition: Fisher-z correlations for craft2003; logit arm proportions for roever2022/ursino2021; per-occasion stored estimates for ishak2007; stored nonstandard columns for bakdash2021/maire2019; documented wide contrasts for lopez2019; and an MD from observed recurrence means/SDs/sample sizes for huber2000. These are computed from package data, never invented outputs. `source_rows` indexes rows of the prepared effect table, not validated bibliographic or trial identifiers.

`corpus.json` records each key, construction, exact input, retained-row positions, and omitted-row positions. `construction-attempts.json` records every attempted captured vector, including insufficient-k exclusions and invalid-row omissions. `coverage.json` contains dataset-level decisions and all preparation warnings/errors. Messages from skipped model/graph dependencies do not imply missing effect vectors; successful constructions are retained separately. No dataset is excluded merely because R later refuses its model. R warnings are preserved per configuration in `reference.json`, including perfect-fit radial-regression warnings. The documented besson2016 conversion warns about unusually large SMDs; this numerical parity audit does not certify the underlying research data.

| Dataset | Configurations | Decision / reason |
|---|---:|---|
| `dat.aloe2013` | 3 | used: stored or documented effect-size definition |
| `dat.anand1999` | 1 | used: stored or documented effect-size definition |
| `dat.anker2025` | 4 | used: stored or documented effect-size definition |
| `dat.assink2016` | 1 | used: stored or documented effect-size definition |
| `dat.axfors2021` | 1 | used: stored or documented effect-size definition |
| `dat.bakdash2021` | 1 | used: stored or documented effect-size definition |
| `dat.baker2009` | 1 | used: stored or documented effect-size definition |
| `dat.bangertdrowns2004` | 1 | used: stored or documented effect-size definition |
| `dat.bartos2023` | 4 | used: stored or documented effect-size definition |
| `dat.baskerville2012` | 1 | used: stored or documented effect-size definition |
| `dat.bassler2004` | 1 | used: stored or documented effect-size definition |
| `dat.bauer2002` | 2 | used: stored or documented effect-size definition |
| `dat.bcg` | 1 | used: stored or documented effect-size definition |
| `dat.begg1989` | 2 | used: stored or documented effect-size definition |
| `dat.berkey1998` | 1 | used: stored or documented effect-size definition |
| `dat.berkey1998r` | 1 | used: stored or documented effect-size definition |
| `dat.besson2016` | 1 | used: stored or documented effect-size definition |
| `dat.bonett2010` | 3 | used: stored or documented effect-size definition |
| `dat.bornmann2007` | 1 | used: stored or documented effect-size definition |
| `dat.bourassa1996` | 1 | used: stored or documented effect-size definition |
| `dat.cannon2006` | 1 | used: stored or documented effect-size definition |
| `dat.chiarito2020` | 2 | used: stored or documented effect-size definition |
| `dat.cohen1981` | 1 | used: stored or documented effect-size definition |
| `dat.colditz1994` | 1 | used: stored or documented effect-size definition |
| `dat.collins1985a` | 3 | used: stored or documented effect-size definition |
| `dat.collins1985b` | 5 | used: stored or documented effect-size definition |
| `dat.craft2003` | 1 | used: stored or documented effect-size definition |
| `dat.crede2010` | 1 | used: stored or documented effect-size definition |
| `dat.crisafulli2020` | 1 | used: stored or documented effect-size definition |
| `dat.curtin2002` | 1 | used: stored or documented effect-size definition |
| `dat.curtis1998` | 1 | used: stored or documented effect-size definition |
| `dat.dagostino1998` | 2 | used: stored or documented effect-size definition |
| `dat.damico2009` | 1 | used: stored or documented effect-size definition |
| `dat.debruin2009` | 1 | used: stored or documented effect-size definition |
| `dat.demir2022` | 1 | used: stored or documented effect-size definition |
| `dat.dogliotti2014` | 1 | used: stored or documented effect-size definition |
| `dat.dong2013` | 1 | used: stored or documented effect-size definition |
| `dat.dorn2007` | 2 | used: stored or documented effect-size definition |
| `dat.dumouchel1994` | 1 | used: stored or documented effect-size definition |
| `dat.egger2001` | 1 | used: stored or documented effect-size definition |
| `dat.feng2019` | 1 | used: stored or documented effect-size definition |
| `dat.fine1993` | 1 | used: stored or documented effect-size definition |
| `dat.franchini2012` | 1 | used: stored or documented effect-size definition |
| `dat.frank2008` | 4 | used: stored or documented effect-size definition |
| `dat.furukawa2003` | 1 | used: stored or documented effect-size definition |
| `dat.gibson2002` | 3 | used: stored or documented effect-size definition |
| `dat.graves2010` | 1 | used: stored or documented effect-size definition |
| `dat.greb2008` | 1 | used: stored or documented effect-size definition |
| `dat.greenland1992` | 1 | used: stored or documented effect-size definition |
| `dat.gurusamy2011` | 1 | used: stored or documented effect-size definition |
| `dat.hackshaw1998` | 1 | used: stored or documented effect-size definition |
| `dat.hahn2001` | 1 | used: stored or documented effect-size definition |
| `dat.hannum2020` | 3 | used: stored or documented effect-size definition |
| `dat.hart1999` | 2 | used: stored or documented effect-size definition |
| `dat.hartmannboyce2018` | 1 | used: stored or documented effect-size definition |
| `dat.hasselblad1998` | 2 | used: stored or documented effect-size definition |
| `dat.higgins2008` | 1 | used: stored or documented effect-size definition |
| `dat.hine1989` | 1 | used: stored or documented effect-size definition |
| `dat.huber2000` | 1 | used: stored or documented effect-size definition |
| `dat.ishak2007` | 4 | used: stored or documented effect-size definition |
| `dat.kalaian1996` | 1 | used: stored or documented effect-size definition |
| `dat.karner2014` | 2 | used: stored or documented effect-size definition |
| `dat.kearon1998` | 4 | used: stored or documented effect-size definition |
| `dat.knapp2017` | 1 | used: stored or documented effect-size definition |
| `dat.konstantopoulos2011` | 1 | used: stored or documented effect-size definition |
| `dat.landenberger2005` | 1 | used: stored or documented effect-size definition |
| `dat.laopaiboon2015` | 1 | used: stored or documented effect-size definition |
| `dat.lau1992` | 1 | used: stored or documented effect-size definition |
| `dat.lee2004` | 1 | used: stored or documented effect-size definition |
| `dat.lehmann2018` | 3 | used: stored or documented effect-size definition |
| `dat.li2007` | 1 | used: stored or documented effect-size definition |
| `dat.lim2014` | 1 | used: stored or documented effect-size definition |
| `dat.linde2005` | 1 | used: stored or documented effect-size definition |
| `dat.linde2015` | 2 | used: stored or documented effect-size definition |
| `dat.linde2016` | 1 | used: stored or documented effect-size definition |
| `dat.lloyd2010` | 2 | used: stored or documented effect-size definition |
| `dat.lopez2019` | 1 | used: stored or documented effect-size definition |
| `dat.maire2019` | 1 | used: stored or documented effect-size definition |
| `dat.mccurdy2020` | 1 | used: stored or documented effect-size definition |
| `dat.mcdaniel1994` | 2 | used: stored or documented effect-size definition |
| `dat.meeker2017` | 1 | used: stored or documented effect-size definition |
| `dat.metap` | 0 | excluded: p-value collections; no effect sizes with sampling variances or raw outcome summaries for escalc |
| `dat.michael2013` | 2 | used: stored or documented effect-size definition |
| `dat.molloy2014` | 1 | used: stored or documented effect-size definition |
| `dat.moore1998` | 1 | used: stored or documented effect-size definition |
| `dat.moura2021` | 1 | used: stored or documented effect-size definition |
| `dat.nakagawa2007` | 1 | used: stored or documented effect-size definition |
| `dat.nielweise2007` | 1 | used: stored or documented effect-size definition |
| `dat.nielweise2008` | 1 | used: stored or documented effect-size definition |
| `dat.nissen2007` | 4 | used: stored or documented effect-size definition |
| `dat.normand1999` | 2 | used: stored or documented effect-size definition |
| `dat.obrien2003` | 2 | used: stored or documented effect-size definition |
| `dat.pagliaro1992` | 2 | used: stored or documented effect-size definition |
| `dat.pignon2000` | 1 | used: stored or documented effect-size definition |
| `dat.poole2003` | 1 | used: stored or documented effect-size definition |
| `dat.pritz1997` | 4 | used: stored or documented effect-size definition |
| `dat.quan2000` | 1 | used: stored or documented effect-size definition |
| `dat.raudenbush1985` | 1 | used: stored or documented effect-size definition |
| `dat.riley2003` | 1 | used: stored or documented effect-size definition |
| `dat.rivera2025` | 3 | used: stored or documented effect-size definition |
| `dat.roever2022` | 1 | used: stored or documented effect-size definition |
| `dat.senn2013` | 2 | used: stored or documented effect-size definition |
| `dat.spooner2002` | 1 | used: stored or documented effect-size definition |
| `dat.steurer2006` | 2 | used: stored or documented effect-size definition |
| `dat.stowe2010` | 1 | used: stored or documented effect-size definition |
| `dat.tannersmith2016` | 1 | used: stored or documented effect-size definition |
| `dat.thompson1999` | 1 | used: stored or documented effect-size definition |
| `dat.tian2009` | 1 | used: stored or documented effect-size definition |
| `dat.ursino2021` | 1 | used: stored or documented effect-size definition |
| `dat.vanhowe1999` | 1 | used: stored or documented effect-size definition |
| `dat.viechtbauer2021` | 1 | used: stored or documented effect-size definition |
| `dat.white2020` | 1 | used: stored or documented effect-size definition |
| `dat.woods2010` | 1 | used: stored or documented effect-size definition |
| `dat.yusuf1985` | 1 | used: stored or documented effect-size definition |

## Defects and patch

1. `limit-ma/index.html:346` used `limit + beta.r * SE` for the funnel regression. Radial regression instead implies `TE = beta.r + alpha.r * sqrt(SE² + tau²)`. The patch draws this curve at 65 vertices. Its zero-SE endpoint is the beta0 limit. The original curve fails away from its shared endpoint; the patched vertices are checked against R-derived coordinates.
2. `limit-ma/index.html:336` ignored the supplied SE-axis minimum. The patch maps `(SE - min)/(max - min)` and draws the curve over that range.
3. `limit-ma/index.html:437` exposed log toggles without implementing log transforms. The local page now disables those controls and explains their unsupported status; linear ranges remain available.
4. `limit-ma/index.html:269` cleared only the result object on insufficient input, leaving old table/plot evidence visible. `radialReg` at line 203 also divided by zero for equal SEs. The patch clears stale output, displays a refusal reason, rejects equal-SE singular inputs, and guards all exported numerical fields against nonfinite output.

`fix.patch` is a unified diff against the source repository. `patched/` is the tested copy; `original/` preserves source bytes. `verify.py` applies the patch to another local copy and requires byte equality with the tested HTML. Core numerical formulas were not changed.

The orientation tests (`limit-ma/tests/test_against_metasens.py`) describe an older simplified WLS method and include a Python reimplementation with a 0.15 adjusted-estimate tolerance. They do not execute this shipped page and were not counted as parity evidence. The patch also corrects the header’s “Stat Med 2011” to Biostatistics, consistent with the existing footer citation.

## Primary-oracle results

| Quantity | Original pass/checks | Patched pass/checks | Original max difference | Patched max difference | Tolerance |
|---|---:|---:|---:|---:|---:|
| status | 168/169 | 168/169 | 1 | 1 | 1e-09 |
| k | 168/168 | 168/168 | 0 | 0 | 1e-09 |
| fe_est | 168/168 | 168/168 | 8.8817841970012523e-16 | 8.8817841970012523e-16 | 1e-09 |
| fe_se | 168/168 | 168/168 | 1.1102230246251565e-16 | 1.1102230246251565e-16 | 1e-09 |
| fe_ci_lo | 168/168 | 168/168 | 8.8817841970012523e-16 | 8.8817841970012523e-16 | 1e-09 |
| fe_ci_hi | 168/168 | 168/168 | 9.9920072216264089e-16 | 9.9920072216264089e-16 | 1e-09 |
| re_est | 168/168 | 168/168 | 1.2212453270876722e-15 | 1.2212453270876722e-15 | 1e-09 |
| re_se | 168/168 | 168/168 | 3.4649139111754116e-16 | 3.4649139111754116e-16 | 1e-09 |
| re_ci_lo | 168/168 | 168/168 | 1.4432899320127035e-15 | 1.4432899320127035e-15 | 1e-09 |
| re_ci_hi | 168/168 | 168/168 | 1.2212453270876722e-15 | 1.2212453270876722e-15 | 1e-09 |
| tau2_dl | 168/168 | 168/168 | 5.8286708792820718e-16 | 5.8286708792820718e-16 | 1e-09 |
| tau_dl | 168/168 | 168/168 | 9.4368957093138306e-16 | 9.4368957093138306e-16 | 1e-09 |
| limit_est | 168/168 | 168/168 | 1.3322676295501878e-14 | 1.3322676295501878e-14 | 1e-09 |
| limit_se | 168/168 | 168/168 | 5.848760364912664e-11 | 5.848760364912664e-11 | 1e-09 |
| limit_ci_lo | 168/168 | 168/168 | 1.1463685556378778e-10 | 1.1463685556378778e-10 | 1e-09 |
| limit_ci_hi | 168/168 | 168/168 | 8.5576256316566389e-11 | 8.5576256316566389e-11 | 1e-09 |
| slope | 168/168 | 168/168 | 2.8238576142339278e-13 | 2.8238576142339278e-13 | 1e-09 |
| alpha_r | 168/168 | 168/168 | 2.9231884581736527e-13 | 2.9231884581736527e-13 | 1e-09 |
| beta_r | 168/168 | 168/168 | 2.8238576142339278e-13 | 2.8238576142339278e-13 | 1e-09 |
| Q | 168/168 | 168/168 | 8.8920317279713506e-16 | 8.8920317279713506e-16 | 1e-09 |
| Q_small | 168/168 | 168/168 | 4.3765543376046455e-13 | 4.3765543376046455e-13 | 1e-09 |
| Q_resid | 168/168 | 168/168 | 9.0878099886778727e-15 | 9.0878099886778727e-15 | 1e-09 |
| G_squared | 168/168 | 168/168 | 3.219646771412954e-15 | 3.219646771412954e-15 | 1e-09 |
| te_limit_length | 168/168 | 168/168 | 0 | 0 | 1e-09 |
| te_limit | 9716/9716 | 9716/9716 | 6.488249565738745e-14 | 6.488249565738745e-14 | 1e-09 |
| table_render | 168/168 | 168/168 | 0 | 0 | 1e-09 |
| points_length | 168/168 | 168/168 | 0 | 0 | 1e-09 |
| points_x | 9716/9716 | 9716/9716 | 2.0301221021717147e-15 | 2.0301221021717147e-15 | 1e-09 |
| points_y | 9716/9716 | 9716/9716 | 2.2204460492503131e-16 | 2.2204460492503131e-16 | 1e-09 |
| regression_length | 168/168 | 168/168 | 0 | 0 | 1e-09 |
| regression_x | 168/10920 | 10920/10920 | 188.01108480884906 | 8.5816256965497363e-14 | 1e-09 |
| regression_y | 10920/10920 | 10920/10920 | 0 | 2.1899686221900418e-16 | 1e-09 |

Maxima are over finite numerical comparisons; a nonfinite/missing value is still a failure. Refused reference configurations contribute a status check, not fabricated numerical checks. `baseline-results.json` and `patched-results.json` retain every failing key and quantity.

Verbatim final comparison lines:

```text
44772/55525 checks pass
55524/55525 checks pass
```

## Refusals and diagnostic rerun

- `dat.hartmannboyce2018::001`: reference refused during limitmeta beta0 (including internal metagen call); app ok. R reason: Fisher scoring algorithm did not converge. See 'help(rma)' for possible remedies.

The primary refusal remains a failed status comparison. In metasens, the internal `m.lim <- metagen(TE.limit, seTE.limit, ...)` uses the global default REML even though the supplied main model uses DL. That extra heterogeneity fit is not used for the exported beta0 quantities, but it can fail before the reference returns. No dataset-specific app refusal was added to imitate this R optimizer failure.

Separately, `dat.hartmannboyce2018::001` under a global DL setting for that internal fit: 158/158 numerical export checks pass. This is diagnostic evidence only, saved in `reference-diagnostic.json`; it does not replace or convert the original refusal into a pass.

## UI and integrity verification

The default fixture and explicit two-study/equal-SE robustness probes are separate from the package-data corpus. Their inputs are visible in `test-ui.cjs`; they are not presented as research datasets.

```text
2/7 UI checks pass (original)
7/7 UI checks pass (patched)
```

`verification.json` records exact inventory/coverage agreement, valid input dimensions, unchanged source hashes, patch application, browser errors, and damaged-evidence rejection.

## Reproduction

Set `R_LIBS_USER` to the provided task library, `EXTRA_R_LIB` to the installed local library containing metasens/jsonlite, and `PLAYWRIGHT_MODULE` to the task’s installed Playwright module. For a new source snapshot, set `ALLMETA_SOURCE` to the task’s read-only source checkout. All output paths are relative to this folder.

```powershell
python setup.py $env:ALLMETA_SOURCE
Rscript inspect.R
python run_all.py
python verify.py
python report.py
```

The executed orchestration consists of `Rscript build.R`, `Rscript reference.R`, `node run-app.cjs original app.json`, `python compare.py app.json baseline`, `python make-patch.py`, `node run-app.cjs patched app-patched.json`, `python compare.py app-patched.json patched`, and both `node test-ui.cjs` runs. Comparators exit nonzero for failed checks; run_all preserves those results for this audit rather than declaring them green. R/browser/comparison output is saved in the corresponding `.log` files. JSON numbers are emitted using `sprintf("%.17g")`.

## Hardcode disclosure

| Component | Static | Dynamic/source-backed |
|---|---|---|
| Model | DL, beta0, 95% normal CI, k ≥ 3 from page | All estimated parameters and diagnostics |
| Corpus | Conversion rules and documented column mappings | Enumerated package datasets, effect values, SEs, row omissions |
| Validation | 1e-9 tolerance; exact keys/lengths | R and actual Chrome outputs, pass/failure counts |
| Plot | Page dimensions and 65-point display grid | Study coordinates and R-derived fitted curve |
| Robustness tests | Explicit synthetic small/singular inputs, clearly separated | Actual page responses |

No source repository, project registry, workbook, remote, or deployment was modified.

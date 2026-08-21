---
aliases: [Code index, Scripts]
tags: [code, generated, moc]
---

# Code index

Every script in `R/`, mirrored here so it is readable inside Obsidian with syntax highlighting. The scripts themselves remain the source of truth.

> [!info] Generated
> Produced by `R/make-code-notes.R`. Edit the scripts, not these notes.

| Script | What it does | Lines | Concept note |
|---|---|---|---|
| [[code-_seats\|`_seats.R`]] | The SEATS canonical decomposition, from scratch. | 195 | — |
| [[code-_series\|`_series.R`]] | The standard test series for this vault. | 53 | — |
| [[code-_setup\|`_setup.R`]] | Shared helpers. source() this at the top of every script. | 61 | — |
| [[code-_spectral\|`_spectral.R`]] | Frequency-domain helpers. source() after _setup.R. | 64 | — |
| [[code-_x11\|`_x11.R`]] | X-11 building blocks, hand-coded. source() after _setup.R. | 189 | — |
| [[code-00-series-catalogue\|`00-series-catalogue.R`]] | 00 -- The test series, and what each one breaks. | 67 | — |
| [[code-10-01-lag-operator\|`10-01-lag-operator.R`]] | The lag operator B is just algebra. | 35 | [[10-01-lag-operator]] |
| [[code-10-02-stationarity-and-roots\|`10-02-stationarity-and-roots.R`]] | Stationarity is a statement about polynomial roots. | 46 | [[10-02-stationarity-and-roots]] |
| [[code-10-03-ar-processes\|`10-03-ar-processes.R`]] | AR processes: infinite echo. | 51 | [[10-03-ar-processes]] |
| [[code-10-04-ma-processes\|`10-04-ma-processes.R`]] | MA processes: finite memory, and the non-uniqueness of theta. | 52 | [[10-04-ma-processes]] |
| [[code-10-05-invertibility\|`10-05-invertibility.R`]] | Invertibility, pi-weights, and the unit MA root. | 62 | [[10-05-invertibility]] |
| [[code-10-06-differencing\|`10-06-differencing.R`]] | Differencing: logs first, then (1-B) and (1-B^12). | 81 | [[10-06-differencing]] |
| [[code-10-07-acf-and-pacf\|`10-07-acf-and-pacf.R`]] | Identification from ACF and PACF. | 49 | [[10-07-acf-and-pacf]] |
| [[code-10-08-arma-duality\|`10-08-arma-duality.R`]] | Psi-weights, pi-weights, and common factors. | 43 | [[10-08-arma-duality]] |
| [[code-10-09-seasonal-arima\|`10-09-seasonal-arima.R`]] | Multiplicative seasonal ARIMA: four polynomials. | 55 | [[10-09-seasonal-arima]] |
| [[code-10-10-airline-model\|`10-10-airline-model.R`]] | The airline model on real data. | 72 | [[10-10-airline-model]] |
| [[code-10-11-sign-conventions\|`10-11-sign-conventions.R`]] | Prove the sign convention to yourself. Do not take it on faith. | 34 | [[10-11-sign-conventions]] |
| [[code-10-12-estimation\|`10-12-estimation.R`]] | ML vs CSS, and why outliers wreck an ARIMA fit. | 48 | [[10-12-estimation]] |
| [[code-10-12b-general-estimation\|`10-12b-general-estimation.R`]] | 10-12b -- Exact ML for a GENERAL ARIMA, built from scratch. | 248 | — |
| [[code-10-13-model-selection\|`10-13-model-selection.R`]] | AICC, Ljung-Box done right, residual spectrum. | 52 | [[10-13-model-selection]] |
| [[code-10-14-forecasting\|`10-14-forecasting.R`]] | Forecasting, and the revision experiment that motivates everything. | 67 | [[10-14-forecasting]] |
| [[code-20-01-moving-averages-as-filters\|`20-01-moving-averages-as-filters.R`]] | A moving average is a filter. Gain and phase. | 47 | [[20-01-moving-averages-as-filters]] |
| [[code-20-02-the-12-term-ma\|`20-02-the-12-term-ma.R`]] | The centred 12-term MA: X-11's first move. | 74 | [[20-02-the-12-term-ma]] |
| [[code-20-03-henderson-filters\|`20-03-henderson-filters.R`]] | Henderson filters: derive, verify, and see what they do NOT do. | 86 | [[20-03-henderson-filters]] |
| [[code-20-04-seasonal-moving-averages\|`20-04-seasonal-moving-averages.R`]] | Seasonal MAs: smoothing ACROSS YEARS within a calendar month. | 63 | [[20-04-seasonal-moving-averages]] |
| [[code-20-05-the-x11-iteration\|`20-05-the-x11-iteration.R`]] | Build X-11, check it against the real thing, then recover its filter. | 98 | [[20-05-the-x11-iteration]] |
| [[code-20-06-extreme-values\|`20-06-extreme-values.R`]] | Extreme values: the one nonlinear step. | 70 | [[20-06-extreme-values]] |
| [[code-20-07-end-filters\|`20-07-end-filters.R`]] | End filters: where revisions come from. | 85 | [[20-07-end-filters]] |
| [[code-20-08-x11-arima\|`20-08-x11-arima.R`]] | X-11-ARIMA: extend with forecasts, then filter symmetrically. | 98 | [[20-08-x11-arima]] |
| [[code-30-01-frequency-domain-basics\|`30-01-frequency-domain-basics.R`]] | Frequencies, periods, harmonics, aliasing. | 74 | [[30-01-frequency-domain-basics]] |
| [[code-30-02-spectral-density\|`30-02-spectral-density.R`]] | The spectral density: variance distributed over frequency. | 58 | [[30-02-spectral-density]] |
| [[code-30-03-spectrum-of-an-arma\|`30-03-spectrum-of-an-arma.R`]] | The central formula: f(w) = (sigma^2/2pi) \|theta\|^2 / \|phi\|^2. | 92 | [[30-03-spectrum-of-an-arma]] |
| [[code-30-04-pseudo-spectrum\|`30-04-pseudo-spectrum.R`]] | The pseudo-spectrum: unit roots as infinite peaks. | 110 | [[30-04-pseudo-spectrum]] |
| [[code-30-05-filters-in-the-frequency-domain\|`30-05-filters-in-the-frequency-domain.R`]] | Filtering multiplies the spectrum by the squared gain. | 68 | [[30-05-filters-in-the-frequency-domain]] |
| [[code-30-06-wiener-kolmogorov\|`30-06-wiener-kolmogorov.R`]] | Wiener-Kolmogorov: keep the share of the power that is yours. | 75 | [[30-06-wiener-kolmogorov]] |
| [[code-30-07-finite-samples\|`30-07-finite-samples.R`]] | Applying a doubly-infinite filter to 144 observations. | 87 | [[30-07-finite-samples]] |
| [[code-40-01-unobserved-components-and-reduced-form\|`40-01-unobserved-components-and-reduced-form.R`]] | A structural model has an ARIMA reduced form. SEATS runs it backwards. | 73 | [[40-01-unobserved-components-and-reduced-form]] |
| [[code-40-02-admissible-decompositions\|`40-02-admissible-decompositions.R`]] | Which models can be decomposed at all? | 76 | [[40-02-admissible-decompositions]] |
| [[code-40-03-canonical-decomposition\|`40-03-canonical-decomposition.R`]] | The canonical rule: give the irregular as much variance as possible. | 96 | [[40-03-canonical-decomposition]] |
| [[code-40-04-partial-fractions-in-b-and-f\|`40-04-partial-fractions-in-b-and-f.R`]] | The partial fractions, with numbers. | 93 | [[40-04-partial-fractions-in-b-and-f]] |
| [[code-40-05-component-models\|`40-05-component-models.R`]] | What ARIMA does each component follow? | 84 | [[40-05-component-models]] |
| [[code-40-06-wk-filters-for-the-airline-model\|`40-06-wk-filters-for-the-airline-model.R`]] | The three WK filters: gains, weights, and X-11 side by side. | 88 | [[40-06-wk-filters-for-the-airline-model]] |
| [[code-40-07-implementing-seats-in-r\|`40-07-implementing-seats-in-r.R`]] | The build, walked through, plus the traps that produce plausible output. | 103 | [[40-07-implementing-seats-in-r]] |
| [[code-40-08-validating-against-x13\|`40-08-validating-against-x13.R`]] | Prove it against the Census Bureau binary. | 88 | [[40-08-validating-against-x13]] |
| [[code-50-01-is-there-seasonality\|`50-01-is-there-seasonality.R`]] | Should this series be adjusted at all? | 68 | [[50-01-is-there-seasonality]] |
| [[code-50-02-residual-seasonality\|`50-02-residual-seasonality.R`]] | Did any seasonality survive? | 57 | [[50-02-residual-seasonality]] |
| [[code-50-03-m-and-q-statistics\|`50-03-m-and-q-statistics.R`]] | The M and Q statistics, and their limits. | 58 | [[50-03-m-and-q-statistics]] |
| [[code-50-04-sliding-spans\|`50-04-sliding-spans.R`]] | Sliding spans: is the answer robust to moving the window? | 86 | [[50-04-sliding-spans]] |
| [[code-50-05-revision-history\|`50-05-revision-history.R`]] | Revision history: concurrent vs final. | 69 | [[50-05-revision-history]] |
| [[code-50-06-turning-points\|`50-06-turning-points.R`]] | Adjustment is least reliable exactly when it matters most. | 81 | [[50-06-turning-points]] |
| [[code-50-07-outliers-and-breaks\|`50-07-outliers-and-breaks.R`]] | AO, LS, TC: getting the TYPE right matters as much as the location. | 81 | [[50-07-outliers-and-breaks]] |
| [[code-50-08-covid\|`50-08-covid.R`]] | A COVID-like shock, and the three treatment strategies. | 77 | [[50-08-covid]] |
| [[code-50-09-x11-vs-seats\|`50-09-x11-vs-seats.R`]] | Which method do you publish? | 73 | [[50-09-x11-vs-seats]] |
| [[code-50-10-calendar-effects\|`50-10-calendar-effects.R`]] | Trading day, Easter, and moving holidays that are NOT built in. | 134 | [[50-10-calendar-effects]] |
| [[code-check-numbers\|`check-numbers.R`]] | Guard against stale numbers in the notes. | 193 | — |
| [[code-check-vault\|`check-vault.R`]] | Every staleness check in the vault, one command. | 72 | — |
| [[code-inline\|`inline.R`]] | Run the R snippets embedded in the notes and fill in their output. | 139 | — |
| [[code-make-code-notes\|`make-code-notes.R`]] | Mirror every R/*.R script into a readable note in _code/. | 165 | — |
| [[code-make-figure-index\|`make-figure-index.R`]] | Generate _meta/figure-index.md, the figure appendix. | 143 | — |
| [[code-make-figures\|`make-figures.R`]] | Regenerate every PNG embedded in the notes. | 477 | — |

## Regenerating

```r
setwd("D:/time-series-vault/time-series-vault")
source("R/make-code-notes.R")   # defines the functions
make_code_notes()               # rewrite _code/
check_code_notes()              # or: just report which notes drifted
```

Running the file directly (`Rscript R/make-code-notes.R`) regenerates immediately. Sourcing it interactively only defines the functions, so `check_code_notes()` can actually detect drift instead of silently repairing it first.

Shared helpers `_setup.R` (polynomial and sign-convention utilities) and `_x11.R` (the hand-coded X-11) have no concept note of their own — they are sourced by the others.

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
| [[code-_setup\|`_setup.R`]] | Shared helpers. source() this at the top of every script. | 61 | — |
| [[code-_x11\|`_x11.R`]] | X-11 building blocks, hand-coded. source() after _setup.R. | 165 | — |
| [[code-10-01-lag-operator\|`10-01-lag-operator.R`]] | The lag operator B is just algebra. | 35 | [[10-01-lag-operator]] |
| [[code-10-02-stationarity-and-roots\|`10-02-stationarity-and-roots.R`]] | Stationarity is a statement about polynomial roots. | 46 | [[10-02-stationarity-and-roots]] |
| [[code-10-03-ar-processes\|`10-03-ar-processes.R`]] | AR processes: infinite echo. | 51 | [[10-03-ar-processes]] |
| [[code-10-04-ma-processes\|`10-04-ma-processes.R`]] | MA processes: finite memory, and the non-uniqueness of theta. | 52 | [[10-04-ma-processes]] |
| [[code-10-05-invertibility\|`10-05-invertibility.R`]] | Invertibility, pi-weights, and the unit MA root. | 49 | [[10-05-invertibility]] |
| [[code-10-06-differencing\|`10-06-differencing.R`]] | Differencing: logs first, then (1-B) and (1-B^12). | 54 | [[10-06-differencing]] |
| [[code-10-07-acf-and-pacf\|`10-07-acf-and-pacf.R`]] | Identification from ACF and PACF. | 49 | [[10-07-acf-and-pacf]] |
| [[code-10-08-arma-duality\|`10-08-arma-duality.R`]] | Psi-weights, pi-weights, and common factors. | 43 | [[10-08-arma-duality]] |
| [[code-10-09-seasonal-arima\|`10-09-seasonal-arima.R`]] | Multiplicative seasonal ARIMA: four polynomials. | 55 | [[10-09-seasonal-arima]] |
| [[code-10-10-airline-model\|`10-10-airline-model.R`]] | The airline model on real data. | 48 | [[10-10-airline-model]] |
| [[code-10-11-sign-conventions\|`10-11-sign-conventions.R`]] | Prove the sign convention to yourself. Do not take it on faith. | 34 | [[10-11-sign-conventions]] |
| [[code-10-12-estimation\|`10-12-estimation.R`]] | ML vs CSS, and why outliers wreck an ARIMA fit. | 48 | [[10-12-estimation]] |
| [[code-10-13-model-selection\|`10-13-model-selection.R`]] | AICC, Ljung-Box done right, residual spectrum. | 52 | [[10-13-model-selection]] |
| [[code-10-14-forecasting\|`10-14-forecasting.R`]] | Forecasting, and the revision experiment that motivates everything. | 67 | [[10-14-forecasting]] |
| [[code-make-code-notes\|`make-code-notes.R`]] | Mirror every R/*.R script into a readable note in _code/. | 157 | — |
| [[code-make-figures\|`make-figures.R`]] | Regenerate every PNG embedded in the notes. | 159 | — |

## Regenerating

```r
setwd("D:/time-series-vault/time-series-vault")
source("R/make-code-notes.R")   # defines the functions
make_code_notes()               # rewrite _code/
check_code_notes()              # or: just report which notes drifted
```

Running the file directly (`Rscript R/make-code-notes.R`) regenerates immediately. Sourcing it interactively only defines the functions, so `check_code_notes()` can actually detect drift instead of silently repairing it first.

Shared helpers `_setup.R` (polynomial and sign-convention utilities) and `_x11.R` (the hand-coded X-11) have no concept note of their own — they are sourced by the others.

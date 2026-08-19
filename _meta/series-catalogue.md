---
aliases: [Series catalogue, Test series, Data]
tags: [meta, reference]
---

# The series catalogue

Code: [[code-_series|`R/_series.R`]] · catalogue script: `R/00-series-catalogue.R`

## Why AirPassengers is not enough

`AirPassengers` is the running example because it is short, clean and famous, and because using one series throughout lets the modules stack. But it is **unrepresentative in every direction that matters**:

- no outliers, no level shifts, no breaks
- no trading-day or moving-holiday effects
- seasonality that is strong, stable and smoothly evolving
- a monotone trend with no business-cycle turning points
- parameters comfortably inside the SEATS **admissible region**

So it flatters every method and can never show you a failure. A vault that only ever used it would teach you that seasonal adjustment works, which is the wrong lesson.

Each series below earns its place by exposing something AirPassengers structurally cannot.

## The catalogue

| Series | Freq | n | Auto model | What it is for |
|---|---|---|---|---|
| `AirPassengers` | 12 | 144 | $(0,1,1)(0,1,1)$, log | the clean baseline |
| `nottem` | 12 | 240 | $(1,0,0)(1,1,1)$, **no log** | near-**deterministic** seasonality |
| `co2` | 12 | 468 | $(0,1,1)(0,1,1)$, log | very stable seasonal, long series |
| `USAccDeaths` | 12 | 72 | $(0,1,1)(0,1,1)$, log | how little data can you adjust? |
| `ldeaths`, `mdeaths` | 12 | 72 | $(0,0,1)(0,1,1)$, log | the airline model **over-differences** it |
| `UKgas` | **4** | 108 | $(1,0,1)(0,1,0)$, log | quarterly; an ARMA component |
| `JohnsonJohnson` | **4** | 84 | $(0,1,1)(0,1,1)$, log | quarterly, strong growth |
| `seasonal::unemp` | 12 | — | $(1,1,1)(0,1,1)$, no log | recessions — **turning points** |
| `seasonal::cpi` | 12 | — | fitted $(2,1,1)(1,0,1)$ → **SEATS uses $(1,1,2)(1,0,1)$** | **inadmissible decomposition** |
| `seasonal::imp` | 12 | — | $(0,1,2)(0,1,1)$, log | **Chinese New Year** — a moving holiday |
| `seasonal::iip` | 12 | — | $(0,1,1)(0,1,1)$, log | **Diwali** — a second moving holiday |

## What $\Theta$ says about each

Forcing the airline model on all of them (Census signs) gives a single number per series that predicts how much its seasonal factors will revise — the claim made in [[10-10-airline-model]] and [[20-08-x11-arima]]. Measured:

| Series | $\theta$ | $\Theta$ | Reading |
|---|---|---|---|
| `co2` | 0.360 | **0.912** | very stable seasonal, small revisions |
| `iip` | 0.364 | **0.932** | very stable |
| `nottem` | 0.946 | 0.922 | stable — it is deterministic |
| `unemp` | 0.028 | 0.765 | trend is nearly a pure random walk |
| `AirPassengers` | 0.402 | 0.557 | middling |
| `imp` | 0.562 | 0.498 | middling |
| `JohnsonJohnson` | 0.681 | **0.315** | volatile seasonal, expect big revisions |
| `UKgas` | 0.919 | **0.235** | volatile seasonal |
| `ldeaths` | **1.000** | **1.000** | pinned — the model is wrong |

The spread from 0.235 to 0.932 is the point. AirPassengers sits unremarkably in the middle, so it teaches you nothing about either extreme.

Note `unemp`'s $\theta = 0.028$: a regular MA of essentially zero means the trend is a near-pure random walk. Different series are hard in different ways.

## The three that matter most

### `cpi` — an inadmissible decomposition, live

regARIMA fits $(2,1,1)(1,0,1)$. SEATS then reports:

```text
Model used in SEATS is different: (1 1 2)(1 0 1)
```

SEATS could not decompose the fitted model into non-negative component spectra, so it **substituted a nearby model that it can decompose**. This is the admissibility constraint of [[40-02-admissible-decompositions]] firing on real data, and it is the single most important thing AirPassengers cannot demonstrate.

Practical consequence: the model you fitted and the model your components came from are **not the same model**. Anyone reading SEATS output needs to check for this, and most do not.

### `ldeaths` — the over-differencing diagnostic, vindicated

Force the airline model onto it and both MA coefficients come back pinned at $0.9999$ — the non-invertible boundary of [[10-05-invertibility]].

Left to choose, X-13 picks $(0,0,1)(0,1,1)$: **$d = 0$, no regular differencing at all**. The pinned coefficient was not a numerical quirk; it was the model correctly reporting that the regular difference should not have been taken.

Three independent diagnostics agree, which is what makes this a good worked example:

```text
1. the MA coefficients pin at the boundary        (10-05)
2. AIC prefers the d=0 model     -82.52 vs -81.99 (10-13)
3. the regular difference INCREASES the variance:
     log(ldeaths)            0.0812
     after (1-B^12)          0.0189   <- stop here
     after (1-B)(1-B^12)     0.0349   <- worse
```

This closes the loop between [[10-05-invertibility]], [[10-06-differencing]] and [[10-13-model-selection]] on real data rather than on a simulation.

### `nottem` — seasonality that genuinely is deterministic

Monthly Nottingham temperatures. Seasonality is driven by the Earth's orbit, so it really is fixed — the one case where seasonal dummies are the right model. X-13 picks $(1,0,0)(1,1,1)$ with **no log transform** and no regular differencing.

Useful as the limiting case of the "how much does the seasonal evolve" question that $\Theta$ answers everywhere else. It also breaks the habit of assuming logs.

## Where each is used

| Module | Series | Where | Done |
|---|---|---|---|
| 1 — ARIMA | `ldeaths` | [[10-05-invertibility]], [[10-06-differencing]] — over-differencing, three ways | ✅ |
| 1 — ARIMA | `nottem` | [[10-10-airline-model]] — no logs, deterministic seasonality | ✅ |
| 2 — X-11 | `UKgas`, `JohnsonJohnson` | [[20-02-the-12-term-ma]], [[20-03-henderson-filters]], [[20-05-the-x11-iteration]] — quarterly | ✅ |
| 3 — spectra | `nottem`, `UKgas` | [[30-04-pseudo-spectrum]] — deterministic vs evolving, as peak width | ✅ |
| 4 — SEATS | `cpi` | [[40-02-admissible-decompositions]] — a real inadmissible decomposition | ✅ |
| 5 — diagnostics | `unemp`, `sunspots` | [[50-06-turning-points]], [[50-01-is-there-seasonality]] | ✅ |
| 5 — diagnostics | `imp`, `iip` | moving holidays — mentioned, not yet worked through | ⬜ |

## What the retrofit turned up

Adding quarterly series was not cosmetic. `x11_decompose()` had **hardcoded the monthly 2×12 MA and the monthly Henderson table**, so quarterly data silently ran with the wrong filters. Fixed by generalising to `ma_2xs(s)` and `henderson_length(ic, s)`.

The cost of that class of bug, measured: forcing a 13-term Henderson on `UKgas` (which should get 7) moves the trend by up to **10.2%**, with no error and no warning.

Verified afterwards, hand-coded X-11 against the real X-13, interior mean absolute difference:

| Series | $s$ | d10 | d11 | d12 |
|---|---|---|---|---|
| `AirPassengers` | 12 | 0.52% | 0.52% | 0.61% |
| `UKgas` | 4 | 0.75% | 0.75% | 1.03% |
| `JohnsonJohnson` | 4 | 0.76% | 0.75% | 0.92% |

Quarterly agreement is as good as monthly — which is the point worth carrying: nothing about the method is special to 12.

## A standing caution

Every quantitative result in this vault is *on the series it was computed on*. The 41% revision reduction in [[20-08-x11-arima]] is an AirPassengers number, not a law of nature. Where a claim is meant to generalise, it should be checked on at least two series — and the catalogue exists so that is cheap.

## Links

- [[00-Start-Here]] · [[_meta/progress]]

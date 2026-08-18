---
aliases: [Diagnostics, Module 5]
tags: [moc, module-5]
---

# Module 5 — Diagnostics and practice

Being able to *run* an adjustment is not the same as knowing whether to believe it.

## Notes to write

- [[50-01-is-there-seasonality]] — spectral peaks, stable-seasonality F-test, QS statistic. Adjusting a non-seasonal series is worse than doing nothing.
- [[50-02-residual-seasonality]] — the cardinal sin: a seasonal peak surviving in the adjusted series. Check the spectrum of the SA series and of the irregular.
- [[50-03-m-and-q-statistics]] — X-11's M1–M11 and the combined Q. Useful, crude, widely misused as a pass/fail gate.
- [[50-04-sliding-spans]] — re-adjust on overlapping subspans; if the factors disagree, the adjustment is unstable regardless of what the M-stats say.
- [[50-05-revision-history]] — the concurrent-vs-final comparison; the honest measure of end-of-sample quality.
- [[50-06-turning-points]] — **why adjustment fails exactly when it matters most**
- [[50-07-outliers-and-breaks]] — AO / LS / TC; when to intervene manually
- [[50-08-covid]] — the canonical modern breakdown case and what agencies did about it
- [[50-09-x11-vs-seats]] — when they disagree, and which to trust

## The turning-point problem, stated properly

This deserves its own headline because it is the thing practitioners most need to understand and most often do not.

Symmetric filters need future observations. At the sample end there are none, so X-13 forecast-extends and effectively applies an **asymmetric** filter. At a business-cycle turn the forecast is systematically wrong — it extrapolates the *old* regime — so the seasonal factors at the end are contaminated in a systematic direction, and get revised as real data arrives.

Three separable mechanisms:

1. **Forecast contamination** — the extension itself is biased at a turn.
2. **Asymmetric end-filter weights** — the end filter differs from the interior filter in a way that does not average out.
3. **The revision path** — later vintages converge toward the symmetric-filter value.

Numbers worth carrying:

| Quantity | Value | Source |
|---|---|---|
| Forecast-contamination bias | $\approx 0.38 \times$ average overstatement (0.38 = future-side weight of the end filter) | |
| Revision variance reduction | $-50\%$ after 1 yr, $-77\%$ after 3 yr, $-88\%$ after 5 yr | Maravall 1996 |
| False-signal rate, month-to-month SA movements | $\approx 40\%$ | Maravall & Pierce 1983 |

That last one is the number to quote at anyone who reads a single month's seasonally adjusted change as news.

## Tooling

- `seasonal::seas()`, then `seasonal::inspect()` for the interactive diagnostics view
- `seasonal::udg()` for the raw X-13 diagnostic dictionary
- `seasonal::series(m, "s10")` etc. to pull individual X-13 tables

## Prerequisites

Modules 1, 2, 4.

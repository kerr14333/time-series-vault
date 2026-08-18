---
aliases: [Extreme values, Sigma limits, Robustness in X-11]
tags: [module-2]
---

# Extreme values

Code: `R/20-06-extreme-values.R`

The one part of X-11 that is **not** a linear filter. It is what makes X-11 robust, and it is also what stops you from analysing X-11 purely as a gain function.

## The problem

A single outlier — a strike, a hurricane, a data error — enters the SI ratios for its calendar month. The seasonal filter then smears it across neighbouring years of that same month ([[20-04-seasonal-moving-averages]]), so one bad January corrupts the seasonal factor for *several* Januaries. A one-month problem becomes a multi-year problem.

## The mechanism

Work with the irregular. For each calendar month, compute a moving 5-year standard deviation $\sigma$ of the irregulars, then assign weights:

| Distance from 1 (multiplicative) | Weight |
|---|---|
| $< 1.5\sigma$ | 1 — full weight, kept as is |
| $1.5\sigma$ to $2.5\sigma$ | graduated linearly from 1 down to 0 |
| $> 2.5\sigma$ | 0 — fully replaced |

Those cutoffs, 1.5 and 2.5, are the default **sigma limits**, adjustable in X-13 (`x11.sigmalim`).

A zero-weight value is **replaced**, not deleted — substituted with an average of the nearest same-month values that survived. This keeps the series a regular monthly series with no gaps, which every filter downstream depends on.

> [!important] Replaced for the seasonal estimate, restored for the adjusted series
> The replacement is used when **estimating the seasonal factors**. It is not used when producing D11. The final seasonally adjusted series is the original data divided by the final seasonal factors, so a genuine outlier stays visible in D11 — as it should.
>
> Getting this backwards is a common implementation bug: you end up silently smoothing real events out of the published series.

## Two graduated passes

X-11 does this twice: preliminary weights during the B pass, refined weights during the C pass (the C17 table). Same reason as everything else here — the first estimate of the irregular is poor, so the first set of weights is poor.

## Why not just detect outliers properly

You can, and X-13 does — AO / LS / TC detection in regARIMA ([[10-12-estimation]]), *before* X-11 ever runs. That is strictly better where it applies, because it uses a model, gives you a significance test and a coefficient, and distinguishes a one-month blip (AO) from a permanent level change (LS), which the sigma-limit rule cannot.

The sigma-limit machinery predates that and remains as a safety net for whatever regARIMA missed. In modern practice both are active, so an extreme value has to get past two filters.

The distinction is worth holding onto:

| | Detects | Distinguishes AO/LS/TC? | Tests significance? |
|---|---|---|---|
| regARIMA outliers | before decomposition, model-based | yes | yes |
| X-11 sigma limits | during decomposition, empirical | no | no |

## Consequence for analysis

Because of this step X-11 is **nonlinear**: doubling the input does not double the output, and the composite-filter trick of [[20-05-the-x11-iteration]] is only exact for a series with no extremes. When people write "the X-11 filter", they mean the linear filter you get with the extreme-value step disabled. That is a real approximation, not a formality — say so when you compare X-11 to SEATS.

## Exercises

1. Inject a +30% spike into one January. Adjust with and without the extreme-value step. How much does the seasonal factor for *other* Januaries move?
2. Confirm the spike is still visible in D11 even when the value was fully downweighted for estimating the factors.
3. Vary the sigma limits from (1.5, 2.5) to (2.5, 4.0). How much does D11 change on a clean series? On a contaminated one?
4. Handle the same spike instead as an AO regressor in regARIMA. Compare.

## Links

- Prev: [[20-05-the-x11-iteration]] · Next: [[20-07-end-filters]]

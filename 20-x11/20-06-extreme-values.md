---
aliases: [Extreme values, Sigma limits, Robustness in X-11]
tags: [module-2]
---

# Extreme values

Code: [[code-20-06-extreme-values|`R/20-06-extreme-values.R`]]

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

![[20-06-extreme-values.png]]

*Drawn by [[figure-index#20-06-extreme-values.png|`make-figures.R`]] — code and every other figure in the [[figure-index|figure appendix]].*

Left: one +30% spike in January 1954, and what it does to the seasonal factor for **every other January** when the extreme-value step is switched off. Right: the spike is still plainly there in D11 — downweighting affects how the factors are *estimated*, not what gets published.

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

## Numerically

Extreme-value replacement is where X-11 stops being a linear filter.

The sigma limits turn residuals into weights: full weight inside 1.5 sigma, zero outside 2.5, and a linear ramp between:

<!-- run -->
```r
set.seed(11)
irr <- c(rnorm(60, 1, 0.02), 1.12, rnorm(11, 1, 0.02))   # one spike at t=61
w <- extreme_weights(irr)
cat("observations down-weighted:", sum(w < 1), "  fully excluded:", sum(w == 0), "\n")
round(w[58:64], 3)
```
```text
observations down-weighted: 4   fully excluded: 1 
[1] 1.000 1.000 1.000 0.000 1.000 0.476 1.000
```
<!-- end -->

Why it matters: the same input, with and without replacement, gives different seasonal factors. X-11 is therefore **not** a fixed linear filter — its weights depend on the data:

<!-- run -->
```r
a <- x11_decompose(AirPassengers, extreme = TRUE)$d10
b <- x11_decompose(AirPassengers, extreme = FALSE)$d10
cat(sprintf("max difference in seasonal factors: %.3f%%\n",
            100 * max(abs(as.numeric(a) - as.numeric(b)) / as.numeric(b))))
```
```text
max difference in seasonal factors: 1.146%
```
<!-- end -->

## Exercises

*Solutions: [[solutions#20-06-extreme-values|worked answers]] in the solutions appendix.*

1. Inject a +30% spike into one January. Adjust with and without the extreme-value step. How much does the seasonal factor for *other* Januaries move?
2. Confirm the spike is still visible in D11 even when the value was fully downweighted for estimating the factors.
3. Vary the sigma limits from (1.5, 2.5) to (2.5, 4.0). How much does D11 change on a clean series? On a contaminated one?
4. Handle the same spike instead as an AO regressor in regARIMA. Compare.

## Going further

*Harder, and different in kind: predict before you run, break things on purpose, and move the idea to a series it was not built on.*

1. **Predict first.** Will down-weighting an extreme January change the seasonal factor for *July*? Predict, then measure.
2. **Break it.** Set the sigma limits so wide that nothing is down-weighted, then inject a large outlier. How much do the seasonal factors move?
3. Explain in two sentences why extreme-value replacement makes X-11 a **non-linear** procedure, and what that costs you analytically.

## Links

- Prev: [[20-05-the-x11-iteration]] · Next: [[20-07-end-filters]]

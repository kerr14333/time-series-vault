---
aliases: [Turning points, Turning-point failure, False signals]
tags: [module-5, key]
---

# Why adjustment fails at turning points

Code: [[code-50-06-turning-points|`R/50-06-turning-points.R`]]

The most important note in the vault, and the reason any of this matters. Seasonal adjustment is least reliable exactly when people need it most.

## The claim, measured

US unemployment, 1990–2016 (`seasonal::unemp`, 323 months). Every **second** month from December 1997 to November 2015 — 108 months in all — is adjusted twice: once **concurrently** (as if that month were the last observation) and once from the **full sample**.

| Months | Mean absolute revision |
|---|---|
| in an NBER recession | **1.163%** |
| within a year of a recession | 1.112% |
| everywhere else | **0.620%** |
| **ratio** | **1.79×** |

Narrowing to the Great Recession:

| Months | Mean absolute revision |
|---|---|
| 2008–2010 | **1.600%** |
| all other months | 0.632% |
| **ratio** | **2.53×** |

And the tail — which is what actually damages credibility:

| | |
|---|---|
| worst 10% of revisions falling near a recession | **64%** |
| baseline share of months near a recession | 35% |
| **enrichment** | **1.81×** |

Nine of the fifteen worst-revised months in twenty-six years sit inside 2007–2010.

> [!important] The headline
> Revisions roughly **double** at business-cycle turning points. The seasonally adjusted unemployment number is about twice as provisional during a recession as it is in normal times — and that is precisely when it drives policy and dominates the news.

![[50-06-turning-points.png]]

*Drawn by [[figure-index#50-06-turning-points.png|`make-figures.R`]] — code and every other figure in the [[figure-index|figure appendix]].*

> [!note] Why the figure says 1.59x and the text says 1.79x
> Both start from the same month (December 1997) and run the same code on the same data. The figure steps every **third** month to keep `make-figures.R` runnable; the table above steps every **second**. Only the sampling differs.
>
> Neither is wrong, and the gap is the point: the exact ratio moves with how you sample, so quote it as **"roughly 1.5-2x"** rather than to three digits. The finding that survives every variant is that revisions are **substantially larger near turning points** — not any particular decimal.

## The three mechanisms

Kept separate, because they are usually merged into one hand-wave and the distinctions matter.

**1. Forecast contamination.** The symmetric filter needs future data, so X-13 supplies forecasts from the regARIMA model ([[10-14-forecasting]]). At a turn, the model extrapolates the *old* regime — it has seen nothing else — so the extension is wrong in a **systematic direction**, not randomly. The contamination bias is roughly $0.38\times$ the average overstatement, where 0.38 is the future-side weight of the end filter.

**2. Asymmetric end-filter weights.** Even with a perfect forecast, the end filter differs structurally from the interior one ([[20-07-end-filters]]) and has nonzero phase, so it shifts timing. This does not average out.

**3. The revision path.** Later vintages converge toward the symmetric-filter value, so the concurrent estimate was never an unbiased draw around the final one — it was biased in a direction determined by the regime the model had seen.

## Why it cannot be fixed

Every fix improves the terms without repealing the problem:

| Fix | Effect at a turn |
|---|---|
| a better ARIMA model | forecasts the old regime more precisely |
| forecast extension | 41% fewer revisions in normal times, no help at the turn |
| longer filters | smoother, and slower to notice the turn |
| more data | works, but arrives after the decision |

The information about the turn **does not exist yet**. No estimator can recover it. This is the honest limit of the whole subject, and it is worth saying to users plainly rather than burying in a footnote.

## The number to quote

Roughly **40% of month-to-month movements in a seasonally adjusted series can be false signals** (Maravall & Pierce 1983). Combined with the doubling above, a single month's adjusted change during a turning point carries very little information.

The correct response is not to abandon adjustment but to stop reading single months. Three-month averages, or year-on-year comparisons, are far more robust — and the reason agencies increasingly publish them alongside.

## A methodological warning from building this

My first attempt used **trend curvature** (the absolute second difference of the trend) as a proxy for "near a turning point". It recovered a much weaker effect, and essentially no correlation:

```text
curvature-based split      1.42x   correlation 0.083
recession-date split       1.79x
2008-2010 window           2.53x
```

Curvature is dominated by many small wiggles, so the proxy is swamped by ordinary months — note the correlation of 0.083 between curvature and revision size, which is essentially nothing. Using actual NBER recession dates — external information, not derived from the series — separates the groups more sharply and, more importantly, gives a variable that means what it claims to.

> [!warning] The lesson generalises
> A weak result can mean the effect is absent, or that your operationalisation is bad. Before concluding "no effect", check whether the variable you constructed actually measures the thing you meant. Here the same data gave 1.42× and 1.79× depending only on how "turning point" was defined — and the correlation between curvature and revision size is 0.083, essentially nil.

## Exercises

1. Reproduce the revision history for `unemp` and the recession split.
2. Look at the *sign* of the revisions during 2008–09. Are concurrent estimates systematically too low or too high? That is mechanism 1, visible directly.
3. Compare X-11 and SEATS revisions during the recession. Does the model-based method help at a turn?
4. Repeat the curvature proxy and confirm it fails. Then try other proxies — the magnitude of the trend's first difference, or a rolling variance. Does any recover the effect?
5. Compute the false-signal rate directly: how often does the sign of the concurrent month-to-month change differ from the sign of the final one?

## Links

- Prev: [[50-05-revision-history]] · Next: [[50-07-outliers-and-breaks]]
- Mechanisms: [[10-14-forecasting]], [[20-07-end-filters]], [[30-07-finite-samples]]
- Extreme case: [[50-08-covid]]

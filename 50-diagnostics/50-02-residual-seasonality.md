---
aliases: [Residual seasonality, QS on the adjusted series]
tags: [module-5, key]
---

# Residual seasonality

Code: [[code-50-02-residual-seasonality|`R/50-02-residual-seasonality.R`]]

The cardinal sin. If seasonality survives in the adjusted series, the adjustment failed at the one job it had — and users will read the leftover seasonal movement as economic news.

## The test

$$\text{QS on the adjusted series} \;=\; \texttt{qssadj}$$

Same statistic as [[50-01-is-there-seasonality]], pointed at the output instead of the input. $\chi^2_2$, so **above ~9 is significant**; you want it near zero.

Across the catalogue, after X-11 adjustment:

| Series | QS(orig) | QS(SA) |
|---|---|---|
| `co2` | 495.3 | 0.00 |
| `unemp` | 414.9 | 0.00 |
| `AirPassengers` | 167.6 | 0.00 |
| `UKgas` | 176.5 | 0.03 |
| `JohnsonJohnson` | 52.7 | **0.40** |

All clean. `JohnsonJohnson` is the least clean, which fits: it is quarterly with the most volatile seasonality in the catalogue ($\Theta = 0.315$), so its factors are the hardest to pin down.

## Check three series, not one

Residual seasonality can hide in different places, and each location means something different:

| Where you find it | What it means |
|---|---|
| the **adjusted series** (`qssadj`) | the adjustment plainly failed |
| the **irregular** (`qsirr`) | seasonality is leaking through into what should be noise |
| the **model residuals** (`qsrsd`) | the *model* is wrong — the seasonal part is misspecified |

The last is the most diagnostic. A seasonal peak in the regARIMA residuals means the model never captured the seasonality, so nothing downstream could have removed it properly. Fix the model, not the filter.

## Do it yourself, too

Do not rely solely on the reported statistic. Take the adjusted series, difference it, and look:

```r
sp <- spec.pgram(diff(log(d11)), spans = c(3,3), taper = 0.1, plot = FALSE)
# then compare power at k/12 against the median
```

On `AirPassengers` the ratios at the six seasonal frequencies come out $0.57, 0.40, 0.87, 0.42, 1.10, 0.21$ — nothing above about 1.1, so no peak. A ratio above roughly 2 is worth investigating; above 3, act.

This matters because of the trap in [[50-01-is-there-seasonality]]: X-13's undocumented `peaks.seas` key reports `"rsd sa"` for this very series, which reads like a warning and is contradicted by both QS and the direct spectrum.

## Common causes, and what actually fixes them

| Cause | Fix |
|---|---|
| seasonality evolving faster than the filter allows | shorter seasonal MA (3×3), or a lower $\Theta$ model |
| a **break** in the seasonal pattern | split the span, or add regressors for the break |
| unmodelled **trading day** or moving holiday | add the regressors — this is very often the real culprit |
| the wrong model | check `qsrsd` first; fix the ARIMA |
| genuinely too little data | nothing; do not publish |
| a **composite** built from separately adjusted parts | adjust the total directly, or accept the leftover |

That last row is a real institutional problem: aggregating separately adjusted series does not generally give a properly adjusted aggregate, and residual seasonality in published totals often traces to it.

## Why users care more than statisticians do

A leftover seasonal of even 0.3% in a monthly series is invisible in a plot and completely changes the story a single month tells. Since roughly **40% of month-to-month movements in an adjusted series can be false signals already** (Maravall & Pierce 1983, and [[50-06-turning-points]]), adding a systematic seasonal residue on top makes the headline number actively misleading.

This is the diagnostic to run every time, on every series, without exception.

## Exercises

1. Reproduce the QS table. Which series is least clean, and does its $\Theta$ explain that?
2. Compute the spectrum of the adjusted series yourself and compare with the QS verdict.
3. Force residual seasonality: adjust with `x11.seasonalma = "s3x9"` (a very long, slow filter) a series whose seasonality evolves fast. Does QS(SA) rise?
4. Introduce a seasonal break — shift the pattern by adding a constant to every January after the midpoint — and see which diagnostics catch it.
5. Adjust two series separately, add them, and test the sum for residual seasonality. Compare with adjusting the sum directly.

## Links

- Prev: [[50-01-is-there-seasonality]] · Next: [[50-03-m-and-q-statistics]]

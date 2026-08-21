---
aliases: [Forecasting, Psi weights, Forecast extension]
tags: [module-1, key]
---

# Forecasting — and why seasonal adjustment needs it

Code: [[code-10-14-forecasting|`R/10-14-forecasting.R`]]

This note is the hinge between Module 1 and everything after it. Forecasting is not a side application of ARIMA here; **it is the reason X-13 fits an ARIMA at all.**

## Minimum-MSE forecast

The optimal $h$-step forecast is the conditional expectation given the past. Using the AR($\infty$) form ([[10-08-arma-duality]]), forecast recursively: replace future $a$'s by 0 and future $z$'s by their forecasts.

Forecast error in terms of the $\psi$-weights:

$$e_t(h) = \sum_{j=0}^{h-1}\psi_j a_{t+h-j} \qquad\Longrightarrow\qquad V(h) = \sigma_a^2\sum_{j=0}^{h-1}\psi_j^2$$

Consequences worth internalising:

- $V(h)$ is nondecreasing in $h$. For a **stationary** model $\sum\psi_j^2$ converges, so $V(h)$ flattens at the unconditional variance — the forecast reverts to the mean.
- For a model with **unit roots**, $\psi_j \not\to 0$ and $V(h)$ grows without bound. A random walk's forecast is a flat line with ever-widening bands.
- For the **airline model**, the forecast keeps the seasonal shape and extends the local trend linearly — which is exactly what makes it useful for extending a real economic series.

## Why the filters need forecasts

Here is the argument that motivates the rest of this vault.

A seasonal adjustment filter is **symmetric and two-sided**. To estimate the seasonal factor for month $t$ you use data from roughly $t-3$ years to $t+3$ years. Fine in the middle of the sample. But for the **most recent month there is no future data.**

Two possible responses:

1. Use a different, **asymmetric** filter at the ends — one that only looks backward. X-11 does this explicitly, with its own set of end weights.
2. **Forecast the series forward**, then apply the ordinary symmetric filter to the extended series.

X-13 does (2), using the regARIMA model, and this is the deep reason ARIMA appears in a method that is otherwise about moving averages. Note that (2) *is* a form of (1): applying a symmetric filter to model-based forecasts is algebraically equivalent to applying some implied asymmetric filter to the observed data. Forecast extension is a principled way to choose the end filter.

> [!important] The consequence that makes this whole subject interesting
> The most recent months' seasonal factors depend on **forecasts**, not data. When real data arrives, they get **revised**. And at a business-cycle turning point the forecast is systematically wrong — it extrapolates the old regime — so the end-of-sample adjustment is systematically contaminated, precisely when people care most.
>
> Quantified: seasonal-adjustment revision variance falls roughly 50% after 1 year, 77% after 3 years, 88% after 5 years (Maravall 1996). And roughly 40% of month-to-month movements in a seasonally adjusted series can be false signals (Maravall & Pierce 1983).

Module 5 makes this the main event: [[50-00-diagnostics-map]].

## Forecasting logs

If the model is on $\log z_t$ and you want a forecast of $z_t$, $\exp$ of the forecast is the **median**, not the mean. Mean requires $\exp(\hat z + \sigma^2/2)$. For seasonal adjustment this rarely matters (factors are ratios), but it matters for published forecasts.

## Numerically

Forecasts and, more importantly, how fast the uncertainty grows.

Twelve months ahead, back on the original scale:

<!-- run -->
```r
f <- arima(lap, order = c(0, 1, 1),
           seasonal = list(order = c(0, 1, 1), period = 12))
p <- predict(f, n.ahead = 12)
round(cbind(forecast = exp(p$pred), lo95 = exp(p$pred - 1.96 * p$se),
            hi95 = exp(p$pred + 1.96 * p$se)), 1)
```
```text
         forecast  lo95  hi95
Jan 1961    450.4 419.1 484.0
Feb 1961    425.7 391.5 463.0
Mar 1961    479.0 435.9 526.4
Apr 1961    492.4 443.9 546.2
May 1961    509.1 455.0 569.5
Jun 1961    583.3 517.3 657.8
Jul 1961    670.0 589.7 761.2
Aug 1961    667.1 583.0 763.3
Sep 1961    558.2 484.6 643.0
Oct 1961    497.2 428.9 576.4
Nov 1961    429.9 368.5 501.4
Dec 1961    477.2 406.7 560.0
```
<!-- end -->

The interval widens with horizon because the $\psi$-weights accumulate. This is exactly why forecast-extension helps least at the end of a series:

<!-- run -->
```r
round(data.frame(horizon = c(1, 3, 6, 12),
                 se = p$se[c(1, 3, 6, 12)],
                 width_pct = 100 * (exp(1.96 * p$se[c(1, 3, 6, 12)]) - 1)), 3)
```
```text
  horizon    se width_pct
1       1 0.037     7.462
2       3 0.048     9.884
3       6 0.061    12.770
4      12 0.082    17.337
```
<!-- end -->

## Exercises

1. Forecast `log(AirPassengers)` 24 months ahead from the airline model. Plot with intervals on the original scale. How fast do the bands widen?
2. Compute $\psi$-weights for the airline model with `ARMAtoMA()` after expanding the polynomials. Confirm they do not decay to zero.
3. **The key experiment.** Fit the model to data through 1958, forecast 1959–60, and compare to the truth. Then re-run holding out a different window. Where are the errors largest?
4. Truncate the series at various points, adjust each vintage, and plot how the January-1958 seasonal factor changes as more data arrives. You have just measured a revision path — this is Module 5 in miniature.

## Links

- Prev: [[10-13-model-selection]] · **Module 1 complete** → [[20-00-x11-map]]
- Payoff: [[50-00-diagnostics-map]]

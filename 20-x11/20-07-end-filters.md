---
aliases: [End filters, Asymmetric filters, Musgrave filters, Revisions]
tags: [module-2, key]
---

# End filters — where revisions come from

Code: `R/20-07-end-filters.R`

The most important note in this module. Everything in [[50-00-diagnostics-map]] traces back here.

## The problem, precisely

A 13-term Henderson filter needs six observations on each side. For the final month of the sample there are **zero** future observations. For the second-to-last there is one. And so on.

You cannot use the symmetric filter. You must use something else for the last $m$ points — and whatever you use, it is **asymmetric**, so by [[20-01-moving-averages-as-filters]] it has **nonzero phase**. It shifts things in time.

## Musgrave's surrogate filters

X-11's answer (Musgrave, 1964): for each end position, derive the asymmetric filter that **minimises the mean squared revision** — the expected squared difference between what this filter gives now and what the symmetric filter will eventually give — under an assumed model for the series (a linear trend plus noise, with a specified I/C ratio).

So there is not one end filter but $m$ of them: one for the last point, one for the second-to-last, and so on, each converging toward the symmetric weights as more future data becomes available.

## Look at the weights

This is the thing to actually stare at, and the script plots it:

| Filter | Weight on the current observation | Weight on future observations |
|---|---|---|
| symmetric 13-term Henderson | 0.240 | 0.5 of the total, by symmetry |
| end filter (last point) | much larger | **zero** — there is no future |

The end filter is forced to put all its mass on the past and present. It is not a small perturbation of the symmetric filter; it is a structurally different object.

![[20-07-end-filters.png]]

> [!important] Why the failure happens *at* the turn, not before it
> The end weights differ **sharply** from the interior weights. So the estimate for recent months is produced by a different filter than the one that will eventually be applied to them.
>
> As new data arrives, each month's estimate is recomputed with a progressively less asymmetric filter, converging on the symmetric answer. That convergence *is* the revision path.

## Revisions, quantified

The numbers worth carrying (all for seasonally adjusted series, from the literature):

| Quantity | Value | Source |
|---|---|---|
| Revision variance reduction after 1 year | $-50\%$ | Maravall (1996) |
| after 3 years | $-77\%$ | |
| after 5 years | $-88\%$ | |
| Fraction of month-to-month SA movements that are false signals | $\approx 40\%$ | Maravall & Pierce (1983) |
| Forecast-contamination bias | $\approx 0.38 \times$ average overstatement | — |

That 0.38 is the **future-side weight of the end filter** — the share of the filter's mass that, in the symmetric version, would have come from data that does not exist yet and must be supplied by a forecast instead.

## The three mechanisms, kept separate

When you write or read about turning-point failure, distinguish:

1. **Forecast contamination** — the extension is systematically wrong at a turn because it extrapolates the old regime.
2. **Asymmetric end-filter weights** — the end filter differs from the interior filter in a way that does not average out.
3. **The revision path** — later vintages converge toward the symmetric-filter value, so the early estimate was never an unbiased draw around the final one.

They are often merged into one hand-wave. Keeping them apart is what makes the diagnosis useful.

## The connection to forecast extension

Applying a **symmetric** filter to a series extended by **forecasts** is algebraically equivalent to applying *some* asymmetric filter to the observed data. So the two strategies are the same kind of thing; the question is only which implied asymmetric filter you get.

Musgrave derives his directly, under a simple assumed model. X-11-ARIMA and X-13 derive theirs implicitly, from a regARIMA model fitted to the actual series — which is usually better, because the model is tailored rather than assumed. That is [[20-08-x11-arima]].

## Exercises

1. Plot the symmetric 13-term Henderson weights against the end-point weights on one axis. Confirm the end filter has zero weight on the future and much more on the present.
2. Adjust a series truncated at successive endpoints and plot the revision path for one month. Compare with the same experiment in `R/10-14-forecasting.R` — you already ran this once for SEATS.
3. Measure it: mean absolute revision between the concurrent estimate and the estimate 12 months later, across the whole series.
4. Confirm the phase shift of an end filter is nonzero while the symmetric filter's is zero.

## Links

- Prev: [[20-06-extreme-values]] · Next: [[20-08-x11-arima]]
- Payoff: [[50-05-revision-history]], [[50-06-turning-points]]

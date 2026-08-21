---
aliases: [Outliers, Level shifts, AO LS TC, Breaks]
tags: [module-5]
---

# Outliers and breaks

Code: [[code-50-07-outliers-and-breaks|`R/50-07-outliers-and-breaks.R`]]

An undetected outlier corrupts the ARIMA fit, and through it the seasonal factors, and through those the entire published series. Handling them is not tidying-up — it is load-bearing.

## The three types

| Type | Shape | Example | Effect on the series |
|---|---|---|---|
| **AO** additive outlier | one point | a strike, a data error | a single month is wrong |
| **LS** level shift | a permanent step | a definitional change, a new plant | everything after moves |
| **TC** temporary change | a spike decaying geometrically | a hurricane and its recovery | several months, fading |

X-13 also supports **SO** (seasonal outlier — one month's seasonal pattern changes) and **ramps** for gradual transitions.

Getting the *type* right matters as much as the location:

> [!important] AO and LS are not interchangeable
> Model a genuine level shift as an AO and the step remains in the data, distorting the trend and inflating the residual variance from then on. Model a one-off spike as an LS and you permanently shift a series that should have returned to its path.
>
> The seasonal factors inherit both mistakes.

## Detection

X-13 runs an iterative t-test procedure: fit, find the largest standardised outlier effect, add it as a regressor, refit, repeat until nothing exceeds the critical value. The default critical value scales with sample size (around 3.8 for a few hundred observations).

```r
m <- seas(x, outlier.types = "all", outlier.critical = 3.5)
grep("^(AO|LS|TC)", names(coef(m)), value = TRUE)
```

Note `coef()` also returns the ARIMA coefficients, so filter by name — reporting `MA-Nonseasonal-01` as an outlier is an easy and embarrassing mistake.

## Two layers of protection

Modern X-13 has both, and they do different jobs:

| | regARIMA outliers | X-11 sigma limits ([[20-06-extreme-values]]) |
|---|---|---|
| When | before decomposition | during decomposition |
| Basis | model, with a t-test | empirical, moving standard deviation |
| Distinguishes AO/LS/TC | **yes** | no |
| Reports a coefficient | **yes** | no |
| Survives into the published series | effect removed, then added back | the value stays in D11 |

regARIMA is strictly better where it applies. The sigma limits remain as a safety net for whatever the model missed.

## Automatic detection is not enough

Three failure modes worth knowing:

1. **Outliers at the very end are hard to detect** and easy to confuse with a genuine turning point. An LS in the final months is exactly what the start of a recession looks like — and treating a real downturn as a level shift *removes the recession from the trend*. This is a real and serious failure mode.
2. **Too many outliers means the model is wrong.** If automatic detection finds fifteen, the problem is not fifteen unusual months; it is that the model does not fit.
3. **Detected outliers change as data arrives**, so an outlier found this month may vanish next month, which itself causes revisions.

The standard institutional practice is therefore: automatic detection *proposes*, a human *disposes*, and known events (a strike, a policy change, a definitional break) are specified in advance rather than discovered.

## Breaks in the seasonal pattern

Harder than outliers in the level, and less well handled. If the seasonal pattern itself changes — a retailer moves its sale season, a school calendar shifts — the options are:

- a **seasonal outlier** (SO) regressor for a single month's change;
- **splitting the span** and adjusting the two halves separately;
- accepting residual seasonality and documenting it.

Sliding spans ([[50-04-sliding-spans]]) is the diagnostic that finds these, because a seasonal break makes the adjustment unstable to which window you use.

## Exercises

*Solutions for this note are not written yet — see [[solutions]] for the modules that are covered.*

1. Inject an AO, an LS and a TC of the same size into a clean series. Adjust each. Which does most damage to the seasonal factors?
2. Model an injected LS as an AO instead. Quantify the damage to the trend after the break.
3. Vary `outlier.critical` from 3.0 to 5.0. How many outliers appear, and how much does D11 move?
4. Put an LS in the final six months and see whether detection finds it. Then ask whether you would want it to.
5. Simulate a seasonal break and confirm sliding spans catch it while QS does not.

## Links

- Prev: [[50-06-turning-points]] · Next: [[50-08-covid]]
- Related: [[20-06-extreme-values]], [[10-12-estimation]]

---
aliases: [Finite samples, Burman's algorithm, Filter truncation]
tags: [module-3]
---

# From an infinite filter to real data

Code: [[code-30-07-finite-samples|`R/30-07-finite-samples.R`]]

The Wiener–Kolmogorov filter of [[30-06-wiener-kolmogorov]] is doubly infinite. Your series has 144 observations. This note closes that gap — and in doing so lands you back on the revision problem from a completely different direction, which is the point.

## Three approaches

**1. Truncate.** The weights decay geometrically, so drop them below some tolerance. Crude, and it silently changes the filter at the ends — the truncated weights no longer sum to 1 unless you renormalise, and renormalising distorts the gain.

**2. Forecast-extend, then filter.** Extend the series with forecasts and backcasts from the same ARIMA model, far enough that the remaining truncated weights are negligible, then apply the symmetric filter to the extended series.

This is what X-13 does, and it is the same device as [[20-08-x11-arima]] — arrived at here from theory rather than from Dagum's empirical fix. Note how the two modules converge on the identical trick from opposite starting points. That convergence is not coincidence: it is the same underlying problem.

**3. Burman's algorithm** (1980). The exact finite-sample solution, computed efficiently by exploiting the rational structure of the filter rather than by explicit extension. It is what SEATS actually implements, and it gives exactly what infinite forecast extension would give, without the extension.

Approaches 2 and 3 agree; 3 is faster and numerically cleaner. Implementing 2 is more instructive, so that is what you will build in [[40-07-implementing-seats-in-r]].

## Why forecast extension is exactly right here

For a **linear** filter applied to a series extended by **minimum-MSE forecasts**, the result equals the minimum-MSE estimate of the filtered value given the observed data. Forecasting and filtering commute in the right way.

So extension is not an approximation to the finite-sample answer — under the model, it *is* the answer. Which is why X-13's forecast extension is principled rather than a patch, and why the same idea appears in both the filter-based and model-based halves of the program.

## And here is the revision problem again

The estimate for the last observation uses forecasts. As real data arrives:

- the forecasts are replaced by observations,
- the effective filter becomes progressively more symmetric,
- the estimate converges to the value the symmetric filter would have given.

**That path is the revision.** It has now been derived three times in three languages:

| Module | Route |
|---|---|
| [[10-14-forecasting]] | the filter needs future values that do not exist |
| [[20-07-end-filters]] | the end filter differs structurally from the interior filter |
| here | the WK filter is doubly infinite and must be completed with forecasts |

Same phenomenon. If you can state all three and say why they are the same statement, you understand the end-of-sample problem better than most practitioners.

## How far to extend

Far enough that the omitted weights are negligible — governed by how fast the WK weights decay, which is governed by how close the roots of $\theta(B)$ are to the unit circle ([[30-06-wiener-kolmogorov]]).

Rule of thumb: a few years each way. X-13 defaults to one year of forecasts for X-11; SEATS effectively uses more via Burman. A series with $\Theta$ very near 1 needs a longer extension — the same series whose seasonal peaks are narrowest and whose revisions are smallest once enough data exists.

## Practical checks when you implement this

1. **Do the weights sum to 1?** If not, the level is being distorted.
2. **Is the filter symmetric** in the interior? Asymmetry there is a bug, not a feature.
3. **Do the components add back to the input?** $\hat T + \hat S + \hat I = z$ exactly, up to floating point. This is the single best end-to-end test of an implementation, and it catches most errors.
4. **Does the interior agree with SEATS?** Ends will differ if your extension differs; the interior should not.

## Numerically

The theory gives an infinite two-sided filter. The data is finite. Something has to give.

How far the airline WK filter actually reaches, as a function of Theta. This is not a small number:

<!-- run -->
```r
for (Th in c(0.3, 0.557, 0.8))
  cat(sprintf("  Theta = %.3f : %3d lags needed = %.1f years\n",
              Th, seats_max_lag(0.4, Th), seats_max_lag(0.4, Th) / 12))
```
```text
  Theta = 0.300 :  60 lags needed = 5.0 years
  Theta = 0.557 : 331 lags needed = 27.6 years
  Theta = 0.800 : 600 lags needed = 50.0 years
```
<!-- end -->

Truncating instead of extending does not add noise — it adds a **constant offset**, which is far easier to miss:

<!-- run -->
```r
x <- lap
good <- seats_decompose(x, 0.4018, 0.5569, normalize = FALSE)
bad  <- seats_decompose(x, 0.4018, 0.5569, max_lag = 60, extend = 72,
                        normalize = FALSE)
d <- as.numeric(bad$seasonal) - as.numeric(good$seasonal)
cat(sprintf("mean offset %+.5f   sd about that mean %.5f\n", mean(d), sd(d)))
cat("The mean dwarfs the scatter: a bias, not noise.\n")
```
```text
mean offset +0.02292   sd about that mean 0.00134
The mean dwarfs the scatter: a bias, not noise.
```
<!-- end -->

## Exercises

*Solutions: [[solutions#30-07-finite-samples|worked answers]] in the solutions appendix.*

1. Compute WK weights for a signal-plus-noise model and plot their decay. How many terms until they fall below $10^{-4}$?
2. Apply the truncated filter with and without renormalisation. Compare the gains near $\omega=0$.
3. Extend a series with ARIMA forecasts, filter, and compare to the truncated version. Where do they differ, and by how much?
4. Vary the extension length from 1 to 5 years and watch the estimate for the final observation converge.
5. Confirm the three-way equivalence: extension length $\to\infty$, truncation tolerance $\to0$, and Burman's exact answer all coincide.

## Going further

*Harder, and different in kind: predict before you run, break things on purpose, and move the idea to a series it was not built on.*

1. **Predict first.** How many years of filter will a $\Theta = 0.99$ model need? Guess before computing — most people are badly wrong.
2. **Break it.** Truncate at 24 lags and compare against the correct answer *without* normalising either. What is the shape of the error?
3. **Transfer.** Repeat the lag-requirement calculation for a quarterly model. Fewer lags, or fewer *years*?

## Links

- Prev: [[30-06-wiener-kolmogorov]] · **Module 3 complete** → [[40-00-seats-map]]
- Same problem elsewhere: [[10-14-forecasting]], [[20-07-end-filters]]
- Quiz: [[_quiz/quiz-module-3]]

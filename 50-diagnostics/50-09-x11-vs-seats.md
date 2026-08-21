---
aliases: [X-11 vs SEATS, Which method, Method comparison]
tags: [module-5, key]
---

# X-11 versus SEATS

Code: [[code-50-09-x11-vs-seats|`R/50-09-x11-vs-seats.R`]]

The practical question the whole vault has been building toward: which do you publish?

## How different are they, actually?

Both methods on every catalogue series, comparing `d11` (X-11) with `s11` (SEATS):

| Series | $\Theta$ | Mean abs diff | Max diff | Correlation |
|---|---|---|---|---|
| `co2` | 0.912 | **0.018%** | 0.06% | 0.99999 |
| `cpi` | 0.592 | 0.046% | 0.43% | 0.99999 |
| `USAccDeaths` | 0.593 | 0.364% | 1.28% | 0.99532 |
| `iip` | 0.932 | 0.438% | 1.49% | 0.99933 |
| `AirPassengers` | 0.557 | 0.527% | 2.63% | 0.99989 |
| `unemp` | 0.765 | 0.537% | 2.58% | 0.99974 |
| `nottem` | 0.922 | 0.576% | 3.57% | 0.98292 |
| `JohnsonJohnson` | 0.315 | 1.388% | 8.28% | 0.99986 |
| `ldeaths` | 1.000 | 1.607% | 4.08% | 0.98071 |
| `imp` | 0.498 | 1.777% | **27.47%** | 0.99991 |
| `UKgas` | **0.235** | **4.178%** | 11.68% | 0.99759 |

Two readings, and both matter.

**Usually they agree closely.** Correlations of 0.99+ throughout; for `co2` the two methods differ by less than a fiftieth of a percent. On a well-behaved series with stable seasonality the choice barely matters.

**When they disagree, they disagree a lot.** `UKgas` differs by 4.2% on average and 11.7% at worst; `imp` has a single month differing by **27%**. These are not rounding differences — they are different published numbers, and someone has to choose.

## The pattern in the disagreement

The three worst (`UKgas` 0.235, `JohnsonJohnson` 0.315, `imp` 0.498) all have **low $\Theta$** — volatile, fast-evolving seasonality. The best (`co2` 0.912, `iip` 0.932) have high $\Theta$.

That is exactly what [[40-06-wk-filters-for-the-airline-model]] predicts. SEATS adapts its notch width to $\Theta$; X-11 picks from a small fixed menu. When seasonality is stable both produce narrow notches and agree. When it is volatile SEATS widens its notches substantially while X-11 can only step to the next filter length — so the methods part company.

`ldeaths` disagrees for a different reason: the airline model over-differences it ([[series-catalogue]]), so the model-based method is working from a model that does not fit.

> [!important] Predicting the disagreement
> **Low $\Theta$ means the two methods will differ.** You can tell before running either one whether the choice of method will matter for a given series — from a single coefficient.

## Choosing

| Prefer **SEATS** when | Prefer **X-11** when |
|---|---|
| the ARIMA model fits well (clean residuals) | the model fits poorly, or is unstable across vintages |
| you want filters adapted to the series | you want the same treatment across many series |
| you need component standard errors | you need M/Q diagnostics |
| the decomposition is admissible | SEATS keeps substituting the model ([[40-02-admissible-decompositions]]) |
| you value theoretical coherence | you value robustness to model misspecification |

The honest summary: **SEATS is better when its model is right, and X-11 degrades more gracefully when it is not.** That is the usual trade between model-based and nonparametric methods, and neither answer is universally correct.

Institutional practice reflects this — Eurostat and the Bank of Spain lean SEATS, the US Census Bureau and BLS lean X-11, and both camps are staffed by people who understand the other option perfectly well.

## Keep the comparison in proportion

From [[40-08-validating-against-x13]], on `AirPassengers`:

| Comparison | Difference |
|---|---|
| SEATS vs X-11 — **method** | 0.760% |
| our build vs X-13 — **implementation** | 0.001% |

A factor of ~660. The method choice dominates implementation precision by nearly three orders of magnitude. Spend your attention accordingly.

## What to do when they disagree

1. **Check the model first.** Large disagreement usually means the ARIMA fits badly. Fix that and they often converge.
2. **Check admissibility.** If SEATS substituted the model, its components came from a model you did not choose.
3. **Check $\Theta$.** If it is low, disagreement is expected and neither method is malfunctioning.
4. **Run both, look at both, publish one, and document the choice.** Switching methods between vintages is far worse than either choice.

That last point is the one that matters institutionally. A series adjusted by SEATS this month and X-11 next month has revisions that mean nothing.

## Numerically

Two methods, same data. How far apart do they actually land?

The method difference, and for scale, the difference between our SEATS and the Census binary:

<!-- run -->
```r
x <- AirPassengers
a <- as.numeric(series(seas(x, x11 = ""), "d11"))
b <- as.numeric(series(seas(x, x11 = NULL), "s11"))
cat(sprintf("X-11 vs SEATS (method)        : %.3f%%\n",
            100 * max(abs(a - b) / b)))
cat("Compare 0.001%% for our SEATS vs the Census binary in 40-08:\n")
cat("the choice of METHOD matters hundreds of times more than the\n")
cat("choice of implementation.\n")
```
```text
X-11 vs SEATS (method)        : 2.627%
Compare 0.001%% for our SEATS vs the Census binary in 40-08:
the choice of METHOD matters hundreds of times more than the
choice of implementation.
```
<!-- end -->

## Exercises

*Solutions for this note are not written yet — see [[solutions]] for the modules that are covered.*

1. Reproduce the comparison table. Confirm the low-$\Theta$ pattern.
2. Investigate `imp`'s 27% month. What is happening there — an outlier, a moving holiday, a break?
3. For `UKgas`, plot both adjusted series. Is the difference visible, or only in the statistics?
4. Compare revisions rather than levels: which method revises less at the end of the sample?
5. Fit a better model to `ldeaths` (the $d=0$ one) and re-compare. Do the methods converge?

## Links

- Prev: [[50-08-covid]] · **Module 5 complete**
- Filters: [[40-06-wk-filters-for-the-airline-model]] · Data: [[series-catalogue]]
- Quiz: [[_quiz/quiz-module-5]]

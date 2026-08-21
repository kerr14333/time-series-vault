---
aliases: [M statistics, Q statistic, M7]
tags: [module-5]
---

# The M and Q statistics

Code: [[code-50-03-m-and-q-statistics|`R/50-03-m-and-q-statistics.R`]]

X-11's eleven summary diagnostics and their weighted average. Useful, crude, and very widely misused — so this note is as much about their limits as their meaning.

## The eleven

Each is scaled so that **below 1 is acceptable** and above 1 is a warning.

| | Measures |
|---|---|
| M1 | relative contribution of the irregular to the variance of the differenced series |
| M2 | same, from the *stationary portion* |
| M3 | irregular size relative to month-to-month trend change |
| M4 | autocorrelation in the irregular |
| M5 | months for cyclical dominance — how long before the trend outgrows the noise |
| M6 | year-to-year change in the irregular vs the seasonal |
| **M7** | **combined test for identifiable seasonality** |
| M8 | size of the fluctuations in the seasonal component over the span |
| M9 | average linear movement in the seasonal |
| M10 | M8 computed on recent years only |
| M11 | M9 computed on recent years only |

**Q** is a weighted average of all eleven; **Q-M2** is the same excluding M2 (which is unreliable on short series). Both use the same "below 1" convention.

## In practice, M7 is the one that matters

M7 combines the stable-seasonality F-test with the moving-seasonality F-test into a single number, and it is the standard gate for *should this series be adjusted at all*.

Across the catalogue:

| Series | M7 | Q | Reading |
|---|---|---|---|
| `co2` | 0.03 | 0.12 | textbook |
| `unemp` | 0.17 | 0.18 | very good |
| `AirPassengers` | 0.20 | 0.20 | very good |
| `UKgas` | 0.21 | 0.33 | good |
| `JohnsonJohnson` | 0.36 | 0.56 | acceptable |
| `cpi` | **0.66** | 0.42 | weakest of the real series |
| **`sunspots`** | **2.47** | **1.46** | **fails — do not adjust** |

Two things to notice. `sunspots` fails decisively, as it should ([[50-01-is-there-seasonality]]). And `cpi` has the highest M7 among the genuine series — the same series that is inadmissible for SEATS ([[40-02-admissible-decompositions]]). Independent diagnostics converging on the same awkward series is a good sign that they are measuring something real.

## The limits, stated plainly

> [!warning] Q is not a pass/fail gate, however often it is used as one
> - The **thresholds are conventions**, not test sizes. There is no null distribution behind "below 1"; nobody can tell you the false-positive rate.
> - The weights in Q are **arbitrary**. They were chosen by judgement in the 1960s and never re-derived.
> - **They are X-11 statistics.** SEATS produces no M or Q. Comparing a SEATS adjustment to an X-11 one via Q is comparing a method to itself.
> - **They say nothing about the ends**, which is where the real uncertainty lives ([[50-05-revision-history]], [[50-06-turning-points]]).
> - A good Q on a series with **residual seasonality** is possible. Q is a summary; QS is the test. Run both.

The healthy use is as a **screen over many series** — flag the worst 5% for human attention — rather than as a certificate for any single one.

## What to run instead, or as well

| Question | Better tool |
|---|---|
| is there seasonality? | QS, M7, the spectrum |
| did any survive? | QS on the adjusted series |
| is the adjustment stable? | sliding spans ([[50-04-sliding-spans]]) |
| how much will it revise? | revision history ([[50-05-revision-history]]) |
| is the model right? | residual diagnostics ([[10-13-model-selection]]) |

M and Q answer none of the last three, and those are the questions users actually feel.

## Numerically

Eleven M statistics and one Q. Under 1 passes; over 1 is a complaint.

The full panel on `AirPassengers`. Read which ones are near or above 1 rather than the overall verdict alone:

<!-- run -->
```r
m <- seas(AirPassengers, x11 = "")
u <- udg(m)
ks <- sprintf("f3.m%02d", 1:11)
v <- vapply(ks, function(k) if (k %in% names(u)) as.numeric(u[[k]])[1] else NA_real_, 0)
names(v) <- sprintf("M%d", 1:11)
print(round(v, 3))
cat("Q =", round(as.numeric(u[["f3.q"]])[1], 3),
    if (as.numeric(u[["f3.q"]])[1] < 1) " -- accepted\n" else " -- FAILED\n")
```
```text
   M1    M2    M3    M4    M5    M6    M7    M8    M9   M10   M11 
0.041 0.042 0.000 0.283 0.190 0.703 0.203 0.418 0.368 0.431 0.418 
Q = 0.2  -- accepted
```
<!-- end -->

## Exercises

*Solutions: [[solutions#50-03-m-and-q-statistics|worked answers]] in the solutions appendix.*

1. Print all eleven M statistics for `AirPassengers` and for `sunspots`. Which differ most?
2. Find a series where Q is below 1 but QS on the adjusted series is significant. What does that combination mean?
3. Adjust the same series with a 3×3 and a 3×9 seasonal filter. How much do M8–M11 move? Does Q pick the filter you would?
4. Confirm that SEATS mode produces no M or Q statistics at all.
5. Shorten a series until M7 crosses 1. How many years does it take?

## Going further

*Harder, and different in kind: predict before you run, break things on purpose, and move the idea to a series it was not built on.*

1. **Predict first.** Which M statistic will fail first as you shorten a series? Guess, then find out empirically.
2. **Break it.** Construct a case where Q passes but the adjustment is visibly bad. What does that say about composite statistics?
3. Explain in two sentences why SEATS produces no M or Q statistics, and what you would use instead to compare the two methods.

## Links

- Prev: [[50-02-residual-seasonality]] · Next: [[50-04-sliding-spans]]

---
aliases: [Sliding spans, Stability diagnostics]
tags: [module-5]
---

# Sliding spans

Code: [[code-50-04-sliding-spans|`R/50-04-sliding-spans.R`]]

The stability question: if I had started the series a bit later, or ended it a bit earlier, would I get the same answer? An adjustment that changes materially under such a harmless perturbation is not one to publish.

## The procedure

1. Take several **overlapping spans** of the data — typically four, each covering 8–11 years, each shifted a year from the last.
2. Adjust each span independently.
3. For every month covered by two or more spans, compare the seasonal factors.
4. Flag months where the **maximum percentage difference** across spans exceeds a threshold.

Standard thresholds (Findley et al. 1990):

| Quantity | Flag if max % difference exceeds |
|---|---|
| seasonal factors | 3% |
| month-to-month change in the adjusted series | 3% |
| year-to-year change | 3% |

And the summary rule: if **more than 25% of months are flagged**, the adjustment is unstable and should not be published as is. For month-to-month changes the tolerance is tighter — above 40% flagged is considered a failure.

## Why this catches things nothing else does

Sliding spans probe a different failure mode from every other diagnostic in this module:

- **QS** asks whether seasonality remains. Says nothing about stability.
- **M and Q** are computed from *one* adjustment. They cannot see instability by construction.
- **Revision history** ([[50-05-revision-history]]) asks how the estimate changes as data is *added* at the end.
- **Sliding spans** ask how the estimate changes when the *window itself* moves.

A series can pass QS and Q comfortably and still be wildly unstable — typically when the seasonal pattern is evolving, or when a single influential observation is driving the factors and moves in and out of the window.

## What instability usually means

| Symptom | Likely cause |
|---|---|
| a few specific months flagged | an outlier near a span boundary |
| flags concentrated late in the sample | the seasonal pattern is changing |
| flags everywhere | seasonality too weak or too volatile to estimate — revisit [[50-01-is-there-seasonality]] |
| flags after a known event | a genuine break; model it explicitly |

The fix is rarely "use a different filter". It is usually to model the thing that is causing the instability — an outlier, a level shift, a break in the seasonal pattern.

## The honest limitation

Sliding spans need **a lot of data**. Four 8-year spans shifted by a year each need 11 years minimum, and the diagnostic is unreliable below that. Short series — `USAccDeaths` at 72 observations, `JohnsonJohnson` at 84 — simply cannot be assessed this way.

That is awkward, because short series are exactly the ones most likely to be unstable. The diagnostic is least available where it is most needed, and there is no way around it: the information is not there.

## Sliding spans versus revision history

They are complementary and often confused:

| | Sliding spans | Revision history |
|---|---|---|
| Perturbation | move the whole window | add data at the end |
| Question | is the answer robust? | how much will it change? |
| Needs | a long series | a long series |
| Failure means | the estimate is fragile | the early estimate is provisional |

Run both when you can. If sliding spans are clean but revisions are large, the adjustment is *stable but provisional* — normal, and the subject of [[50-05-revision-history]]. If sliding spans fail, something is wrong with the model or the data, and revisions are the least of your problems.

## In R

`seasonal` exposes this through the `slidingspans` spec:

```r
m <- seas(x, slidingspans = "")
udg(m)      # look for keys containing "sspan"
```

## Exercises

1. Run sliding spans on `AirPassengers`. What percentage of months are flagged?
2. Do the same for a series with volatile seasonality (`UKgas`, `JohnsonJohnson`). Does the flag rate track $\Theta$?
3. Inject an outlier near a span boundary and watch the flag rate jump. Then model it as an AO and confirm it settles.
4. Shorten a series until sliding spans become unavailable. How much data does the diagnostic actually need?
5. Find a series that passes Q but fails sliding spans, and explain what Q missed.

## Links

- Prev: [[50-03-m-and-q-statistics]] · Next: [[50-05-revision-history]]

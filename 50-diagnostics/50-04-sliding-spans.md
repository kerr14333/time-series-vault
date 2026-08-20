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
m <- seas(x, slidingspans = "", x11 = "")
udg(m)[["s2.a.per"]]   # c(n flagged, n tested, percent) for seasonal factors
udg(m)[["s2.d.per"]]   # the same for month-to-month changes
```

> [!warning] The obvious grep finds the wrong thing
> Searching `udg(m)` for keys containing `"sspan"` returns exactly one: `sspans`, whose value is the string `"yes"`. That is a yes/no that the spec ran — not a statistic. The numbers live in the **`s2.*`** keys. This vault's own script made that mistake and printed `?%` for every series in the catalogue until it was audited; the wrong key returned something truthy, so nothing looked broken.

Measured across the catalogue:

| Series | Seasonal factors flagged | Month-to-month | |
|---|---|---|---|
| `AirPassengers` | 2.08% (2/96) | 2.10% | passes |
| `imp` | 5.56% (6/108) | 15.89% | passes |
| `iip` | 0.00% (0/92) | 0.00% | passes |
| `UKgas` | **40.62%** (13/32) | 77.42% | **fails** |
| `JohnsonJohnson` | **18.75%** (6/32) | 51.61% | **fails** |

The two quarterly series fail badly, and that is the lesson: quarterly data gives you a quarter as many observations per span, and both have seasonality that genuinely evolves. Compare their $\Theta$ in [[series-catalogue]].

> [!note] It is not available for every series
> `accdeaths` and `ldeaths` return `sspans = "failed"` — six years is too short to build four spans, the limitation described above. But `temperature`, `co2`, `unemp` and `cpi` return `sspans = "yes"` and still emit no `s2.a.per`, giving `ssa`/`sscut`/`ssdiff` instead. That is **not** the additive-versus-multiplicative split — `co2` and `cpi` are both log transformed. What rule X-13 actually applies here I did not establish; when the key is missing, read the printed S 2 tables with `out(m)`.

## Exercises

1. Run sliding spans on `AirPassengers`. What percentage of months are flagged?
2. Do the same for a series with volatile seasonality (`UKgas`, `JohnsonJohnson`). Does the flag rate track $\Theta$?
3. Inject an outlier near a span boundary and watch the flag rate jump. Then model it as an AO and confirm it settles.
4. Shorten a series until sliding spans become unavailable. How much data does the diagnostic actually need?
5. Find a series that passes Q but fails sliding spans, and explain what Q missed.

## Links

- Prev: [[50-03-m-and-q-statistics]] · Next: [[50-05-revision-history]]

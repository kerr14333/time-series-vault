---
aliases: [Revision history, Concurrent vs final, Revisions]
tags: [module-5, key]
---

# Revision history

Code: [[code-50-05-revision-history|`R/50-05-revision-history.R`]]

The honest measure of end-of-sample quality, and the number your users actually experience.

## The definitions

| Term | Meaning |
|---|---|
| **concurrent** estimate | the adjustment for month $t$ computed when $t$ was the last observation |
| **final** estimate | the adjustment for month $t$ computed from the full sample, where $t$ sits in the interior |
| **revision** | final − concurrent |

The concurrent estimate is what gets published. The final is what turns out to be right. The gap is what people complain about.

## Measure it against a shared reference

This is where the trap from [[20-08-x11-arima]] lives, and it is worth restating because it reverses conclusions:

> [!warning] Never compare a method against its own later vintage
> Comparing each method's concurrent estimate with *its own* estimate two years later measures **self-consistency, not accuracy** — a method that is stably wrong scores perfectly.
>
> Measure every method against **one shared reference**: the full-sample estimate, where the month in question is produced by the symmetric filter.
>
> On `AirPassengers`, the wrong definition says forecast extension is worthless (0.3% improvement); the right one says it cuts revisions by **41%**. Same data, same code.

## The expected size

From the literature, for seasonally adjusted series:

| Horizon | Revision variance reduction |
|---|---|
| after 1 year | −50% |
| after 3 years | −77% |
| after 5 years | −88% |

(Maravall 1996.) So revisions never stop entirely — they decay geometrically as the effective filter becomes more symmetric. A published series is *provisional for years*, which is a fact worth stating to users rather than hiding.

## Why revisions exist at all

Three derivations, all of the same thing, from three modules:

| Module | Statement |
|---|---|
| [[10-14-forecasting]] | the filter needs future values that do not exist |
| [[20-07-end-filters]] | the end filter differs structurally from the interior filter |
| [[30-07-finite-samples]] | the WK filter is doubly infinite and must be completed with forecasts |

If you can say why those are the same statement, you understand the end-of-sample problem properly.

## Reducing revisions — what works and what does not

| Action | Effect |
|---|---|
| forecast extension (X-11-ARIMA) | **large** — 41% on AirPassengers |
| a better ARIMA model | moderate; it improves the forecast |
| modelling outliers and calendar effects properly | moderate; removes contamination |
| a longer seasonal filter | reduces revisions, at the cost of tracking real change more slowly |
| **concurrent vs projected factors** | a policy choice, see below |
| waiting | works, but you have to publish something now |

**Projected factors.** Some agencies compute seasonal factors once a year and apply the projections for the following twelve months, rather than re-estimating every month. This makes the published series *not revise at all* within the year — the revision is deferred to the annual reanalysis, not eliminated. It trades a stream of small revisions for one large annual one. Users generally prefer that, which is a fact about users rather than about statistics.

## Reporting revisions

Publish the revision history. Concretely:

- mean and mean-absolute revision, concurrent → final;
- the distribution, not just the mean — the tails are what damage credibility;
- **revisions conditioned on where in the cycle they occurred**, because they are not uniform ([[50-06-turning-points]]).

That last split is the one almost nobody publishes, and it is the one that would tell users when to distrust the number.

## Numerically

How much will today's number move as data arrives?

Concurrent versus final, on the last few points of the sample:

<!-- run -->
```r
x <- AirPassengers
fin <- as.numeric(series(seas(x, x11 = ""), "d11"))
n <- length(x)
idx <- (n - 6):(n - 1)
conc <- sapply(idx, function(i) {
  z <- ts(as.numeric(x)[1:i], start = start(x), frequency = 12)
  as.numeric(series(seas(z, x11 = ""), "d11"))[i]
})
round(data.frame(t = idx, concurrent = conc, final = fin[idx],
                 pct = 100 * (fin[idx] - conc) / fin[idx]), 3)
```
```text
    t concurrent   final    pct
1 138    480.150 477.793 -0.493
2 139    479.611 477.994 -0.338
3 140    482.071 481.124 -0.197
4 141    482.931 482.666 -0.055
5 142    492.335 489.487 -0.582
6 143    492.427 490.665 -0.359
```
<!-- end -->

## Exercises

*Solutions: [[solutions#50-05-revision-history|worked answers]] in the solutions appendix.*

1. Compute the full revision history for a series: for each month, the concurrent estimate and the full-sample estimate. Plot the difference.
2. Report mean, mean-absolute and the 5th/95th percentiles. How much bigger is the tail than the mean?
3. Repeat with and without forecast extension, measured against the shared reference. Reproduce the 41%.
4. Plot revision size against the horizon (1, 2, 3, 5 years of extra data). Does it decay like Maravall's figures?
5. Compare X-11 and SEATS revisions on the same series. Which is smaller, and does it depend on how well the model fits?

## Links

- Prev: [[50-04-sliding-spans]] · Next: [[50-06-turning-points]]

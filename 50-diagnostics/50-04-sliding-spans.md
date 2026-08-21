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

And the summary rule, in the two tiers X-13 prints for itself:

| Estimate | Too high | Much too high |
|---|---|---|
| seasonal factors (or implied adjustment factors) | 15% | 25% |
| month-to-month changes in the adjusted series | 35% | 40% |
| year-to-year changes | 10% | — |

Above 25% of months flagged on the seasonal factors, the adjustment is unstable and should not be published as is. Note that the month-to-month tolerance is **looser**, not tighter: a month-to-month change is the difference of two noisy numbers, so more of them cross the 3% line by chance and a higher flag rate is unremarkable.

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

The five estimates are lettered `a` through `e`, and the letter is part of the key:

| Key | Estimate | Flag if max difference exceeds |
|---|---|---|
| `s2.a.per` | seasonal factors | 3% |
| `s2.b.per` | trading day factors | 2% |
| `s2.c.per` | final adjusted series — carries the **implied adjustment factors** in an additive run | 3% |
| `s2.d.per` | month-to-month changes in the adjusted series | 3% |
| `s2.e.per` | year-to-year changes | 3% |

Those five cutoffs are the `sscut` key, and they are what the `3, 2, 3, 3, 3` in every run's output means.

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

Five series, out of eleven. The other six produce no percentage at all, and the reason is the subject of the next section — it is not that the diagnostic failed.

## When X-13 emits no percentage at all

Six of the eleven catalogue series come back with no `s2.a.per`, and none of those six is a failure. There are three separate reasons, plus a fourth wrinkle that appears once you work around one of them. They are worth knowing, because the natural response — assume the diagnostic failed, or fall back to a hand-rolled version — is wrong in two of the three cases.

| Series | Mode | `ssdiff` | `s2.pct` | Seasonal factor range | Key emitted |
|---|---|---|---|---|---|
| `airline` | multiplicative | no | yes | 48.87 | `s2.a.per` |
| `ukgas` | multiplicative | no | yes | 126.74 | `s2.a.per` |
| `jj` | multiplicative | no | yes | 37.83 | `s2.a.per` |
| `imp` | multiplicative | no | yes | 27.84 | `s2.a.per` |
| `iip` | multiplicative | no | yes | 16.68 | `s2.a.per` |
| `co2` | multiplicative | no | **no** | **1.97** | none |
| `cpi` | multiplicative | no | **no** | **1.15** | none |
| `temperature` | **additive** | **yes** | — | — | none |
| `unemp` | **additive** | **yes** | — | — | none |
| `accdeaths` | — | — | — | — | `sspans = "failed"` |
| `ldeaths` | — | — | — | — | `sspans = "failed"` |

### Gate 0: the series is too short

`accdeaths` and `ldeaths` return `sspans = "failed"`. Six years cannot be cut into four eight-year spans. This is the limitation described above, and there is nothing to do about it.

### Gate 1: the adjustment is additive

`temperature` and `unemp` are fitted with no transformation, so the adjustment is additive and the seasonal factors are in the units of the series — degrees, persons. A *percentage* difference between two such factors is not a meaningful quantity, and X-13 knows it: the internal flag `Ssdiff` defaults to true and is forced false **only** when the mode is multiplicative, so an additive run compares spans by differences and never computes the percentage summary. The `s2.pct` key is not written at all.

You can override it with `slidingspans.additivesa = "percent"` — see the next gate for what actually comes back.

### Gate 2: the seasonal factors barely move

`co2` and `cpi` are multiplicative and log transformed, so gate 1 does not apply. Their seasonal factors simply do not swing far enough. X-13 averages each calendar month's factor within each span, takes the range of those averages — highest minus lowest, pooled over all spans and all months, reported as the third field of `ssran.all` — and if it is **below 10** it prints

> WARNING: Range of seasonal factors is too low for summary sliding spans measures to be reliable. Summary sliding spans statistics not printed out.

writes `s2.pct: no`, and stops. `co2`'s range is 1.97 and `cpi`'s is 1.15, against a flagging threshold of 3%: the entire seasonal swing of `co2` is smaller than two flags. A percentage of months exceeding 3% would be measuring rounding noise.

The cutoff is a bare literal in the Census source (`ssrng.f`), not a fraction of the threshold or of anything else, and a sweep over a synthetic series with a tunable seasonal amplitude puts it exactly there:

| Seasonal amplitude | Factor range | `s2.pct` | Summary |
|---|---|---|---|
| 6% | 6.17 | no | suppressed |
| 8% | 8.11 | no | suppressed |
| 9% | 9.08 | no | suppressed |
| 10% | 10.05 | **yes** | **printed** |
| 11% | 11.02 | yes | printed |

Same model, same seed, same noise; only the amplitude moves. The flip is between 9.08 and 10.05.

### Gate 3: the letter changes

Force percentages onto an additive run and the summary comes back — but not under `a`:

| Series | `ssdiff` | `s2.pct` | Key | Flagged |
|---|---|---|---|---|
| `temperature` | no | yes | `s2.c.per` | 2.78% (4/144) |
| `unemp` | no | yes | `s2.c.per` | 0.84% (1/119) |

In an additive adjustment the seasonal-factor slot is replaced by the **implied adjustment factors** — original divided by adjusted, a ratio, so a percentage of it means something again — and those live in slot `c`. Code that greps only for `s2.a.per` still finds nothing, and still concludes the diagnostic failed.

> [!warning] What this costs you if you get it wrong
> This vault's own script printed `?%` for six of eleven series before it was audited, and the note you are reading previously said the split was *not* additive-versus-multiplicative and that the real rule was unknown. Both halves of that were wrong: it **is** the additive split for two series, and a documented range cutoff for two more. The lesson is not about sliding spans — it is that "the software returned nothing" is a claim to investigate, not a fact to write down.

> [!tip] The accessor that actually works
> ```r
> ss_stat <- function(u) {
>   for (k in c("s2.a.per", "s2.c.per")) if (k %in% names(u)) return(u[[k]])
>   NULL   # then read ssdiff, s2.pct and sspans to find out which gate closed
> }
> ```

## Exercises

*Solutions: [[solutions#50-04-sliding-spans|worked answers]] in the solutions appendix.*

1. Run sliding spans on `AirPassengers`. What percentage of months are flagged?
2. Do the same for a series with volatile seasonality (`UKgas`, `JohnsonJohnson`). Does the flag rate track $\Theta$?
3. Inject an outlier near a span boundary and watch the flag rate jump. Then model it as an AO and confirm it settles.
4. Shorten a series until sliding spans become unavailable. How much data does the diagnostic actually need?
5. Find a series that passes Q but fails sliding spans, and explain what Q missed.

## Going further

*Harder, and different in kind: predict before you run, break things on purpose, and move the idea to a series it was not built on.*

1. **Predict first.** Will `co2` pass sliding spans? Reason from its $\Theta$ and its length, then check.
2. **Break it.** Shorten a passing series year by year until the diagnostic becomes unavailable. Where is the cliff?
3. **Transfer.** Explain why the two quarterly series fail while the monthly ones pass — is it the frequency, the evolution, or the sample size?

## Practice set

*Drills, output-reading and judgement calls. Short answers; the point is fluency and knowing what you are looking at.*

1. **Drill.** Report the flag rate for four series and mark which exceed 15%.
2. **Read it.** `sspans` returns 'failed'. What does that mean and what would fix it?
3. **Judgement.** A series fails sliding spans but passes everything else. Publish?
4. **Read it.** A run returns `sspans = "yes"`, `ssdiff = "yes"`, and no `s2.pct` key. Which gate closed, and what one argument reopens it?
5. **Read it.** Another run returns `sspans = "yes"`, `ssdiff = "no"`, `s2.pct = "no"`. Which gate closed this time, and which single number would you look at to confirm it?
6. **Drill.** Take a series X-13 declines to summarise and compute the flag rate by hand anyway. Is your number wrong, or just not the number X-13 would have reported?
7. **Judgement.** A colleague's monitoring script flags "sliding spans unavailable" for a third of the production series and treats them all as failures. What is wrong with that, and what should the script report instead?

## Links

- Prev: [[50-03-m-and-q-statistics]] · Next: [[50-05-revision-history]]

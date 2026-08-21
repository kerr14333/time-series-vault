---
aliases: [Seasonal moving averages, 3x3 MA, 3x5 MA, Seasonal filter]
tags: [module-2]
---

# Seasonal moving averages

Code: [[code-20-04-seasonal-moving-averages|`R/20-04-seasonal-moving-averages.R`]]

## The key structural idea

The trend filters of [[20-02-the-12-term-ma]] and [[20-03-henderson-filters]] run **along** the series, month to month. The seasonal filter does something different:

> It runs **across years, within a calendar month.** All the Januaries form one little series; smooth that. Then all the Februaries. And so on, twelve times.

So in terms of the lag operator the seasonal filter is a polynomial in $B^{12}$, not in $B$ — the same distinction as $\Phi(B^{12})$ versus $\phi(B)$ in [[10-09-seasonal-arima]]. The two halves of X-11 mirror the two halves of a seasonal ARIMA, which is a good sign that both are describing the same underlying structure.

## The filters

Named "$p \times q$" meaning a $p$-term MA of a $q$-term MA, applied across years:

| Name | Weights | Span |
|---|---|---|
| 3×3 | $\tfrac{1}{9}(1,2,3,2,1)$ | 5 years |
| 3×5 | $\tfrac{1}{15}(1,2,3,3,3,2,1)$ | 7 years |
| 3×9 | $\tfrac{1}{27}(1,2,3,3,3,3,3,3,3,2,1)$ | 11 years |

Each is a convolution — 3×5 is $\tfrac13(1,1,1)$ convolved with $\tfrac15(1,1,1,1,1)$ — so you can derive the weights rather than memorise them. All sum to 1.

![[20-04-seasonal-ma.png]]

*Drawn by [[figure-index#20-04-seasonal-ma.png|`make-figures.R`]] — code and every other figure in the [[figure-index|figure appendix]].*

Note the x-axis on the left panel: **years**, not months. The right panel shows the actual January SI ratios from `AirPassengers` — the raw values wander, and the choice of filter is the choice of how much of that wandering you treat as signal.

**Longer filter = more stable seasonal pattern, slower to adapt.** This is the exact same trade-off that $\Theta$ controls in the airline model ([[10-10-airline-model]]): how fast is the seasonality allowed to evolve? X-11 expresses it by choosing a filter length; SEATS expresses it by estimating a parameter. Same question, two dialects.

## Choosing the length

X-11 uses the **moving seasonality ratio (MSR)**: average year-to-year change in the SI ratios for a month, divided by the average change in the seasonal factors. Roughly, "how noisy is this month's seasonal pattern relative to how much it genuinely moves".

| MSR | Filter |
|---|---|
| $< 2.5$ | 3×3 |
| $2.5$–$3.5$ | (indeterminate — X-11 widens the window and retests) |
| $3.5$–$5.5$ | 3×5 |
| $> 5.5$ | 3×9 |

The default when nothing is specified is **3×5**. X-13 can also choose per calendar month, so November might get a 3×3 while July gets a 3×9 — sensible, since months differ in how stable their seasonality is.

Also available: `stable` (one fixed factor per month, the mean of all years) at one extreme, and `s3x1` at the other.

## Centring

After smoothing, the twelve monthly factors will not generally average to 1 over a year. Left alone, that leaks a slow drift out of the seasonal component and into the trend. X-11 corrects it by dividing the seasonal factors by a centred 12-term MA of themselves:

$$\hat{S}_t \leftarrow \frac{\hat{S}_t}{\nu_{2\times12}(B)\,\hat{S}_t}$$

Note this is the same $2\times12$ filter from [[20-02-the-12-term-ma]], used for a third purpose. Small step, easy to omit when hand-coding, and omitting it produces a subtle drift that is genuinely hard to diagnose later — so put it in from the start.

## Numerically

Seasonal filters average *across years within a calendar month*, which is a different axis from everything else in X-11.

The 3x3 and 3x5 weight vectors. They are short because there are only so many Januaries:

<!-- run -->
```r
for (ty in c("3x3", "3x5", "3x9")) {
  w <- seasonal_ma(ty)
  cat(sprintf("%-4s length %2d  sum %.6f  weights %s\n",
              ty, length(w), sum(w), paste(round(w, 4), collapse = " ")))
}
```
```text
3x3  length  5  sum 1.000000  weights 0.1111 0.2222 0.3333 0.2222 0.1111
3x5  length  7  sum 1.000000  weights 0.0667 0.1333 0.2 0.2 0.2 0.1333 0.0667
3x9  length 11  sum 1.000000  weights 0.037 0.0741 0.1111 0.1111 0.1111 0.1111 0.1111 0.1111 0.1111 0.0741 0.037
```
<!-- end -->

A longer filter is smoother but slower to react. The gain at the *annual* frequency of the year-over-year series shows the trade-off directly:

<!-- run -->
```r
ff <- seq(0, 0.5, length.out = 6)
round(rbind(freq = ff,
            `3x3` = gain(seasonal_ma("3x3"), ff),
            `3x5` = gain(seasonal_ma("3x5"), ff),
            `3x9` = gain(seasonal_ma("3x9"), ff)), 4)
```
```text
     [,1]   [,2]   [,3]   [,4]   [,5]   [,6]
freq    0 0.1000 0.2000 0.3000 0.4000 0.5000
3x3     1 0.7616 0.2909 0.0162 0.0424 0.1111
3x5     1 0.5648 0.0000 0.0315 0.0000 0.0667
3x9     1 0.0970 0.0599 0.0141 0.0229 0.0370
```
<!-- end -->

## Exercises

*Solutions: [[solutions#20-04-seasonal-moving-averages|worked answers]] in the solutions appendix.*

1. Derive the 3×5 weights by convolving $\tfrac13(1,1,1)$ with $\tfrac15(1,1,1,1,1)$.
2. Take the SI ratios from a decomposition, extract just the Januaries, and smooth them with a 3×3 and a 3×5. Plot both. Which tracks the evolution, which is steadier?
3. Skip the centring step and compare the resulting trend to the centred version. How large is the drift after 10 years?

## Going further

*Harder, and different in kind: predict before you run, break things on purpose, and move the idea to a series it was not built on.*

1. **Predict first.** For a series whose seasonality changes fast, will X-11 want a $3\times3$ or a $3\times9$? Reason it out before checking the moving seasonality ratio.
2. **Break it.** Force a $3\times9$ on a fast-evolving series and check for residual seasonality afterwards.
3. **Transfer.** Extract the Januaries from a quarterly series — there are none. What does the seasonal filter operate on instead?

## Links

- Prev: [[20-03-henderson-filters]] · Next: [[20-05-the-x11-iteration]]

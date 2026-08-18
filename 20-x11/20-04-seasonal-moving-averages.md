---
aliases: [Seasonal moving averages, 3x3 MA, 3x5 MA, Seasonal filter]
tags: [module-2]
---

# Seasonal moving averages

Code: `R/20-04-seasonal-moving-averages.R`

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

## Exercises

1. Derive the 3×5 weights by convolving $\tfrac13(1,1,1)$ with $\tfrac15(1,1,1,1,1)$.
2. Take the SI ratios from a decomposition, extract just the Januaries, and smooth them with a 3×3 and a 3×5. Plot both. Which tracks the evolution, which is steadier?
3. Skip the centring step and compare the resulting trend to the centred version. How large is the drift after 10 years?

## Links

- Prev: [[20-03-henderson-filters]] · Next: [[20-05-the-x11-iteration]]

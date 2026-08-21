---
aliases: [2x12 MA, Centred 12-term moving average, First trend estimate]
tags: [module-2]
---

# The centred 12-term MA — X-11's first move

Code: [[code-20-02-the-12-term-ma|`R/20-02-the-12-term-ma.R`]]

## The filter

$$\nu_{2\times12}(B) = \frac{1}{24}\left(B^{-6} + 2B^{-5} + \cdots + 2B^{5} + B^{6}\right)$$

Thirteen weights: $\tfrac{1}{24}, \tfrac{2}{24}, \tfrac{2}{24}, \ldots, \tfrac{2}{24}, \tfrac{1}{24}$, i.e. $\tfrac{1}{24}(1,2,2,2,2,2,2,2,2,2,2,2,1)$.

They sum to $\tfrac{1}{24}(1 + 2\times11 + 1) = 1$. Good — the level is preserved.

## Why the half-weights on the ends

A plain 12-term average has an even number of terms, so it is centred *between* two months — half a period out of phase. Averaging two consecutive 12-term averages recentres it on a month. That is what "2×12" means: a 2-term MA of a 12-term MA.

$$\frac{1}{2}(1 + B)\cdot\frac{1}{12}(1 + B + \cdots + B^{11})$$

Expand it and the interior terms each get hit twice while the two ends get hit once — hence $1,2,2,\ldots,2,1$. Do this expansion by hand once; it is the same polynomial-multiplication move from [[10-01-lag-operator]].

The payoff is **symmetry**, hence **zero phase** ([[20-01-moving-averages-as-filters]]). An uncentred 12-term MA would shift every turning point by half a month.

## What makes it the right first move

> [!important] It annihilates a 12-month seasonal *exactly*
> Its gain is **exactly zero** at every seasonal frequency $\omega_k = 2\pi k/12$ for $k = 1,\ldots,6$.

![[20-02-2x12-gain.png]]

*Drawn by [[figure-index#20-02-2x12-gain.png|`make-figures.R`]] — code and every other figure in the [[figure-index|figure appendix]].*

Measured, the gain at the six seasonal frequencies is of order $10^{-16}$ — zero to machine precision, not merely small.

Why: the 12-term average of a periodic-with-period-12 pattern is the average of one full cycle, which is that pattern's mean — zero, if the seasonal is centred. Algebraically, $\frac{1}{12}(1 + B + \cdots + B^{11})$ is the $S(B)$ factor from [[10-06-differencing]], and $S(z) = 0$ at every 12th root of unity except $z=1$.

So the very same polynomial keeps reappearing:

| Context | Role of $S(B) = 1 + B + \cdots + B^{11}$ |
|---|---|
| [[10-06-differencing]] | the seasonal half of $(1-B^{12})$ |
| here | the filter that kills seasonality |
| [[40-00-seats-map]] | the AR denominator assigned to the seasonal component |

That is not a coincidence — it is the same mathematical object seen from three sides, and noticing it is a genuine milestone.

## Quarterly: the same filter, shorter

Nothing conceptual changes for quarterly data — only the arithmetic. The general form is a **2xs MA**, a 2-term MA of an s-term MA:

| | Weights | Terms |
|---|---|---|
| monthly, $s=12$ | $\tfrac{1}{24}(1,2,2,\ldots,2,1)$ | 13 |
| quarterly, $s=4$ | $\tfrac{1}{8}(1,2,2,2,1)$ | **5** |

And the seasonal frequencies it must annihilate shrink from six to **two**: $f = 1/4$ and $1/2$ ([[30-01-frequency-domain-basics]]). Measured, the quarterly gain at both is $3\times10^{-17}$ and $0$ — exactly zero, as for monthly.

The helper is `ma_2xs(s)`; `ma_2x12()` is just the monthly case named. Hardcoding 12 is the most common way to get quarterly silently wrong.

## What it gets wrong

It kills seasonality exactly, but it is a blunt instrument for the trend:

- **It also damages the trend.** A 13-term average flattens genuine curvature. At a sharp turning point it undershoots.
- **Its gain is not monotone** — it has side lobes, so some high-frequency noise leaks through with a *negative* sign (a phase flip of $\pi$).
- **It costs six observations at each end.** With 10 years of monthly data you lose the most recent six months, which are the ones anyone cares about.

Hence the iteration: this MA gives a *preliminary* trend, good enough to compute SI ratios from. The trend gets replaced by a **Henderson filter** ([[20-03-henderson-filters]]) once the seasonality is out of the way, and the end-loss gets handled by [[20-07-end-filters]] or by forecast extension ([[20-08-x11-arima]]).

## Exercises

1. Derive the 13 weights by expanding $\frac{1}{2}(1+B)\cdot\frac{1}{12}(1+B+\cdots+B^{11})$ on paper.
2. Plot the gain. Confirm the zeros sit exactly at $k/12$ cycles per month for $k=1..6$, and find the side lobes.
3. Apply it to a pure sine of period 12 plus a straight line. Confirm the sine vanishes and the line survives. Then try period 11 — what leaks through, and why should that worry you?

## Links

- Prev: [[20-01-moving-averages-as-filters]] · Next: [[20-03-henderson-filters]]

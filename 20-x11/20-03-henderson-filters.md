---
aliases: [Henderson filter, Henderson trend filter, I/C ratio]
tags: [module-2, key]
---

# Henderson filters

Code: `R/20-03-henderson-filters.R`

The trend-cycle filter in X-11. Older than X-11 itself — Robert Henderson, 1916, working on actuarial graduation.

## The design criterion

Henderson asked a precise question: among all symmetric filters of length $2m+1$ that **reproduce a cubic polynomial exactly**, which one produces the **smoothest** output?

"Smoothest" is made concrete as: minimise the sum of squared **third differences** of the filter weights,

$$\min \sum_j \left(\nabla^3 w_j\right)^2 \quad\text{subject to}\quad \sum_j w_j = 1,\ \ \sum_j j\,w_j = \sum_j j^2 w_j = \sum_j j^3 w_j = 0$$

The constraints are exactly "passes a cubic through untouched". Solve that constrained least-squares problem and you get a closed form.

## The closed form

For a $(2m+1)$-term filter, let $n = m+2$. Then for $j = -m,\ldots,m$:

$$w_j = \frac{315\left[(n-1)^2 - j^2\right]\left[n^2 - j^2\right]\left[(n+1)^2 - j^2\right]\left[3n^2 - 16 - 11j^2\right]}{8n\,(n^2-1)(4n^2-1)(4n^2-9)(4n^2-25)}$$

The script computes this and checks it against the published 13-term weights. Verify it yourself rather than trusting the formula — it is easy to mistype and the failure is silent.

The 13-term weights, for reference:

$$(-0.019,\ -0.028,\ 0,\ 0.066,\ 0.147,\ 0.214,\ \mathbf{0.240},\ 0.214,\ 0.147,\ 0.066,\ 0,\ -0.028,\ -0.019)$$

## Two features worth noticing

**Negative weights at the ends.** They are what allow the filter to follow curvature instead of flattening it — the filter sharpens as well as smooths. They are also why a Henderson trend can occasionally overshoot beyond the range of the data, which surprises people the first time they see it.

**It does *not* kill seasonality — not remotely.** Measure the gain of the 13-term filter at the six seasonal frequencies and you get:

$$(0.846,\ 0.110,\ 0.016,\ 0.002,\ 0.007,\ 0.008) \quad\text{at}\quad \omega_k = 2\pi k/12,\ k=1..6$$

At the **fundamental annual frequency** the gain is $0.85$ — an annual cycle passes through almost untouched. Only the higher harmonics get damped.

> [!warning] So the order of operations is not a stylistic choice
> Apply a Henderson filter to a raw seasonal series and 85% of the annual swing lands in your "trend". In X-11 the Henderson filter is only ever applied to a series that has **already** been seasonally adjusted — by the $2\times12$ MA of [[20-02-the-12-term-ma]], whose gain at those frequencies is exactly zero.
>
> Seasonal first, Henderson second. The two filters do different jobs and neither substitutes for the other.

## Choosing the length

Longer filter = smoother trend = more damage to genuine short movements. X-11 picks the length automatically from the **I/C ratio** — the average absolute month-to-month change in the irregular divided by that of the trend-cycle:

| I/C ratio (monthly) | Henderson length |
|---|---|
| $< 1.0$ | 9-term |
| $1.0 \le I/C < 3.5$ | 13-term |
| $\ge 3.5$ | 23-term |

Noisy series get a longer filter, which is the right instinct: more noise to average away. Quarterly data uses 5- or 7-term filters.

This ratio is computed from a preliminary decomposition, which is one of several reasons X-11 must iterate — you cannot choose the filter until you have an estimate, and you cannot get a good estimate until you have chosen the filter.

## Where it breaks

The Henderson filter is symmetric, so it needs $m$ observations on each side. For a 13-term filter that is six months of future data you do not have at the end of the sample. X-11's answer is a set of **asymmetric surrogate filters** (Musgrave), and those end weights differ *sharply* from the interior weights.

> [!warning] This is the mechanism behind turning-point failure
> The distortion appears **at** the turn, not before it, because it is the end filter — not the interior filter — that is doing the work there. Carry this into [[20-07-end-filters]] and [[50-06-turning-points]].

## Exercises

1. Implement the closed form. Confirm it reproduces the published 13-term weights to 3 decimals.
2. Verify the cubic-reproducing property numerically: apply the filter to $t^3$ and confirm you get $t^3$ back (in the interior).
3. Plot gains for the 9-, 13- and 23-term filters on one axis. Where do they differ most, and what does that imply about the smoothness/responsiveness trade-off?
4. Compute the gain at the six seasonal frequencies and confirm the 0.85 at the fundamental. Then apply a 13-term Henderson directly to raw `AirPassengers` and look at the "trend" you get.

## Links

- Prev: [[20-02-the-12-term-ma]] · Next: [[20-04-seasonal-moving-averages]]

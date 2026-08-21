---
aliases: [Henderson filter, Henderson trend filter, I/C ratio]
tags: [module-2, key]
---

# Henderson filters

Code: [[code-20-03-henderson-filters|`R/20-03-henderson-filters.R`]]

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

![[20-03-henderson.png]]

*Drawn by [[figure-index#20-03-henderson.png|`make-figures.R`]] — code and every other figure in the [[figure-index|figure appendix]].*

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

## Quarterly lengths

The same closed form, but the menu of lengths is different — and getting this wrong is a **silent** error, because a 13-term Henderson on quarterly data spans over three years and simply oversmooths.

| Data | I/C ratio | Henderson length |
|---|---|---|
| monthly | $<1.0$ / $1.0$–$3.5$ / $\ge3.5$ | 9 / 13 / 23 |
| **quarterly** | $<1.0$ / $\ge1.0$ | **5 / 7** |

The 5-term weights are $(-0.073,\ 0.294,\ 0.559,\ 0.294,\ -0.073)$ — same shape as the monthly ones, negative at the ends, summing to 1. `henderson_length(ic, s)` takes the period so the right table is used.

**What the mistake costs.** Forcing the monthly 13-term filter onto `UKgas` (which should get 7) changes the trend by up to **10.2%**. That is not a subtlety — it is a visibly different published series, produced by code that runs without complaint.

## Where it breaks

The Henderson filter is symmetric, so it needs $m$ observations on each side. For a 13-term filter that is six months of future data you do not have at the end of the sample. X-11's answer is a set of **asymmetric surrogate filters** (Musgrave), and those end weights differ *sharply* from the interior weights.

> [!warning] This is the mechanism behind turning-point failure
> The distortion appears **at** the turn, not before it, because it is the end filter — not the interior filter — that is doing the work there. Carry this into [[20-07-end-filters]] and [[50-06-turning-points]].

## Numerically

Henderson filters are chosen to be smooth, not to remove seasonality. Both halves of that matter.

The weights are a closed form, and they sum to 1. Note they go *negative* at the ends — that is what makes them sharper than a plain average:

<!-- run -->
```r
round(henderson(9), 5)
cat("sum:", sum(henderson(13)), "  negative weights:", sum(henderson(13) < 0), "\n")
```
```text
sum: 1   negative weights: 4 
```
<!-- end -->

They reproduce a cubic exactly. That is the design criterion — feed in a polynomial of degree 3 and it comes back unchanged:

<!-- run -->
```r
h <- henderson(13); m <- (length(h) - 1) / 2; j <- -m:m
for (deg in 0:4) cat(sprintf("  t^%d reproduced: max error %.3e\n",
                             deg, abs(sum(h * j^deg) - (deg == 0))))
```
```text
  t^0 reproduced: max error 0.000e+00
  t^1 reproduced: max error 0.000e+00
  t^2 reproduced: max error 2.220e-16
  t^3 reproduced: max error 0.000e+00
  t^4 reproduced: max error 6.923e+01
```
<!-- end -->

But the gain at the annual frequency is **0.85**, not zero. A Henderson filter is a low-pass smoother; removing seasonality is not its job:

<!-- run -->
```r
round(rbind(freq = seas_freq(12),
            H9  = gain(henderson(9),  seas_freq(12)),
            H13 = gain(henderson(13), seas_freq(12)),
            H23 = gain(henderson(23), seas_freq(12))), 4)
```
```text
       [,1]   [,2]   [,3]   [,4]   [,5]   [,6]
freq 0.0833 0.1667 0.2500 0.3333 0.4167 0.5000
H9   0.9520 0.5397 0.0128 0.0329 0.0286 0.0267
H13  0.8456 0.1095 0.0160 0.0015 0.0066 0.0079
H23  0.3478 0.0107 0.0027 0.0015 0.0012 0.0011
```
<!-- end -->

## Exercises

*Solutions: [[solutions#20-03-henderson-filters|worked answers]] in the solutions appendix.*

1. Implement the closed form. Confirm it reproduces the published 13-term weights to 3 decimals.
2. Verify the cubic-reproducing property numerically: apply the filter to $t^3$ and confirm you get $t^3$ back (in the interior).
3. Plot gains for the 9-, 13- and 23-term filters on one axis. Where do they differ most, and what does that imply about the smoothness/responsiveness trade-off?
4. Compute the gain at the six seasonal frequencies and confirm the 0.85 at the fundamental. Then apply a 13-term Henderson directly to raw `AirPassengers` and look at the "trend" you get.

## Links

- Prev: [[20-02-the-12-term-ma]] · Next: [[20-04-seasonal-moving-averages]]

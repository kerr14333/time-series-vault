---
aliases: [X-11 iteration, B tables, C tables, D tables, D11]
tags: [module-2, key]
---

# The X-11 iteration

Code: [[code-20-05-the-x11-iteration|`R/20-05-the-x11-iteration.R`]] — this is where you build a working X-11.

## Why iterate at all

Every filter in X-11 needs an input it does not have yet:

- To estimate the seasonal you must first remove the trend.
- To estimate the trend well (Henderson) you must first remove the seasonal.
- To choose the Henderson length you need the I/C ratio, which needs a decomposition.
- To choose the seasonal filter length you need the MSR, which needs seasonal factors.
- To downweight extreme values you need the irregular, which needs both other components.

Circular. The escape is to start crude and refine: use the blunt $2\times12$ MA to get a first trend, and go around the loop. Three passes is enough in practice, and that is what X-11 does.

## The loop, stripped down

Multiplicative case, $Z = T \times S \times I$. (Additive is identical with $-$ and $\div$ swapped for $+$ and $\times$; taking logs converts one to the other.)

```text
1.  T1  = 2x12 MA of Z                    # crude trend, kills seasonality exactly
2.  SI  = Z / T1                          # seasonal + irregular
3.  S1  = 3x3 MA of SI, by calendar month # seasonal
4.  S1  = S1 / (2x12 MA of S1)            # centre it
5.  A1  = Z / S1                          # first seasonally adjusted series
6.  T2  = Henderson MA of A1              # proper trend, length from I/C ratio
7.  SI  = Z / T2                          # better SI ratios
8.      -- detect and replace extreme values in SI --
9.  S2  = 3x5 MA of SI, by calendar month # final seasonal, length from MSR
10. S2  = S2 / (2x12 MA of S2)            # centre
11. A2  = Z / S2                          # FINAL seasonally adjusted series   -> D11
12. T3  = Henderson MA of A2              # FINAL trend-cycle                  -> D12
13. I   = A2 / T3                         # FINAL irregular                    -> D13
```

Steps 6–13 are the same shape as 1–5, run again on better inputs. That is the whole method.

![[20-05-decomposition.png]]

*Drawn by [[figure-index#20-05-decomposition.png|`make-figures.R`]] — code and every other figure in the [[figure-index|figure appendix]].*

## The table names

X-13 prints intermediate results with letter-number codes. They look cryptic and are actually just "which pass, which quantity":

| Prefix | Pass |
|---|---|
| **B** | first pass — preliminary estimates, prior adjustments applied |
| **C** | second pass — with extreme values downweighted |
| **D** | third pass — final |

The ones you will actually use:

| Table | Contents |
|---|---|
| **D10** | final seasonal factors |
| **D11** | final seasonally adjusted series |
| **D12** | final trend-cycle |
| **D13** | final irregular |
| B1 | the series after prior adjustments |
| C17 | the final weights used for extreme values |

> [!important] D-tables vs S-tables
> `D10`–`D13` are the **X-11** outputs. SEATS writes `s10`–`s13` and `s16` for the corresponding quantities. Same meanings, different engine — and X-13 can produce both from the same run, which is the easiest way to compare the two methods on one series. See [[50-09-x11-vs-seats]].

## Getting the composite filter

Because every step is linear (ignoring the extreme-value step, which is not), the whole thing composes into **one** symmetric filter, per [[20-01-moving-averages-as-filters]]. Two ways to recover it:

1. **Algebraically** — multiply the polynomials through. Tedious but exact.
2. **Numerically** — feed X-11 a series that is zero everywhere except a single 1 at the middle. What comes out *is* the filter's weights. This impulse-response trick is far easier and it works on any implementation, including a black box.

Do (2) in the script. Then plot the gain and you will see the notches at the seasonal frequencies. At that point X-11 has become a single object you can compare directly with the SEATS filters of [[40-06-wk-filters-for-the-airline-model]].

![[20-05-composite-gain.png]]

*Drawn by [[figure-index#20-05-composite-gain.png|`make-figures.R`]] — code and every other figure in the [[figure-index|figure appendix]].*

This is the picture to remember. The whole of X-11 — three passes, five different moving averages — collapses into **one** symmetric filter that passes everything except six narrow notches at the seasonal frequencies. Note also the negative weights at $\pm12$ in the impulse response: to remove this January's seasonality, X-11 leans on neighbouring Januaries with a *negative* sign.

## It all generalises to quarterly

`x11_decompose()` reads the period off the series, so the same loop runs on quarterly data with the 2x4 MA and a 5- or 7-term Henderson. Checked against the real X-13:

| Series | $s$ | d10 | d11 | d12 |
|---|---|---|---|---|
| `AirPassengers` | 12 | 0.52% | 0.52% | 0.61% |
| `UKgas` | **4** | 0.75% | 0.75% | 1.03% |
| `JohnsonJohnson` | **4** | 0.76% | 0.75% | 0.92% |

Interior mean absolute differences. Quarterly agreement is as good as monthly, which is the point: nothing about the method is special to 12.

## What this simplified version omits

Be honest about the gap between what you build and what X-13 runs:

- calendar effects — trading day, moving holidays (these come from regARIMA, [[10-12-estimation]])
- prior adjustments and user-supplied factors
- automatic filter-length selection re-tested across passes
- the full extreme-value machinery ([[20-06-extreme-values]])
- asymmetric end filters ([[20-07-end-filters]]) — the simplified version just loses observations at the ends
- forecast extension ([[20-08-x11-arima]])

The script quantifies the resulting discrepancy against real X-13 output rather than hand-waving it.

## Numerically

The whole algorithm, run on the real thing.

Our hand-coded X-11 against the Census binary on `AirPassengers`, split into the **interior** (where the symmetric filters apply) and the **ends** (where they cannot). Report the two separately — quoting a single number here is how you end up claiming either far better or far worse agreement than you have:

<!-- run -->
```r
z  <- AirPassengers
ours <- x11_decompose(z)
ref  <- seas(z, x11 = "", transform.function = "log",
             arima.model = "(0 1 1)(0 1 1)", regression.aictest = NULL,
             outlier = NULL)
for (tb in c("d10", "d11", "d12")) {
  a <- as.numeric(ours[[tb]]); b <- as.numeric(series(ref, tb))
  n <- length(a); int <- 13:(n - 12)          # a year clear of each end
  pd <- 100 * abs(a - b) / abs(b)
  cat(sprintf("  %s  interior mean %5.2f%%   interior max %5.2f%%   ends max %5.2f%%\n",
              tb, mean(pd[int]), max(pd[int]), max(pd[-int])))
}
```
```text
  d10  interior mean  0.52%   interior max  3.83%   ends max  4.37%
  d11  interior mean  0.52%   interior max  3.98%   ends max  4.57%
  d12  interior mean  0.61%   interior max  2.41%   ends max  2.44%
```
<!-- end -->

Half a percent through the middle, and roughly **nine times worse at the ends**. That gap is not sloppiness in either implementation — it is the end-filter problem ([[20-07-end-filters]]) showing up as a number. Any two X-11 implementations agree where the symmetric filter applies and disagree where each has to improvise.

The identity the whole method rests on — the pieces multiply back to the original:

<!-- run -->
```r
cat("max |z - D10*D11| :",
    format(max(abs(as.numeric(z) - as.numeric(ours$d10) * as.numeric(ours$d11)))), "\n")
cat("max |D11 - D12*D13|:",
    format(max(abs(as.numeric(ours$d11) - as.numeric(ours$d12) * as.numeric(ours$d13)))), "\n")
```
```text
max |z - D10*D11| : 5.684342e-14 
max |D11 - D12*D13|: 5.684342e-14 
```
<!-- end -->

## Exercises

*Solutions: [[solutions#20-05-the-x11-iteration|worked answers]] in the solutions appendix.*

1. Build the loop. Compare your D11 to `seasonal::series(m, "d11")` — report the max absolute percentage difference.
2. Recover the composite filter by the impulse trick. Do the weights sum to 1? Are they symmetric?
3. Plot the composite gain. Mark the seasonal frequencies. How deep are the notches, and how wide?
4. Run the loop for 1, 2 and 3 passes. How much does the answer move each time? Is a fourth pass worth it?

## Links

- Prev: [[20-04-seasonal-moving-averages]] · Next: [[20-06-extreme-values]]

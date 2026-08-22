---
aliases: [Implementing SEATS, SEATS from scratch, The build]
tags: [module-4, key]
---

# Implementing SEATS

Code: [[code-_seats|`R/_seats.R`]] (the engine) and `R/40-07-implementing-seats-in-r.R` (the walkthrough)

**This is the goal you set at the start.** Everything else in the vault exists to make this note possible.

## The whole algorithm

```text
 1. fit the ARIMA                          -> theta, Theta, sigma_a^2
 2. split the AR side by root location     -> (1-B)^2 for trend, S(B) for seasonal
 3. build cosine polynomials N, D_T, D_S   -> |MA|^2 and the two |AR|^2
 4. partial fractions: N = A*D_S + C*D_T + D*D_T*D_S
 5. check all three components are non-negative        (admissibility)
 6. canonical: subtract each minimum, give it to the irregular
 7. WK filters: nu_T = (A - m_T D_T) D_S / N, etc.
 8. invert to weights; extend the series with forecasts and backcasts;
    apply the symmetric filters; keep the original span
 9. normalise the constant between trend and seasonal
```

Nine steps. Steps 1–7 are algebra on a handful of short vectors; step 8 is one convolution; step 9 is a convention. There is no hidden difficulty — which is worth saying, because SEATS has a reputation for being impenetrable and it is not.

## The result

Run on `AirPassengers` with $\theta = 0.4018$, $\Theta = 0.5569$, and compare against the actual Census Bureau binary:

| X-13 table | Meaning | Max difference |
|---|---|---|
| `s10` | seasonal factors | **0.000%** |
| `s11` | seasonally adjusted | **0.001%** |
| `s12` | trend | **0.012%** |
| `s13` | irregular | **0.010%** |

A from-scratch R implementation reproducing forty-year-old Fortran to within a hundredth of a percent. If you can get here, you understand SEATS.

![[40-07-decomposition.png]]

*Drawn by [[figure-index#40-07-decomposition.png|`make-figures.R`]] — code and every other figure in the [[figure-index|figure appendix]].*

## The four traps

I hit three of these building it. They are the note's real content, because each produces output that looks plausible.

### 1. Truncation shows up as a level offset

The WK weights are infinite in extent and must be truncated. Truncate too early and the weights no longer sum to $\nu(0)$ — and since the trend filter must sum to 1 and the seasonal to 0, the error appears as a **constant offset** in the components rather than as noise.

Symptom: your seasonal correlates with the reference at 0.999 but sits a fixed distance away.

The required length depends on $\Theta$, not on the series length:

| $\Theta$ | lags needed | years |
|---|---|---|
| 0.30 | 60 | 5 |
| 0.557 | 331 | **27.6** |
| 0.80 | 600+ | 50+ |

For `AirPassengers` — 144 observations — the correct filter is **331 lags each side**. The filter is far longer than the data. That is normal, not a mistake: the far weights multiply forecast values that contribute almost nothing.

### 2. The extension must be at least as long as the filter

If you extend by 60 but filter with 120 lags, the convolution has no valid range at the original endpoints and you get **all `NA`** — or worse, silent `NA`s in the middle of otherwise fine output. Assert it:

```r
stopifnot(extend >= max_lag)
```

### 3. The constant between trend and seasonal is a convention, not a result

$\nu_S(0) = 0$, so the seasonal filter annihilates constants — meaning the theory **cannot say** whether a constant belongs to the trend or the seasonal. Something must decide.

X-13 normalises multiplicative factors to average **1 in levels**, which in logs forces a mean of about $-\sigma^2/2$, not 0. Skip this and everything is off by a constant:

```text
our log-seasonal mean      0.000539     (theory: 0)
X-13 log-seasonal mean    -0.008243
-var/2 of the log factors -0.008206     <- matches to 4e-5
resulting discrepancy      0.88% in s10, s11 and s12 alike
```

The tell is that `s10`, `s11` and `s12` are *all* off by the same amount while `s13` is exact. A constant, not an error.

### 4. Sign conventions

The algebra manipulates $\theta(B)\theta(F)$ directly, so a flipped MA sign gives component spectra that are wrong but still look plausible. Convert once, at the boundary, and never guess ([[10-11-sign-conventions]]).

## The checks that catch everything else

Run all of these; each caught a real bug during development:

| Check | Expected | Catches |
|---|---|---|
| partial-fraction residual | $<10^{-12}$ | degree bookkeeping errors |
| $\nu_T+\nu_S+\nu_I$ | $1$ at every $\omega$ | numerator errors |
| $\sum$ trend weights | $1$ | truncation |
| $\sum$ seasonal weights | $0$ | truncation |
| $T + S + I$ | $= \log z$ exactly | anything in step 8 |
| component minima | $\ge 0$ | inadmissibility |

The reconstruction identity $T+S+I=\log z$ is the single best end-to-end test: it is sensitive to every step and needs no reference implementation.

## What this build does not do

Be clear about the scope of what you have:

- **Airline model only.** A general implementation must handle arbitrary $(p,d,q)(P,D,Q)$, assign stationary AR roots to trend/seasonal/transitory by **frequency and modulus**, and produce a fourth **transitory** component. The structure generalises; the bookkeeping grows. [[40-10-general-seats]] does it, and [[40-11-validating-general-seats]] is what it took to get the assignment rule right.
- **No regARIMA preadjustment** — no trading day, holidays or outliers. In practice those are removed first and added back after.
- **No mean/drift handling.** For $d=D=1$ there is no constant, so `AirPassengers` sidesteps it. A model with a mean requires care: SEATS keeps it *in* the series it decomposes and folds the drift into the **trend**.
- **Forecast extension, not Burman's algorithm.** Same answer, more compute.
- **No component standard errors.**

## Numerically

The finished thing, on the running example.

Decompose, then check the identity that must hold by construction:

<!-- run -->
```r
d <- seats_decompose(lap, 0.4018, 0.5569)
recon <- as.numeric(d$trend) + as.numeric(d$seasonal) + as.numeric(d$irregular)
cat("max |log z - (T + S + I)| =", format(max(abs(as.numeric(lap) - recon))), "\n")
```
```text
max |log z - (T + S + I)| = 4.571512 
```
<!-- end -->

And the seasonal factors average 1 in levels — X-13's normalisation convention, which is a *choice*, not a theorem:

<!-- run -->
```r
cat("mean of exp(seasonal) :", round(mean(exp(as.numeric(d$seasonal))), 8), "\n")
cat("mean of log seasonal  :", round(mean(as.numeric(d$seasonal)), 6),
    " (not zero -- that is the convention)\n")
```
```text
mean of exp(seasonal) : 1 
mean of log seasonal  : -0.00026  (not zero -- that is the convention)
```
<!-- end -->

## Exercises

*Solutions: [[solutions#40-07-implementing-seats-in-r|worked answers]] in the solutions appendix.*

1. Run the walkthrough and reproduce the table of differences.
2. Break it deliberately: set `max_lag = 60` and confirm the 0.88%-style constant offset appears. Then set `normalize = FALSE` and confirm a *different* constant offset.
3. Decompose `co2` ($\Theta = 0.912$). How many lags does the rule demand? Does it still match X-13?
4. Decompose a quarterly series (`UKgas`, `JohnsonJohnson`) with $s=4$. What changes in the degree bookkeeping?
5. Feed it `cpi` and confirm the admissibility check fires ([[40-02-admissible-decompositions]]).
6. Time it as a function of `max_lag`. Where is the cost, and how would Burman's algorithm avoid it?

> [!abstract] Derivation
> - [[derivations#D10. Why the WK filters have no poles|why no special case is needed at the unit roots]]

## Going further

*Harder, and different in kind: predict before you run, break things on purpose, and move the idea to a series it was not built on.*

1. **Predict first.** For `co2` ($\Theta = 0.912$), how many lags will the rule demand? Guess, then run `seats_max_lag()`.
2. **Break it.** Set `extend` shorter than `max_lag` and see the guard fire. Why is that guard there rather than a silent truncation?
3. **Transfer.** Decompose a quarterly series and check the identity and the X-13 agreement both still hold.

## Practice set

*Drills, output-reading and judgement calls. Short answers; the point is fluency and knowing what you are looking at.*

1. **Drill.** Decompose three catalogue series and report the four X-13 agreement numbers for each.
2. **Drill.** Report `seats_max_lag()` for each and convert to years.
3. **Read it.** Every value comes back `NA`. What is the first thing to check?

## Links

- Prev: [[40-06-wk-filters-for-the-airline-model]] · Next: [[40-08-validating-against-x13]]

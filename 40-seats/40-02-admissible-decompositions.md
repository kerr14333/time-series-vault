---
aliases: [Admissibility, Admissible region, Inadmissible decomposition]
tags: [module-4, key]
---

# Admissible decompositions

Code: [[code-40-02-admissible-decompositions|`R/40-02-admissible-decompositions.R`]]

Not every ARIMA model can be split into components. This note maps exactly which ones can, and shows a real series where it fails.

## The constraint

The partial fractions of [[40-04-partial-fractions-in-b-and-f]] always *solve* — it is a square linear system. But the solution is only meaningful if each piece is a genuine spectrum, and a spectrum must be **non-negative at every frequency** ([[30-02-spectral-density]]).

$$f_T(\omega)\ge0,\qquad f_S(\omega)\ge0,\qquad f_I(\omega)\ge0 \quad\text{for all }\omega$$

A negative spectrum means a negative variance. There is no such thing. When the algebra produces one, the model **admits no decomposition into independent non-negative components** — it is *inadmissible*.

## Mapping the region

Scan $(\theta,\Theta)$ over $[-0.95, 0.95]^2$ and test all three components. Result:

| Quadrant (Census signs) | Admissible |
|---|---|
| $\theta > 0,\ \Theta > 0$ | **100.0%** |
| $\theta < 0,\ \Theta < 0$ | 2.8% |
| $\theta < 0,\ \Theta > 0$ | 1.3% |
| $\theta > 0,\ \Theta < 0$ | 0.5% |
| **overall** | **27.4%** |

> [!important] The rule worth memorising
> For the airline model, admissibility is essentially **"both MA parameters positive in the Census convention"**. Only about a quarter of the parameter space is admissible, and almost all of it sits in the positive quadrant.

Now recall [[10-11-sign-conventions]]: *well-behaved economic series give positive Census-convention MA parameters.* So real economic data usually lands in the admissible quadrant — which is why you can adjust hundreds of series and never meet this problem, and why a course built on `AirPassengers` alone would never mention it.

## A real failure

Testing every series in [[series-catalogue]] under a forced airline model:

| Series | $\theta$ | $\Theta$ | $\min f_T$ | $\min f_S$ | $\min f_I$ | Verdict |
|---|---|---|---|---|---|---|
| `AirPassengers` | 0.402 | 0.557 | 0.0514 | 0.0225 | 0.2238 | admissible |
| `co2` | 0.360 | 0.912 | 0.0935 | 0.0008 | 0.3283 | admissible |
| `UKgas` | 0.919 | 0.235 | 0.0089 | 0.0422 | 0.2163 | admissible |
| `unemp` | 0.028 | 0.765 | 0.1821 | 0.0026 | 0.0211 | admissible, but close |
| **`cpi`** | **−0.086** | 0.592 | 0.1789 | 0.0047 | **−0.0511** | **INADMISSIBLE** |

`cpi` (Swiss CPI) is the **only** inadmissible series in the catalogue. It is also the **only** one with a negative $\theta$. And independently — without being told any of this — the real X-13 binary reports on that same series:

```text
Model used in SEATS is different: (1 1 2)(1 0 1)
```

Three facts agreeing: negative $\theta$ → our algebra gives a negative irregular spectrum → Census's Fortran refuses the fitted model and substitutes another. That is as close to confirmation as this kind of thing gets.

## What SEATS does about it

It does not stop. It **replaces the model with a nearby admissible one** and carries on, printing a note.

> [!warning] The components did not come from the model you fitted
> When SEATS changes the model, your careful regARIMA identification — the AICC comparisons, the residual diagnostics, the outlier tests — applied to a model that was then **discarded for the decomposition**. The trend and seasonal you receive come from a different model, one you did not choose and were not asked about.
>
> Always check for this. In R:
> ```r
> m <- seas(x)
> udg(m, "seatsmdl")        # what SEATS actually used
> m$model$arima$model       # what regARIMA fitted
> ```
> If they differ, say so in any write-up. Most people never look.

The `seats.noadmiss` spec controls it: `"yes"` (default) replaces the model, `"no"` makes it an error instead.

## Which component fails, and why

Across the grid scan the irregular went negative most often (722 cells), then the trend (599), then the seasonal (546).

The irregular is the usual casualty, and there is an intuition for it. The irregular's spectrum is the **constant** $D$ in the partial fraction — the flat floor under everything else. If the fitted model implies a spectrum with less power at high frequencies than the trend and seasonal components jointly require, the leftover flat part comes out negative. Negative $\theta$ does exactly that: it puts a *peak* rather than a trough at high frequency, leaving nothing for the irregular.

![[40-02-admissible-region.png]]

*Drawn by [[figure-index#40-02-admissible-region.png|`make-figures.R`]] — code and every other figure in the [[figure-index|figure appendix]].*

Every point in the $(\theta,\Theta)$ plane is a possible airline model; blue means a canonical decomposition exists. The pattern is stark and worth memorising: **the positive quadrant is entirely admissible and almost nothing else is.**

`AirPassengers` sits comfortably inside. Real fitted models overwhelmingly land in that quadrant, which is why inadmissibility is rare in practice — but `cpi` has $\theta = -0.086$, lands in the grey, and is the one catalogue series where X-13 quietly substitutes a different model.

## Numerically

Not every model can be decomposed. The region is smaller than you would guess.

Sweep the (theta, Theta) grid and ask which points admit a canonical decomposition:

<!-- run -->
```r
ok <- function(th, Th) {
  sp <- seats_ar_split(1, 1, 12)
  isTRUE(tryCatch({
    pf <- seats_partial_fractions(airline_ma(th, Th), sp$trend, sp$seas)
    seats_canonical(pf)$admissible
  }, error = function(e) FALSE))
}
g <- c(-0.9, -0.6, -0.3, 0.3, 0.6, 0.9)
M <- outer(g, g, Vectorize(ok))
dimnames(M) <- list(theta = g, Theta = g)
cat("admissible fraction of this grid:", round(mean(M), 3), "\n")
M
```
```text
admissible fraction of this grid: 0.25 
      Theta
theta   -0.9  -0.6  -0.3   0.3   0.6   0.9
  -0.9 FALSE FALSE FALSE FALSE FALSE FALSE
  -0.6 FALSE FALSE FALSE FALSE FALSE FALSE
  -0.3 FALSE FALSE FALSE FALSE FALSE FALSE
  0.3  FALSE FALSE FALSE  TRUE  TRUE  TRUE
  0.6  FALSE FALSE FALSE  TRUE  TRUE  TRUE
  0.9  FALSE FALSE FALSE  TRUE  TRUE  TRUE
```
<!-- end -->

The pattern is not subtle: both parameters positive is always admissible, and almost nothing else is:

<!-- run -->
```r
cat("theta > 0 AND Theta > 0 :", round(mean(M[g > 0, g > 0]), 3), "\n")
cat("theta < 0 (any Theta)   :", round(mean(M[g < 0, ]), 3), "\n")
cat("any Theta < 0           :", round(mean(M[, g < 0]), 3), "\n")
cat("Fitted models overwhelmingly land in the positive quadrant, which is\n")
cat("why inadmissibility is rare in practice but not impossible.\n")
```
```text
theta > 0 AND Theta > 0 : 1 
theta < 0 (any Theta)   : 0 
any Theta < 0           : 0 
Fitted models overwhelmingly land in the positive quadrant, which is
why inadmissibility is rare in practice but not impossible.
```
<!-- end -->

## Exercises

*Solutions: [[solutions#40-02-admissible-decompositions|worked answers]] in the solutions appendix.*

1. Reproduce the region map. Mark `AirPassengers` on it.
2. Find the admissible boundary along $\Theta = 0.5$: at what $\theta$ does it fail, and which component goes negative first?
3. Test the catalogue and confirm `cpi` is the only failure.
4. Run `seas()` on `cpi` and read `udg(m, "seatsmdl")`. Compare with the fitted model.
5. Set `seats.noadmiss = "no"` on `cpi` and observe the error instead of the substitution.
6. Quarterly: is the admissible region for $s=4$ the same shape?

> [!abstract] Derivation
> - [[derivations#D9. The canonical decomposition, and why it is a convention|the one-parameter family and admissibility]]

## Going further

*Harder, and different in kind: predict before you run, break things on purpose, and move the idea to a series it was not built on.*

1. **Predict first.** Will a model with $\theta$ slightly negative and $\Theta = 0.9$ be admissible? Guess from the region map, then test.
2. **Break it.** Find the $\theta$ at which admissibility fails along $\Theta = 0.7$, and identify which component's spectrum goes negative first.
3. **Transfer.** Map the admissible region for $s = 4$ and compare its shape with the monthly one.

## Practice set

*Drills, output-reading and judgement calls. Short answers; the point is fluency and knowing what you are looking at.*

1. **Drill.** Test admissibility at nine $(\theta,\Theta)$ points spread over the four quadrants.
2. **Drill.** For `cpi`, report the fitted $\theta$ and say why it fails.
3. **Read it.** `udg(m, 'seatsmdl')` differs from the model you fitted. What happened?

## Links

- Prev: [[40-01-unobserved-components-and-reduced-form]] · Next: [[40-03-canonical-decomposition]]
- Data: [[series-catalogue]] · Signs: [[10-11-sign-conventions]]

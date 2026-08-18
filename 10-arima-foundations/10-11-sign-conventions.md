---
aliases: [Sign conventions, MA sign trap]
tags: [module-1, gotcha]
---

# Sign conventions — the trap

Code: [[code-10-11-sign-conventions|`R/10-11-sign-conventions.R`]]

Not deep, but it will silently corrupt your work if you skip it, and it is impossible to debug a SEATS implementation without having this straight.

## The AR side: everyone agrees

$$\phi(B) = 1 - \phi_1 B - \cdots - \phi_p B^p$$

Minus signs, so that $z_t = \phi_1 z_{t-1} + \cdots$. R, Census, every textbook: same.

## The MA side: two camps

| Convention | Polynomial | Used by |
|---|---|---|
| **Census / Box–Jenkins** | $\theta(B) = 1 - \theta_1 B - \cdots$ | X-13ARIMA-SEATS, TRAMO/SEATS, Box & Jenkins, most SA literature |
| **Plus** | $\theta(B) = 1 + \theta_1 B + \cdots$ | `stats::arima()`, `forecast`, `statsmodels`, Brockwell & Davis |

$$\boxed{\ \theta^{\text{Census}} = -\,\theta^{\text{R}}\ }$$

So a healthy airline fit on `log(AirPassengers)` prints in R as roughly

```text
ma1 = -0.40    sma1 = -0.61
```

and the *same model* appears in X-13 output as

```text
Nonseasonal MA  0.40     Seasonal MA  0.61
```

Both positive in the Census convention. Rule of thumb: **for well-behaved economic series, Census-convention airline MA parameters come out positive.** If yours are negative, suspect a sign flip before you suspect the data.

## Where it bites

1. Reading a paper's $\theta$ into R code, or vice versa.
2. Computing $\psi$- or $\pi$-weights by hand — the recursion sign changes.
3. **Implementing SEATS.** The canonical decomposition manipulates $\theta(B)\theta(F)$ directly; get the convention wrong and the component spectra come out wrong in a way that still *looks* plausible. This is the most expensive version of the mistake.

## Defensive habits

- State the convention at the top of every script and every note. This vault is **Census convention** unless a note says otherwise.
- Write one converter and use it everywhere:
  ```r
  ma_r_to_census <- function(ma) -ma
  ```
- Sanity-test on a case where you know the sign: MA(1) with $\rho_1 < 0$ implies $\theta^{\text{Census}} > 0$ (from $\rho_1 = -\theta/(1+\theta^2)$).

## Also worth knowing

- **`seasonal::seas()` reports Census convention** (it is a wrapper around the real X-13 binary), while `arima()` reports R convention. Same package ecosystem, different signs. Check this yourself in the script — do not take my word for it.
- Some sources define $\Theta$ on $B^{s}$ and others on $B$ with zero-padding. Harmless, but changes what "lag 12 coefficient" means when you read raw output.

## Links

- Prev: [[10-10-airline-model]] · Next: [[10-12-estimation]]

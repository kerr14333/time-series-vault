---
aliases: [Invertibility, Non-invertible, Unit MA root]
tags: [module-1]
---

# Invertibility — and why anyone cares

Code: [[code-10-05-invertibility|`R/10-05-invertibility.R`]]

## Definition

An MA is **invertible** when $\theta(B)$ can be inverted into a convergent AR($\infty$):

$$\pi(B) z_t = a_t, \qquad \pi(B) = \frac{1}{\theta(B)} = 1 - \pi_1 B - \pi_2 B^2 - \cdots$$

with $\sum|\pi_j| < \infty$. The condition is the exact mirror of stationarity ([[10-02-stationarity-and-roots]]):

> **All roots of $\theta(z) = 0$ lie strictly outside the unit circle.**

For MA(1), root $= 1/\theta$, so invertible iff $|\theta| < 1$.

## Three reasons it matters

**1. It picks a unique model.** From [[10-04-ma-processes]]: $\theta$ and $1/\theta$ have the same ACF. Exactly one of the pair is invertible ($|\theta|<1$). Convention: always report the invertible one. Estimation routines enforce it, sometimes silently — which is why an estimate can pin itself at 0.999.

**2. You need the $\pi$-weights to forecast.** You never observe $a_t$; you infer it from past $z$'s. That inference *is* $\pi(B)z_t = a_t$. If the $\pi$-weights diverge, the shocks are not recoverable from the observed history and the forecast recursion has no stable starting point. Non-invertible = the past does not determine the innovation.

**3. It controls how much the past matters.** For MA(1), $\pi_j = -\theta^j$: the AR($\infty$) weights decay at rate $\theta$. Small $\theta$ → the model is nearly white noise. $\theta \to 1$ → the model remembers essentially everything.

## The boundary case, and why it is the most important case in this vault

What happens at $\theta = 1$ exactly?

$$z_t = (1-B)a_t$$

The MA has a **unit root at $z=1$** — non-invertible, right on the boundary. Two facts:

- Its spectrum is **zero** at frequency 0 (see [[30-00-spectral-map]]). A $(1-B)$ factor annihilates anything constant, so the process contains no zero-frequency power at all.
- If you difference an *already stationary* series you get exactly this: over-differencing induces a non-invertible unit MA root. That is the diagnostic — a $\theta$ estimate pinned at 1 usually means you differenced once too many. Check it before you believe the model.

> [!important] Why SEATS lives on this boundary deliberately
> The **canonical decomposition** in SEATS chooses each component to have *minimum* variance, which is the same as making each component's spectrum touch zero somewhere. A spectrum that touches zero is precisely a component with a **non-invertible (unit) MA root**.
>
> So: canonical components are non-invertible **by construction**. This is not a numerical accident and it is not a bug in your implementation when you see it — it is the definition. Every canonical SEATS trend has a spectral zero at $\pi$; every canonical seasonal has zeros between the seasonal frequencies.

When you get to [[40-00-seats-map]] and see a unit MA root come out of the decomposition, come back and reread this box. It is the single most confusing thing in SEATS for people who learned ARIMA first, because ARIMA training teaches you that unit MA roots are a *symptom of a mistake*. In SEATS they are the *goal*.

## Seen in real data: `ldeaths`

Not a simulation. Monthly UK lung-disease deaths, 72 observations. Force the airline model on it and **both** MA coefficients come back at $0.9999$ — pinned on the non-invertible boundary.

Left to choose its own model, X-13 picks $(0,0,1)(0,1,1)_{12}$: **$d = 0$, no regular differencing at all.** The pinned coefficient was not a numerical quirk; it was the model reporting that the regular difference should never have been taken.

Three independent diagnostics agree:

```text
1. both MA coefficients pin at 0.9999          (this note)
2. AIC prefers d=0:  -82.52  vs  -81.99        (10-13)
3. the regular difference INCREASES variance:  (10-06)
     log(ldeaths)              0.0812
     after (1-B^12)            0.0189   <- stop here
     after (1-B)(1-B^12)       0.0349   <- worse
```

Worth internalising, because the airline model is such a reliable default that it is easy to apply it without looking. `ldeaths` is the case where the default is wrong and says so clearly — if you check.

## Numerically

Two different MA(1) models can produce the *same* autocorrelations. That is the problem invertibility solves.

$\theta$ and $1/\theta$ give an identical ACF, so the data cannot tell them apart:

<!-- run -->
```r
rho <- function(th) -th / (1 + th^2)
for (th in c(0.5, 2, 0.8, 1.25))
  cat(sprintf("theta = %5.2f  rho1 = %7.4f\n", th, rho(th)))
```
```text
theta =  0.50  rho1 = -0.4000
theta =  2.00  rho1 = -0.4000
theta =  0.80  rho1 = -0.4878
theta =  1.25  rho1 = -0.4878
```
<!-- end -->

The tie-break is the $\pi$-weights: writing the MA back as an infinite AR. For $|\theta|<1$ they die; for $|\theta|>1$ they explode:

<!-- run -->
```r
pi_w <- function(th, n = 8) th^(1:n)
round(rbind(`theta=0.5` = pi_w(0.5), `theta=2.0` = pi_w(2)), 3)
```
```text
          [,1] [,2]  [,3]   [,4]   [,5]   [,6]    [,7]    [,8]
theta=0.5  0.5 0.25 0.125  0.062  0.031  0.016   0.008   0.004
theta=2.0  2.0 4.00 8.000 16.000 32.000 64.000 128.000 256.000
```
<!-- end -->

## Exercises

1. Compute the first 8 $\pi$-weights for $\theta = 0.5$ and for $\theta = 0.95$. Plot both.
2. Simulate white noise, difference it, fit an MA(1). What $\theta$ comes back? Now fit `arima(x, c(0,1,1))` to plain white noise repeatedly — how often does it pin at the boundary?
3. Argue in one sentence why "over-differenced" and "non-invertible" are the same statement.

## Links

- Prev: [[10-04-ma-processes]] · Next: [[10-06-differencing]]
- Payoff: [[40-00-seats-map]], [[30-00-spectral-map]]

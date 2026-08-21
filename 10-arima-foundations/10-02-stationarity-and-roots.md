---
aliases: [Stationarity, Unit root, Characteristic roots]
tags: [module-1]
---

# Stationarity and polynomial roots

Code: [[code-10-02-stationarity-and-roots|`R/10-02-stationarity-and-roots.R`]]

## Weak stationarity

A series is **weakly (covariance) stationary** when three things hold for all $t$:

1. $E[z_t] = \mu$ — constant mean
2. $\mathrm{Var}(z_t) = \sigma^2 < \infty$ — constant, finite variance
3. $\mathrm{Cov}(z_t, z_{t-k}) = \gamma_k$ — covariance depends on the **gap** $k$ only, not on *when*

Point 3 is the load-bearing one. It says the series' internal correlation structure is the same in 1950 as in 1960. If that holds you can pool the whole sample to estimate $\gamma_k$, which is why every estimator in the field assumes it.

Airline passengers is not stationary on any of the three counts: the level rises, the seasonal swings get wider, and therefore the covariances change over time. Logs fix #2 (multiplicative seasonality becomes additive), differencing fixes #1 and #3. See [[10-06-differencing]].

## Why roots

Write an AR(p): $\phi(B) z_t = a_t$ with

$$\phi(B) = 1 - \phi_1 B - \phi_2 B^2 - \cdots - \phi_p B^p$$

To solve for $z_t$ you want to invert $\phi(B)$:

$$z_t = \frac{1}{\phi(B)} a_t = \psi(B) a_t$$

That infinite series $\psi(B)$ converges — the shocks fade out — only under a condition on $\phi$. State it via the **characteristic equation**, obtained by replacing $B$ with a complex number $z$:

$$\phi(z) = 1 - \phi_1 z - \cdots - \phi_p z^p = 0$$

> [!important] The condition
> The process is stationary **iff every root of $\phi(z)=0$ lies strictly outside the unit circle**, i.e. $|z_i| > 1$ for all roots.

For AR(1), $\phi(z) = 1 - \phi z$, root $z = 1/\phi$. "Outside the unit circle" means $|1/\phi| > 1$, i.e. $|\phi| < 1$. The familiar condition, recovered.

## The mirror-image convention trap

Half the literature writes the polynomial in $z^{-1}$ instead, and states the condition as "all roots **inside** the unit circle". Both are correct; they are describing reciprocal numbers. What is never ambiguous:

> The *inverse* roots must have modulus $< 1$.

R's `polyroot()` gives you the roots of $\phi(z)$ in the "outside" convention. When in doubt, test AR(1) with $\phi=0.5$: you know the answer, so you can tell which convention you are in.

## Unit roots

A root exactly **on** the unit circle ($|z| = 1$) is a **unit root**. Then the shocks never fade — the process has infinite memory, the variance grows without bound, and it is nonstationary.

- Root at $z = 1$ → factor $(1-B)$ → a **stochastic trend** (random walk). Frequency 0.
- Roots at the seasonal frequencies → factor $(1-B^{12})$ → a **stochastic seasonal**.

This is the connection that makes SEATS possible, so it is worth stating loudly:

> [!important] The key link to seasonal adjustment
> **Unit roots are where the components live.** A unit root at frequency 0 is trend. Unit roots at $2\pi k/12$ are seasonal. Everything left over is irregular. SEATS is, at bottom, the procedure of sorting the roots of the fitted ARIMA into those three bins and turning each bin into a filter.

Hold that thought until [[40-00-seats-map]]. It is the whole plot.

## Explosive is not the same as nonstationary

$|\phi| > 1$ gives an explosive process — theoretically nonstationary too, but never used in this field. In practice "nonstationary" means unit roots, which is why differencing (not detrending by regression) is the standard fix.

## Numerically

Roots, on the machine. The rule is *modulus greater than 1*, and it is worth watching a series cross the line.

Three AR(1) polynomials $1-\phi B$. The root is $1/\phi$, so the root leaves the unit circle exactly when $|\phi|<1$:

<!-- run -->
```r
for (phi in c(0.5, 0.95, 1.01)) {
  pr <- poly_roots(c(1, -phi))      # returns a data.frame: root, modulus, period
  cat(sprintf("phi = %5.2f  |root| = %6.3f  %s\n", phi, pr$modulus,
              if (all(pr$modulus > 1)) "stationary" else "NOT stationary"))
}
```
```text
phi =  0.50  |root| =  2.000  stationary
phi =  0.95  |root| =  1.053  stationary
phi =  1.01  |root| =  0.990  NOT stationary
```
<!-- end -->

An AR(2) with complex roots — a cycle rather than a decay. Modulus and angle together give the period:

<!-- run -->
```r
poly_roots(c(1, -1.6, 0.9))   # 1 - 1.6B + 0.9B^2, a complex pair
```
```text
                  root modulus freq_rad period
1 0.8888889+0.5665577i  1.0541   0.5675 11.073
2 0.8888889-0.5665577i  1.0541  -0.5675 11.073
```
<!-- end -->

## Exercises

1. Is $\phi(B) = 1 - 1.2B + 0.5B^2$ stationary? Find the roots by hand ($z = \frac{1.2 \pm \sqrt{1.44 - 2}}{1}$… careful, do it properly) and check with `polyroot(c(1, -1.2, 0.5))`. Note the roots are complex — what does that imply about the ACF?
2. What are the 12 roots of $1 - B^{12} = 0$? Where are they on the unit circle? Convert each to a frequency in cycles per year.
3. Why can you *not* make a nonstationary series stationary by subtracting a fitted straight line, when the nonstationarity comes from a unit root?

## Links

- Prev: [[10-01-lag-operator]] · Next: [[10-03-ar-processes]]
- Mirror concept on the MA side: [[10-05-invertibility]]
- Payoff: [[40-00-seats-map]]

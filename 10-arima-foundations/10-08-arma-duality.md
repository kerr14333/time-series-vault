---
aliases: [ARMA duality, Wold decomposition]
tags: [module-1]
---

# ARMA duality — one object, two views

Code: `R/10-08-arma-duality.R`

$$\phi(B) z_t = \theta(B) a_t$$

## The two infinite representations

$$\underbrace{z_t = \frac{\theta(B)}{\phi(B)}a_t = \psi(B)a_t}_{\text{MA}(\infty)\ -\ \text{shock view}} \qquad \underbrace{\frac{\phi(B)}{\theta(B)}z_t = \pi(B)z_t = a_t}_{\text{AR}(\infty)\ -\ \text{forecast view}}$$

The first exists iff **stationary**; the second iff **invertible**. When both hold, they are two descriptions of one process, and you switch between them freely by polynomial division.

- The $\psi$-weights answer *"what does a shock do to the future?"* → impulse response, forecast error variance ([[10-14-forecasting]]).
- The $\pi$-weights answer *"what does the past say about today's shock?"* → the forecast recursion, and how X-13 extends a series at the ends.

## Why mixed ARMA at all

Parsimony. A slowly-decaying ACF might need AR(6) or MA(10) alone, but ARMA(1,1) captures it with two parameters. Fewer parameters → lower estimation variance → less noisy seasonal factors → smaller revisions. In seasonal adjustment, parsimony is not aesthetics, it is variance control.

## Wold decomposition — the licence for all of this

**Any** covariance-stationary process with no deterministic component can be written as

$$z_t = \sum_{j \ge 0}\psi_j a_{t-j}, \qquad \psi_0 = 1,\ \sum \psi_j^2 < \infty$$

with $a_t$ uncorrelated. That is a theorem, not an assumption. It says an MA($\infty$) is *general* — nothing is being given up by working inside this class.

ARMA's role: $\theta(B)/\phi(B)$ is a compact rational approximation to a general $\psi(B)$, in the same way a rational function approximates an arbitrary function. That framing — **rational transfer functions** — is exactly the language of Module 3, where spectra are ratios of polynomials evaluated on the unit circle. Duality here becomes partial-fraction decomposition there, and partial fractions are the mechanical heart of SEATS.

## Common factors

If $\phi(B)$ and $\theta(B)$ share a root, cancel it. ARMA(2,2) with a shared root *is* ARMA(1,1), and leaving it in makes the likelihood flat along a ridge — the optimiser wanders, standard errors blow up, and estimates look unstable between vintages.

Symptom: near-identical AR and MA roots in the fitted output, or standard errors much larger than the coefficients. Fix: drop the order. X-13's automatic model selection has explicit guards against this.

## Exercises

1. Compute the first 12 $\psi$-weights of ARMA(1,1), $\phi=0.7$, $\theta=0.4$ (Census sign), by equating coefficients in $\phi(B)\psi(B) = \theta(B)$. Check with `ARMAtoMA()`.
2. Same model, get the $\pi$-weights from $\theta(B)\pi(B) = \phi(B)$.
3. Fit ARMA(2,2) to data simulated from ARMA(1,1) and inspect the roots. Find the common factor.

## Links

- Prev: [[10-07-acf-and-pacf]] · Next: [[10-09-seasonal-arima]]
- Becomes: [[30-00-spectral-map]]

---
aliases: [Glossary]
tags: [meta]
---

# Glossary

Symbols first, because most confusion in this field is notation collisions between authors.

| Symbol | Means | Note | Where |
|---|---|---|---|
| $B$ | backshift / lag operator, $Bx_t = x_{t-1}$ | some authors write $L$ | [[10-01-lag-operator]] |
| $F$ | forward operator, $Fx_t = x_{t+1}$, $F = B^{-1}$ | appears in two-sided filters | [[30-00-spectral-map]] |
| $\nabla$ | $1-B$, first difference | $\nabla_s = 1-B^s$ is the seasonal one | [[10-06-differencing]] |
| $\phi(B)$ | regular AR polynomial, order $p$ | $1 - \phi_1 B - \cdots$ | [[10-03-ar-processes]] |
| $\theta(B)$ | regular MA polynomial, order $q$ | $1 - \theta_1 B - \cdots$ (Census sign) | [[10-04-ma-processes]] |
| $\Phi(B^s), \Theta(B^s)$ | seasonal AR/MA polynomials, orders $P, Q$ | same shape, in $B^s$ | [[10-09-seasonal-arima]] |
| $d, D$ | regular and seasonal differencing orders | the "I" in ARIMA | [[10-06-differencing]] |
| $s$ | seasonal period | 12 monthly, 4 quarterly | |
| $a_t$ | the innovation / white-noise shock, variance $\sigma_a^2$ | Census calls it $a_t$, many texts $\varepsilon_t$ | |
| $z_t$ | the observed series | often already logged | |
| $\psi_j$ | MA($\infty$) weights, $z_t = \psi(B)a_t$ | what a shock does to the future | [[10-14-forecasting]] |
| $\pi_j$ | AR($\infty$) weights, $\pi(B)z_t = a_t$ | what the past says about today's shock | [[10-05-invertibility]] |

## Words

- **Stationary** — mean, variance and autocovariances do not depend on $t$. [[10-02-stationarity-and-roots]]
- **Invertible** — the MA part can be rewritten as a convergent AR($\infty$). [[10-05-invertibility]]
- **Unit root** — a root of a polynomial at $z=1$ (or on the unit circle). The reason you difference.
- **Airline model** — $(0,1,1)(0,1,1)_s$. [[10-10-airline-model]]
- **regARIMA** — regression terms (trading day, holiday, outliers) + ARIMA errors. What X-13 fits before adjusting.
- **Linearized series** — the series after subtracting the regression effects. This is what gets decomposed.
- **Pseudo-spectrum** — the "spectrum" of a nonstationary ARIMA; infinite at some frequencies. The central object in SEATS.
- **Canonical decomposition** — the unique split that gives the irregular the most variance possible. [[40-00-seats-map]]

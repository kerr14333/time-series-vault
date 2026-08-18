---
aliases: [Airline model, (0,1,1)(0,1,1)]
tags: [module-1, key]
---

# The airline model

Code: [[code-10-10-airline-model|`R/10-10-airline-model.R`]]

$$(1-B)(1-B^{12})\,z_t \;=\; (1-\theta B)(1-\Theta B^{12})\,a_t$$

$\text{ARIMA}(0,1,1)(0,1,1)_{12}$. Two parameters. Know this model cold — the entire SEATS worked example in [[40-00-seats-map]] is built on it, and it is the default model X-13 falls back to.

## Why it is the default

- Left side: a **double unit root at frequency 0** (from $(1-B)$ and from the $(1-B)$ hidden inside $(1-B^{12})$) plus the 11 seasonal unit roots. So it accommodates a level that drifts, a slope that drifts, and a seasonal pattern that drifts. That is most economic data.
- Right side: two MA parameters, enough to control *how fast* each of those drifts.
- It is the ARIMA representation of a very natural unobserved-components model — see below — which is why it does not feel arbitrary once you know that.

## What the parameters mean

Both live in $[0,1]$ in practice (Census sign convention, [[10-11-sign-conventions]]).

| | $\theta \to 0$ | $\theta \to 1$ |
|---|---|---|
| $\theta$ (regular) | trend is a pure random walk, wanders freely | trend nearly deterministic, very smooth |
| $\Theta$ (seasonal) | seasonal pattern re-rolls every year | seasonal pattern nearly fixed |

Sanity anchor: $\Theta = 1$ *exactly* cancels the seasonal part of $(1-B^{12})$ — the seasonal unit roots are annulled, and the "stochastic seasonal" becomes deterministic. So $\Theta$ measures how much the seasonality is allowed to evolve. High $\Theta$ (0.6–0.9 is typical) → stable seasonality → small revisions. Low $\Theta$ → volatile seasonality → the seasonal factors will move around every time you rerun.

That mapping — a coefficient you can read off X-13 output, telling you how much your seasonal factors will revise — is the first genuinely *useful* thing ARIMA gives you here.

## The unobserved-components connection

Consider the "basic structural model": local linear trend + stochastic seasonal + noise. If you apply $\nabla\nabla_{12}$ to it, the result is a stationary process whose autocovariances vanish after lag 13 and match those of $(1-\theta B)(1-\Theta B^{12})a_t$ over a wide region of the parameter space.

That is the bridge:

> **A structural model you can describe in English has an ARIMA reduced form. SEATS runs that bridge backwards** — fit the ARIMA, then recover the components it must have come from.

Reading the airline model as "trend + seasonal + noise, differenced" makes the whole of Module 4 feel like an inevitability instead of a trick.

## Acceptable region

Not every $(\theta, \Theta)$ pair yields a valid decomposition. There is an **admissible region** in the parameter space; outside it, SEATS cannot produce non-negative component spectra and falls back to an approximating model. You will map that region yourself in [[40-00-seats-map]] — it is one of the more satisfying exercises in the sequence.

## Exercises

1. Fit the airline model to `log(AirPassengers)` with `arima()`. Convert the reported MA coefficients to Census sign. What do $\theta$ and $\Theta$ say about this series?
2. Simulate the airline model at $(\theta,\Theta) = (0.4, 0.6)$ and at $(0.9, 0.95)$. Plot both. Which looks more like real economic data?
3. Set $\Theta = 1$ in a simulation. Confirm the seasonal pattern stops evolving.

## Links

- Prev: [[10-09-seasonal-arima]] · Next: [[10-11-sign-conventions]]
- The whole point: [[40-00-seats-map]]

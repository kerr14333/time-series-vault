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

## Two series where the default is wrong

The airline model is such a good default that it is easy to apply without checking. Two cases from [[series-catalogue]] where it should not be:

**`ldeaths`** — forcing it pins both MA coefficients at $0.9999$. X-13 picks $(0,0,1)(0,1,1)$: **no regular difference**. See [[10-05-invertibility]].

**`nottem`** — monthly Nottingham temperatures. X-13 picks $(1,0,0)(1,1,1)_{12}$ with **no log transform** and no regular differencing. Two habits broken at once:

- *Logs are not automatic.* Temperature has no multiplicative structure and can be negative in principle; the log/level test correctly says no.
- *Seasonality is not always stochastic.* The seasonal cycle here is driven by the Earth's orbit, so it genuinely is fixed. This is the one case where deterministic seasonal dummies would be right, and $\Theta \to 1$ is the airline model's way of saying so.

`nottem` is the useful limiting case for the whole "how much does the seasonal evolve" question. Everything else in this vault sits between it and a series like `UKgas` ($\Theta = 0.235$), whose pattern re-rolls almost every year.

## Acceptable region

Not every $(\theta, \Theta)$ pair yields a valid decomposition. There is an **admissible region** in the parameter space; outside it, SEATS cannot produce non-negative component spectra and falls back to an approximating model. You will map that region yourself in [[40-00-seats-map]] — it is one of the more satisfying exercises in the sequence.

## Numerically

The model this whole vault is built on, fitted.

Fit $(0,1,1)(0,1,1)_{12}$ to log `AirPassengers`. Remember R's MA sign is the opposite of Census's:

<!-- run -->
```r
fit <- arima(lap, order = c(0, 1, 1),
             seasonal = list(order = c(0, 1, 1), period = 12))
round(coef(fit), 4)
cat("Census convention: theta =", round(-coef(fit)[1], 4),
    " Theta =", round(-coef(fit)[2], 4), "\n")
```
```text
Census convention: theta = 0.4018  Theta = 0.5569 
```
<!-- end -->

Both MA roots sit outside the unit circle, so the fitted model is invertible — the condition SEATS needs later:

<!-- run -->
```r
th <- -coef(fit)[1]; Th <- -coef(fit)[2]
cat("|root| of 1 - theta B    :", poly_roots(c(1, -th))$modulus, "\n")
cat("|roots| of 1 - Theta B^12:",
    unique(poly_roots(c(1, rep(0, 11), -Th))$modulus), "\n")
cat("all greater than 1, so the fitted model is invertible\n")
```
```text
|root| of 1 - theta B    : 2.4886 
|roots| of 1 - Theta B^12: 1.05 
all greater than 1, so the fitted model is invertible
```
<!-- end -->

## Exercises

*Solutions: [[solutions#10-10-airline-model|worked answers]] in the solutions appendix.*

1. Fit the airline model to `log(AirPassengers)` with `arima()`. Convert the reported MA coefficients to Census sign. What do $\theta$ and $\Theta$ say about this series?
2. Simulate the airline model at $(\theta,\Theta) = (0.4, 0.6)$ and at $(0.9, 0.95)$. Plot both. Which looks more like real economic data?
3. Set $\Theta = 1$ in a simulation. Confirm the seasonal pattern stops evolving.

## Going further

*Harder, and different in kind: predict before you run, break things on purpose, and move the idea to a series it was not built on.*

1. **Predict first.** For a series whose seasonal pattern you can see is very stable, predict whether $\Theta$ will be near 0 or near 1. Then fit and check.
2. **Transfer.** Fit the airline model to every catalogue series and tabulate $(\theta, \Theta)$. Which has the most stable seasonality?
3. Explain to someone else, in three sentences, why the airline model is the default despite being only one model among many.

## Practice set

*Drills, output-reading and judgement calls. Short answers; the point is fluency and knowing what you are looking at.*

1. **Drill.** Fit the airline model to three catalogue series and tabulate $(\theta, \Theta)$ in Census signs.
2. **Read it.** $\Theta = 0.95$. Describe the seasonality in one sentence, and predict the revision behaviour.
3. **Read it.** $\Theta = 0.15$. Same two questions.
4. **Judgement.** The airline model fits badly and the residual ACF spikes at lag 2. What do you try next?

## Links

- Prev: [[10-09-seasonal-arima]] · Next: [[10-11-sign-conventions]]
- The whole point: [[40-00-seats-map]]

---
aliases: [Estimation, Maximum likelihood, Kalman filter]
tags: [module-1]
---

# Estimation — how the parameters get found

Code: `R/10-12-estimation.R`

You mostly do not need to implement this to do SEATS, but you need to know what the numbers you
are handed actually are, and which knob to turn when a fit misbehaves.

## Three methods, in increasing order of correctness

**1. Method of moments / Yule–Walker.** Solve the Yule–Walker equations
([[10-03-ar-processes]]) for $\phi$ from the sample ACF. Works for pure AR, closed form, fast.
Poor for MA. Used as a starting value.

**2. Conditional sum of squares (CSS).** Set the pre-sample shocks to zero, run the model
forward to get $\hat a_t$, minimise $\sum \hat a_t^2$. Cheap and robust. Biased when the MA
roots are near the unit circle — which for seasonal data is exactly where you live.

**3. Exact maximum likelihood.** Put the ARIMA in state-space form, run the **Kalman filter**
to get the exact Gaussian likelihood including the pre-sample contribution, and optimise
numerically. This is what `arima(method="ML")` and X-13 both do by default.

## Why exact ML matters here

Seasonal MA parameters sit near 1 ($\Theta \approx 0.6\!-\!0.9$ is normal). Near the
boundary the CSS approximation degrades and the estimate is biased toward the interior.
Since $\Theta$ controls how much your seasonal factors revise ([[10-10-airline-model]]), a
biased $\Theta$ means systematically wrong revision behaviour. Hence: exact ML.

## Practical failure modes

| Symptom | Likely cause |
|---|---|
| MA coefficient pinned at $\pm1$ | over-differenced ([[10-05-invertibility]]) |
| Huge standard errors, unstable across vintages | common AR/MA factor ([[10-08-arma-duality]]) |
| Optimiser will not converge | too many parameters, or bad starting values, or outliers |
| Estimates jump when one observation is added | outlier near the end, or a genuinely fragile model |

X-13 addresses the last one directly by detecting **outliers** (AO / LS / TC) as regression
terms before estimating the ARIMA. An undetected level shift will wreck an ARIMA fit and, via
the fit, wreck the seasonal factors — this is one of the main reasons regARIMA exists.

## regARIMA, briefly

$$z_t = \sum_i \beta_i x_{it} + n_t, \qquad \phi(B)\Phi(B^s)\nabla^d\nabla_s^D\, n_t = \theta(B)\Theta(B^s)a_t$$

Regressors $x_{it}$: trading-day, leap-year, moving holidays (Easter), outliers, user
variables. The $\beta$'s and the ARIMA parameters are estimated **jointly** by exact ML — not
in two stages — because the ARIMA structure determines the correct weighting for the
regression.

The output that matters downstream is the **linearized series**: $z_t$ minus the estimated
regression effects. That is what gets seasonally adjusted.

> [!warning] Exception worth remembering
> The **constant/mean term is not removed** the way trading-day and outlier effects are. SEATS
> keeps the mean inside the series it decomposes, centres the differenced series by it, and
> folds it back so the **trend** carries the drift. Getting this wrong produces a trend error
> that grows toward the sample ends — a distinctive diagnostic signature. Revisit in
> [[40-00-seats-map]].

## Exercises

1. Fit the airline model to `log(AirPassengers)` with `method="ML"` and `method="CSS"`. Compare
   $\Theta$. Which is closer to 1?
2. Insert an artificial level shift into the series, refit, and watch the ARIMA parameters move.
   Then add the level shift as a regressor via `xreg=` and confirm they come back.
3. Fit an over-parameterised model and inspect the standard errors.

## Links

- Prev: [[10-11-sign-conventions]] · Next: [[10-13-model-selection]]

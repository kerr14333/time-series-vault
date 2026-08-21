---
aliases: [Estimation, Maximum likelihood, Kalman filter]
tags: [module-1]
---

# Estimation — how the parameters get found

Code: [[code-10-12-estimation|`R/10-12-estimation.R`]]

You mostly do not need to implement this to do SEATS, but you need to know what the numbers you are handed actually are, and which knob to turn when a fit misbehaves.

## Three methods, in increasing order of correctness

**1. Method of moments / Yule–Walker.** Solve the Yule–Walker equations ([[10-03-ar-processes]]) for $\phi$ from the sample ACF. Works for pure AR, closed form, fast. Poor for MA. Used as a starting value.

**2. Conditional sum of squares (CSS).** Set the pre-sample shocks to zero, run the model forward to get $\hat a_t$, minimise $\sum \hat a_t^2$. Cheap and robust. Biased when the MA roots are near the unit circle — which for seasonal data is exactly where you live.

**3. Exact maximum likelihood.** Put the ARIMA in state-space form, run the **Kalman filter** to get the exact Gaussian likelihood including the pre-sample contribution, and optimise numerically. This is what `arima(method="ML")` and X-13 both do by default.

## Why exact ML matters here

Seasonal MA parameters sit near 1 ($\Theta \approx 0.6\!-\!0.9$ is normal). Near the boundary the CSS approximation degrades and the estimate is biased toward the interior. Since $\Theta$ controls how much your seasonal factors revise ([[10-10-airline-model]]), a biased $\Theta$ means systematically wrong revision behaviour. Hence: exact ML.

## What is actually being maximised

"Exact maximum likelihood" sounds forbidding. The idea underneath is small: **the likelihood is built out of one-step-ahead forecast errors.**

Factor the joint density of the sample by the chain rule — the density of the first point, times the density of the second given the first, and so on:

$$L = p(z_1)\,p(z_2\mid z_1)\,p(z_3\mid z_2,z_1)\cdots$$

Each conditional density is Gaussian, centred on the one-step forecast $\hat z_{t|t-1}$ with some variance $v_t$. Writing $e_t = z_t - \hat z_{t|t-1}$ for the one-step error,

$$-2\log L = \sum_{t=1}^{n}\left[\log(2\pi v_t) + \frac{e_t^2}{v_t}\right]$$

That is the **prediction-error decomposition**, and it is all the Kalman filter is for: given a candidate $(\theta,\Theta)$, walk through the series producing $\hat z_{t|t-1}$ and $v_t$ at each step, including the awkward opening ones where there is barely any history to forecast from. Feed the results into the sum. That number is what the optimiser is handed.

So the loop is: *pick parameters → filter the series → get a number → adjust → repeat.*

### The variance is free

You might expect a three-parameter search over $(\theta, \Theta, \sigma_a^2)$. There is not, because $\sigma_a^2$ can be solved for exactly. Writing $v_t = \sigma_a^2 r_t$, where $r_t$ depends only on the ARIMA parameters,

$$\hat\sigma_a^2 = \frac1n\sum_t \frac{e_t^2}{r_t}$$

Substituting back leaves a function of $(\theta,\Theta)$ alone. This is called **concentrating** the likelihood, and it is why the airline model's search is over a two-dimensional surface — a surface small enough to simply draw:

![[10-12-likelihood-surface.png]]

*Drawn by [[figure-index#10-12-likelihood-surface.png|`make-figures.R`]] — code and every other figure in the [[figure-index|figure appendix]].*

**Left:** the concentrated log-likelihood over the $(\theta,\Theta)$ plane, in R's sign convention. The optimiser starts somewhere and walks uphill; the red dot is where it stops. Contours that are closed and roughly elliptical around the peak are what a well-identified model looks like.

**Right:** a slice through the peak along $\Theta$, back in Census signs. The curvature at the top is the whole story for inference — **a sharply curved peak means a small standard error, a flat one means a large one.** Standard errors are computed exactly this way, from the second derivatives (the Hessian) at the optimum.

That also explains the failure modes below. A common AR/MA factor ([[10-08-arma-duality]]) turns the peak into a *ridge* — a long flat line of nearly equal likelihood — so the optimiser wanders along it, standard errors inflate, and the estimate jumps between vintages. Nothing is broken; the surface genuinely has no single best point.

### Why CSS is not good enough here

Conditional sum of squares sets the pre-sample shocks to zero and minimises $\sum\hat a_t^2$. In the decomposition above, that amounts to discarding the $\log v_t$ term and pretending every $v_t$ is equal — an approximation whose error is concentrated at the *start* of the series and fades as $n$ grows.

Except when an MA root sits near the unit circle. Then the pre-sample contribution stays material at any sample length, and the two methods do not converge on the same answer. Seasonal MA parameters live near that boundary ($\Theta \approx 0.6$–$0.9$ is ordinary), so the approximation is weakest exactly where seasonal adjustment operates. Compare the two on the running example:

<!-- run -->
```r
ml  <- arima(lap, order = c(0, 1, 1),
             seasonal = list(order = c(0, 1, 1), period = 12), method = "ML")
css <- arima(lap, order = c(0, 1, 1),
             seasonal = list(order = c(0, 1, 1), period = 12), method = "CSS")
round(rbind(ML = -coef(ml), CSS = -coef(css)), 4)     # Census signs
```
```text
       ma1   sma1
ML  0.4018 0.5569
CSS 0.3772 0.5724
```
<!-- end -->

The two disagree in both parameters, by a few hundredths. That is small — 144 points is a reasonable sample — but it is not nothing, and note it is *not* a simple shrinkage: here CSS puts $\theta$ lower and $\Theta$ higher than exact ML does. There is no direction to memorise. What matters is that the methods disagree at all, that the disagreement is worst near the invertibility boundary, and that one of the parameters involved is $\Theta$ — which governs how much the seasonal factors will revise ([[10-10-airline-model]]). Given the choice costs nothing, use exact ML.

### Reading the fitted object

Everything discussed above is available directly:

<!-- run -->
```r
cat("log-likelihood        :", round(ml$loglik, 4), "\n")
cat("sigma^2 (concentrated):", round(ml$sigma2, 7), "\n")
cat("n used (after d+D)    :", ml$nobs, "of", length(lap), "\n")
se <- sqrt(diag(ml$var.coef))          # from the Hessian at the optimum
round(cbind(estimate = -coef(ml), se = se, t = -coef(ml) / se), 4)
```
```text
log-likelihood        : 244.6995 
sigma^2 (concentrated): 0.001348 
n used (after d+D)    : 131 of 144 
     estimate     se      t
ma1    0.4018 0.0896 4.4825
sma1   0.5569 0.0731 7.6190
```
<!-- end -->

Note `nobs`: differencing costs $d + D \cdot s = 1 + 12 = 13$ observations, so the likelihood is computed on 131 points, not 144. That matters when comparing models with **different** differencing — the likelihoods are not on the same footing, which is one reason $d$ and $D$ are chosen before the AICC comparison rather than inside it ([[10-13-model-selection]]).

## Practical failure modes

| Symptom | Likely cause |
|---|---|
| MA coefficient pinned at $\pm1$ | over-differenced ([[10-05-invertibility]]) |
| Huge standard errors, unstable across vintages | common AR/MA factor ([[10-08-arma-duality]]) |
| Optimiser will not converge | too many parameters, or bad starting values, or outliers |
| Estimates jump when one observation is added | outlier near the end, or a genuinely fragile model |

X-13 addresses the last one directly by detecting **outliers** (AO / LS / TC) as regression terms before estimating the ARIMA. An undetected level shift will wreck an ARIMA fit and, via the fit, wreck the seasonal factors — this is one of the main reasons regARIMA exists.

## regARIMA, briefly

$$z_t = \sum_i \beta_i x_{it} + n_t, \qquad \phi(B)\Phi(B^s)\nabla^d\nabla_s^D\, n_t = \theta(B)\Theta(B^s)a_t$$

Regressors $x_{it}$: trading-day, leap-year, moving holidays (Easter), outliers, user variables. The $\beta$'s and the ARIMA parameters are estimated **jointly** by exact ML — not in two stages — because the ARIMA structure determines the correct weighting for the regression.

The output that matters downstream is the **linearized series**: $z_t$ minus the estimated regression effects. That is what gets seasonally adjusted.

> [!warning] Exception worth remembering
> The **constant/mean term is not removed** the way trading-day and outlier effects are. SEATS keeps the mean inside the series it decomposes, centres the differenced series by it, and folds it back so the **trend** carries the drift. Getting this wrong produces a trend error that grows toward the sample ends — a distinctive diagnostic signature. Revisit in [[40-00-seats-map]].

## Numerically

What the fitting routine actually reports.

Coefficients, standard errors and $t$-statistics from the airline fit. A $|t|$ under 2 is a term the data does not support:

<!-- run -->
```r
fit <- arima(lap, order = c(0, 1, 1),
             seasonal = list(order = c(0, 1, 1), period = 12))
se <- sqrt(diag(fit$var.coef))
round(cbind(estimate = coef(fit), se = se, t = coef(fit) / se), 4)
```
```text
     estimate     se       t
ma1   -0.4018 0.0896 -4.4825
sma1  -0.5569 0.0731 -7.6190
```
<!-- end -->

AICC rather than AIC, because the correction matters at these sample sizes:

<!-- run -->
```r
aicc <- function(f) {
  k <- length(coef(f)) + 1; n <- f$nobs
  AIC(f) + 2 * k * (k + 1) / (n - k - 1)
}
cat("n =", fit$nobs, "  AIC =", round(AIC(fit), 2),
    "  AICC =", round(aicc(fit), 2), "\n")
```
```text
n = 131   AIC = -483.4   AICC = -483.21 
```
<!-- end -->

## Exercises

1. Fit the airline model to `log(AirPassengers)` with `method="ML"` and `method="CSS"`. Compare $\Theta$. Which is closer to 1?
2. Insert an artificial level shift into the series, refit, and watch the ARIMA parameters move. Then add the level shift as a regressor via `xreg=` and confirm they come back.
3. Fit an over-parameterised model and inspect the standard errors.

> [!abstract] Derivation
> - [[derivations#D13. What the likelihood actually is|the prediction-error decomposition, and concentrating the variance]]

## Links

- Prev: [[10-11-sign-conventions]] · Next: [[10-13-model-selection]]

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

## Estimation for a general ARIMA

Everything above used the airline model, where there are two parameters and the surface can be drawn. The general case is not harder, it just cannot be pictured. Code: [[code-10-12b-general-estimation|`R/10-12b-general-estimation.R`]], which implements exact ML from scratch and checks itself against `arima()`.

Three ideas carry the whole thing.

### 1. There is no such thing as a seasonal model

Multiply $\phi(B)\Phi(B^s)$ and $\theta(B)\Theta(B^s)$ out and you have an ordinary ARMA whose coefficients happen to be mostly zero. Difference the data first, and a stationary ARMA problem is all that is left.

<!-- run -->
```r
source("R/10-12b-general-estimation.R")
e <- expand_seasonal(ma = -0.4018, sma = -0.5569, s = 12)
cat("airline (0,1,1)(0,1,1)_12 becomes ARMA(0,", length(e$ma), ")\n", sep = "")
cat("nonzero MA lags:", which(abs(e$ma) > 1e-12), "\n")
cat("values         :", round(e$ma[abs(e$ma) > 1e-12], 4), "\n")
```
```text
airline (0,1,1)(0,1,1)_12 becomes ARMA(0,13)
nonzero MA lags: 1 12 13 
values         : -0.4018 -0.5569 0.2238 
```
<!-- end -->

Thirteen coefficients, three of them nonzero. The one at lag 13 is $\theta\Theta$, the cross term.

### 2. Any ARMA is a state-space model

With $r = \max(p, q+1)$:

$$T = \begin{pmatrix}\phi_1 & 1 & 0 & \cdots \\ \phi_2 & 0 & 1 & \cdots \\ \vdots & & & \\ \phi_r & 0 & 0 & \cdots\end{pmatrix},
\qquad
R = \begin{pmatrix}1 \\ \theta_1 \\ \vdots \\ \theta_{r-1}\end{pmatrix},
\qquad
Z = (1, 0, \dots, 0)$$

$$\alpha_t = T\alpha_{t-1} + Ra_t, \qquad z_t = Z\alpha_t$$

The state dimension is $\max(p,q+1)$, **not** $p$ — it has to carry the MA terms still working their way through:

<!-- run -->
```r
for (pq in list(c(1,0), c(0,1), c(2,2), c(0,13), c(3,1))) {
  ss <- arma_ss(rep(0.1, pq[1]), rep(0.1, pq[2]))
  cat(sprintf("  ARMA(%2d,%2d) -> r = max(p, q+1) = %2d\n", pq[1], pq[2], ss$r))
}
```
```text
  ARMA( 1, 0) -> r = max(p, q+1) =  1
  ARMA( 0, 1) -> r = max(p, q+1) =  2
  ARMA( 2, 2) -> r = max(p, q+1) =  3
  ARMA( 0,13) -> r = max(p, q+1) = 14
  ARMA( 3, 1) -> r = max(p, q+1) =  3
```
<!-- end -->

The differenced airline model is ARMA(0,13), so $r = 14$ — large because the *MA* reaches back thirteen periods, not because of anything on the AR side.

### 3. The Kalman filter turns that into one-step errors

$$\begin{aligned}
\text{predict:}\quad & a \leftarrow Ta, \qquad P \leftarrow TPT' + RR' \\
\text{error:}\quad & v_t = z_t - Za, \qquad F_t = ZPZ' \\
\text{gain:}\quad & K = PZ'/F_t \\
\text{update:}\quad & a \leftarrow a + Kv_t, \qquad P \leftarrow P - KZP
\end{aligned}$$

Since $Z = (1,0,\dots,0)$, every $Z$ above means "take the first element", and $F_t$ is just $P_{11}$. Started from the stationary $P_0$ solving $P_0 = TP_0T' + RR'$, and fed into D13's formula, that is exact ML.

### Working the recursions, for the airline model

Here are the first eight steps on the differenced series. Read across: the filter predicts, is wrong by $v_t$, and records how surprised it should have been ($F_t$).

<!-- run -->
```r
fitk <- arima(lap, order = c(0,1,1), seasonal = list(order = c(0,1,1), period = 12),
              method = "ML")
ek <- expand_seasonal(ma = coef(fitk)[1], sma = coef(fitk)[2], s = 12)
yk <- difference(lap, 1, 1, 12)
ss <- arma_ss(ek$ar, ek$ma); Tm <- ss$T; Rm <- ss$R
a <- matrix(0, ss$r, 1); P <- init_P(Tm, Rm)
cat(sprintf("r = %d,  P0[1,1] = %.6f\n\n", ss$r, P[1,1]))
cat("  t      y_t   a_pred      v_t      F_t   cum ssq  cum logF\n")
ssq <- 0; slF <- 0
for (t in 1:8) {
  a <- Tm %*% a; P <- Tm %*% P %*% t(Tm) + Rm %*% t(Rm)
  v <- yk[t] - a[1,1]; FF <- P[1,1]
  ssq <- ssq + v*v/FF; slF <- slF + log(FF)
  K <- P[, 1, drop = FALSE] / FF
  cat(sprintf(" %2d %8.5f %8.5f %8.5f %8.5f  %8.4f  %8.4f\n",
              t, yk[t], a[1,1], v, FF, ssq, slF))
  a <- a + K * v; P <- P - K %*% P[1, , drop = FALSE]
}
```
```text
r = 14,  P0[1,1] = 1.521739

  t      y_t   a_pred      v_t      F_t   cum ssq  cum logF
  1  0.03916  0.00000  0.03916  1.52174    0.0010    0.4199
  2  0.00036 -0.01355  0.01391  1.33960    0.0012    0.7122
  3 -0.02050 -0.00547 -0.01503  1.31483    0.0013    0.9859
  4 -0.01294  0.00602 -0.01896  1.31094    0.0016    1.2567
  5  0.06615  0.00761  0.05854  1.31031    0.0042    1.5269
  6  0.03991 -0.02352  0.06343  1.31021    0.0073    1.7971
  7  0.00000 -0.02549  0.02549  1.31019    0.0078    2.0673
  8  0.01135 -0.01024  0.02160  1.31019    0.0081    2.3375
```
<!-- end -->

Two things to notice.

$F_t$ **starts high and settles.** It begins at $P_0[1,1]$ and converges within a handful of steps. Early on the filter has almost no history, so its one-step forecasts genuinely deserve less confidence, and the likelihood is told so through $\log F_t$. **That transient is the entire difference between exact ML and CSS** — CSS assumes every $F_t$ is equal and drops the $\log F_t$ term, which is fine in the middle of a long series and not fine near an MA unit root.

The **prediction is not zero even though the mean is.** At $t=2$ the filter already expects $-0.0136$, because the state carries the shock from $t=1$ multiplied through the MA weights. That memory is what the state is *for*.

### Does it agree with `arima()`?

Evaluated at `arima()`'s own estimates, so any gap is the likelihood computation rather than the optimiser:

<!-- run -->
```r
chk <- function(x, o, sq, s) {
  f <- arima(x, order = o, seasonal = list(order = sq, period = s), method = "ML")
  co <- coef(f); p <- o[1]; q <- o[3]; P <- sq[1]; Q <- sq[3]
  ee <- expand_seasonal(if (p) co[1:p] else numeric(0),
                        if (q) co[p + 1:q] else numeric(0),
                        if (P) co[p+q + 1:P] else numeric(0),
                        if (Q) co[p+q+P + 1:Q] else numeric(0), s)
  k <- kalman_loglik(difference(x, o[2], sq[2], s), ee$ar, ee$ma)
  c(ours = k$loglik, arima = f$loglik, diff = k$loglik - f$loglik)
}
round(rbind(
  `AirPassengers (0,1,1)(0,1,1)` = chk(lap, c(0,1,1), c(0,1,1), 12),
  `AirPassengers (2,1,1)(0,1,1)` = chk(lap, c(2,1,1), c(0,1,1), 12),
  `log(UKgas) (0,1,1)(0,1,1)_4`  = chk(log(UKgas), c(0,1,1), c(0,1,1), 4),
  `Nile (0,1,1)`                 = chk(Nile, c(0,1,1), c(0,0,0), 12)), 6)
```
```text
                                   ours      arima      diff
AirPassengers (0,1,1)(0,1,1)  244.69649  244.69953 -0.003044
AirPassengers (2,1,1)(0,1,1)  246.13196  246.13613 -0.004169
log(UKgas) (0,1,1)(0,1,1)_4    85.00469   85.00481 -0.000121
Nile (0,1,1)                 -632.54562 -632.54562 -0.000001
```
<!-- end -->

Nile agrees to seven decimals; the seasonal models are off in the third. That is not a bug in either — it is a real difference in method, and it is worth understanding.

> [!important] `arima()` does not difference the data
> It keeps the differencing **inside the state** and gives those elements a diffuse prior of variance $\kappa$, default $10^6$. That is an approximation of order $1/\kappa$. Differencing first and using the exact stationary $P_0$, as above, is the limit it converges to. You can watch it converge:

<!-- run -->
```r
ours <- kalman_loglik(yk, ek$ar, ek$ma)$loglik
cat(sprintf("ours (exact P0)   : %.8f\n", ours))
for (kp in c(1e6, 1e8, 1e10, 1e12)) {
  f <- arima(lap, order = c(0,1,1), seasonal = list(order = c(0,1,1), period = 12),
             method = "ML", fixed = coef(fitk), transform.pars = FALSE, kappa = kp)
  cat(sprintf("arima kappa = %-6.0e: %.8f   gap %+.2e\n", kp, f$loglik, f$loglik - ours))
}
```
```text
ours (exact P0)   : 244.69648682
arima kappa = 1e+06 : 244.69953060   gap +3.04e-03
arima kappa = 1e+08 : 244.69651727   gap +3.04e-05
arima kappa = 1e+10 : 244.69648665   gap -1.75e-07
arima kappa = 1e+12 : 244.69623281   gap -2.54e-04
```
<!-- end -->

Raise $\kappa$ by 100 and the gap falls by 100 — exactly the $O(1/\kappa)$ behaviour a diffuse approximation should show. By $10^{10}$ it has landed on our value. By $10^{12}$ it is **worse again**, because an enormous prior variance costs floating-point precision when it is subtracted away. The error is U-shaped in $\kappa$, and R's default sits deliberately on the safe side of the minimum.

None of this matters for a published seasonal adjustment — the differences are in the third decimal of a log-likelihood. It matters for understanding what "exact" means: it is exact *given* an initialisation, and there is more than one defensible choice.

### And can we find the estimates ourselves?

<!-- run -->
```r
own <- fit_arima_ml(lap, order = c(0,1,1), seasonal = c(0,1,1), s = 12)
ref <- arima(lap, order = c(0,1,1), seasonal = list(order = c(0,1,1), period = 12),
             method = "ML")
round(rbind(ours = own$par, arima = coef(ref)), 6)
```
```text
            ma1      sma1
ours  -0.401823 -0.556936
arima -0.401827 -0.556947
```
<!-- end -->

Same estimates to five decimals, from an optimiser handed nothing but the likelihood above. The remaining machinery in a production fitter — parameter transformations to keep the search inside the invertible region, analytic derivatives, good starting values — buys speed and robustness, not a different answer.

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

*Solutions: [[solutions#10-12-estimation|worked answers]] in the solutions appendix.*

1. Fit the airline model to `log(AirPassengers)` with `method="ML"` and `method="CSS"`. Compare $\Theta$. Which is closer to 1?
2. Insert an artificial level shift into the series, refit, and watch the ARIMA parameters move. Then add the level shift as a regressor via `xreg=` and confirm they come back.
3. Fit an over-parameterised model and inspect the standard errors.

> [!abstract] Derivation
> - [[derivations#D13. What the likelihood actually is|the prediction-error decomposition, and concentrating the variance]]

## Going further

*Harder, and different in kind: predict before you run, break things on purpose, and move the idea to a series it was not built on.*

1. **Predict first.** Will adding an AR(1) term to the airline model raise or lower the log-likelihood? Will it raise or lower AICC? Answer both before fitting.
2. **Break it.** Fit the airline model to 24 observations. What happens to the standard errors, and would you trust the $\Theta$?
3. Use `R/10-12b-general-estimation.R` to evaluate the likelihood at a grid of $(\theta,\Theta)$ and find the maximum yourself, without `optim`.

## Practice set

*Drills, output-reading and judgement calls. Short answers; the point is fluency and knowing what you are looking at.*

1. **Drill.** Fit the airline model with `method = 'ML'` and `'CSS'` on three series and tabulate both parameters.
2. **Drill.** Compute AIC and AICC by hand from `logLik()` and check against the built-ins.
3. **Drill.** Report the $t$-statistic for every coefficient in an airline fit on three series. Any below 2?
4. **Read it.** A coefficient has estimate 0.42 and standard error 0.41. What do you conclude?
5. **Read it.** The optimiser reports `convergence = 1`. What does that mean and what would you do?
6. **Read it.** `nobs` is 131 for a 144-point series. Where did 13 go?
7. **Judgement.** Two models differ by 0.4 AICC. Which do you publish?
8. **Judgement.** Your $\Theta$ moves from 0.55 to 0.71 when one observation is added. What is your first suspicion?
9. **Connect.** Which quantity in the likelihood is *not* searched over numerically, and why does that matter for the surface you can plot?

## Links

- Prev: [[10-11-sign-conventions]] · Next: [[10-13-model-selection]]

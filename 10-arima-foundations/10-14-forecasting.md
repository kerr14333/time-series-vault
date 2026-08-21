---
aliases: [Forecasting, Psi weights, Forecast extension]
tags: [module-1, key]
---

# Forecasting — and why seasonal adjustment needs it

Code: [[code-10-14-forecasting|`R/10-14-forecasting.R`]]

This note is the hinge between Module 1 and everything after it. Forecasting is not a side application of ARIMA here; **it is the reason X-13 fits an ARIMA at all.**

## Minimum-MSE forecast

The optimal $h$-step forecast is the conditional expectation given the past. Using the AR($\infty$) form ([[10-08-arma-duality]]), forecast recursively: replace future $a$'s by 0 and future $z$'s by their forecasts.

Forecast error in terms of the $\psi$-weights:

$$e_t(h) = \sum_{j=0}^{h-1}\psi_j a_{t+h-j} \qquad\Longrightarrow\qquad V(h) = \sigma_a^2\sum_{j=0}^{h-1}\psi_j^2$$

Consequences worth internalising:

- $V(h)$ is nondecreasing in $h$. For a **stationary** model $\sum\psi_j^2$ converges, so $V(h)$ flattens at the unconditional variance — the forecast reverts to the mean.
- For a model with **unit roots**, $\psi_j \not\to 0$ and $V(h)$ grows without bound. A random walk's forecast is a flat line with ever-widening bands.
- For the **airline model**, the forecast keeps the seasonal shape and extends the local trend linearly — which is exactly what makes it useful for extending a real economic series.

## Why the filters need forecasts

Here is the argument that motivates the rest of this vault.

A seasonal adjustment filter is **symmetric and two-sided**. To estimate the seasonal factor for month $t$ you use data from roughly $t-3$ years to $t+3$ years. Fine in the middle of the sample. But for the **most recent month there is no future data.**

Two possible responses:

1. Use a different, **asymmetric** filter at the ends — one that only looks backward. X-11 does this explicitly, with its own set of end weights.
2. **Forecast the series forward**, then apply the ordinary symmetric filter to the extended series.

X-13 does (2), using the regARIMA model, and this is the deep reason ARIMA appears in a method that is otherwise about moving averages. Note that (2) *is* a form of (1): applying a symmetric filter to model-based forecasts is algebraically equivalent to applying some implied asymmetric filter to the observed data. Forecast extension is a principled way to choose the end filter.

> [!important] The consequence that makes this whole subject interesting
> The most recent months' seasonal factors depend on **forecasts**, not data. When real data arrives, they get **revised**. And at a business-cycle turning point the forecast is systematically wrong — it extrapolates the old regime — so the end-of-sample adjustment is systematically contaminated, precisely when people care most.
>
> Quantified: seasonal-adjustment revision variance falls roughly 50% after 1 year, 77% after 3 years, 88% after 5 years (Maravall 1996). And roughly 40% of month-to-month movements in a seasonally adjusted series can be false signals (Maravall & Pierce 1983).

Module 5 makes this the main event: [[50-00-diagnostics-map]].

## Forecasting logs

If the model is on $\log z_t$ and you want a forecast of $z_t$, $\exp$ of the forecast is the **median**, not the mean. Mean requires $\exp(\hat z + \sigma^2/2)$. For seasonal adjustment this rarely matters (factors are ratios), but it matters for published forecasts.

![[10-14-forecast-fan.png]]

*Drawn by [[figure-index#10-14-forecast-fan.png|`make-figures.R`]] — code and every other figure in the [[figure-index|figure appendix]].*

Twenty-four months ahead, back on the passenger scale. The forecast keeps both the trend and the seasonal shape, because the model has both differences.

The part worth staring at is the *interval*, not the line. It widens with horizon as the $\psi$-weights accumulate, and it is already wide at twelve months. Any statement about seasonal adjustment at the end of a series inherits this uncertainty — which is exactly why forecast-extension helps in ordinary times and not at a turning point ([[50-06-turning-points]]).

## Computing a forecast from basics

No new theory is needed. A forecast is the model's difference equation, plus one rule about the future.

### Step 1 — turn the model into a recipe

Start from the airline model and multiply both sides out:

$$(1-B)(1-B^{12})z_t = (1-\theta B)(1-\Theta B^{12})a_t$$

$$z_t - z_{t-1} - z_{t-12} + z_{t-13} \;=\; a_t - \theta a_{t-1} - \Theta a_{t-12} + \theta\Theta a_{t-13}$$

Move everything but $z_t$ to the right:

$$z_t = \underbrace{z_{t-1} + z_{t-12} - z_{t-13}}_{\text{from the differencing}} \; + \; \underbrace{a_t - \theta a_{t-1} - \Theta a_{t-12} + \theta\Theta a_{t-13}}_{\text{from the MA part}}$$

Note the $\theta\Theta a_{t-13}$ term. It appears because the two MA factors multiply — nobody writes it down from intuition, and leaving it out gives visibly wrong forecasts. Check the expansion rather than trusting memory:

<!-- run -->
```r
fit <- arima(lap, order = c(0, 1, 1),
             seasonal = list(order = c(0, 1, 1), period = 12))
th <- -coef(fit)[1]; Th <- -coef(fit)[2]      # Census signs
cat("AR side (1-B)(1-B^12) :", poly_show(diff_poly(d = 1, D = 1)), "\n")
cat("MA side               :", poly_show(airline_ma(th, Th)), "\n")
cat(sprintf("theta = %.4f   Theta = %.4f   theta*Theta = %.4f\n", th, Th, th * Th))
```
```text
AR side (1-B)(1-B^12) : 1 - B - B^12 + B^13 
MA side               : 1 - 0.401828B - 0.5569448B^12 + 0.223796B^13 
theta = 0.4018   Theta = 0.5569   theta*Theta = 0.2238
```
<!-- end -->

### Step 2 — take expectations, using two rules

Stand at time $n$ and ask for $\hat z_{n+h} = E[z_{n+h}\mid \text{everything up to } n]$. Everything follows from:

| Term | If it is dated $\le n$ | If it is dated $> n$ |
|---|---|---|
| a $z$ | use the **observed value** | use the **forecast already computed** |
| an $a$ | use the **residual** $\hat a_t$ | use **0** |

The second row, right-hand column, is the whole of forecasting: **future shocks have expectation zero.** A forecast says what happens if nothing new occurs.

So the one-step forecast is read straight off the recipe:

$$\hat z_{n+1} = z_n + z_{n-11} - z_{n-12} - \theta\hat a_n - \Theta\hat a_{n-11} + \theta\Theta\hat a_{n-12}$$

For $h \ge 2$ apply the same line again, feeding in the forecasts you just made. It is a recursion, and it is short enough to write out:

<!-- run -->
```r
z <- as.numeric(lap); a <- as.numeric(residuals(fit)); n <- length(z)
zz <- c(z, numeric(12))          # room for 12 forecasts
aa <- c(a, numeric(12))          # future shocks are ZERO -- that is rule 2

for (h in 1:12) {
  i <- n + h
  zz[i] <- zz[i-1] + zz[i-12] - zz[i-13] -
           th * aa[i-1] - Th * aa[i-12] + th * Th * aa[i-13]
}
hand <- zz[(n+1):(n+12)]
round(head(hand, 4), 6)
```
```text
[1] 6.110186 6.053775 6.171715 6.199300
```
<!-- end -->

Now the test that matters — does it agree with R's own forecaster?

<!-- run -->
```r
pk <- as.numeric(predict(fit, n.ahead = 12)$pred)
cat("max |hand-rolled - predict()| =", format(max(abs(hand - pk))), "\n")
```
```text
max |hand-rolled - predict()| = 8.451665e-08 
```
<!-- end -->

Agreement to eight decimal places. `predict()` is doing exactly the recursion above — there is no extra machinery hiding inside it.

### Step 3 — where the uncertainty comes from

Rewrite the model in $\psi$-weight form, $z_t = \sum_{j\ge0}\psi_j a_{t-j}$ ([[10-08-arma-duality]]). Splitting at the forecast origin,

$$z_{n+h} = \underbrace{\sum_{j\ge h}\psi_j a_{n+h-j}}_{\text{known now}} \;+\; \underbrace{\sum_{j=0}^{h-1}\psi_j a_{n+h-j}}_{\text{future shocks}}$$

The first sum is the forecast; the second is the error. The shocks are uncorrelated, so the variances add:

$$\operatorname{Var}(e_h) = \sigma_a^2\sum_{j=0}^{h-1}\psi_j^2$$

A cumulative sum of squares — it can only grow with $h$. Compute it by hand and check against `predict()` again:

<!-- run -->
```r
ar_c <- c(1, rep(0, 10), 1, -1)                 # (1-B)(1-B^12), R sign
ma_c <- c(-th, rep(0, 10), -Th, th * Th)        # the MA side, R sign
psi  <- c(1, ARMAtoMA(ar = ar_c, ma = ma_c, lag.max = 11))
se_hand <- sqrt(fit$sigma2 * cumsum(psi^2))
se_pk   <- as.numeric(predict(fit, n.ahead = 12)$se)
round(cbind(h = 1:12, psi = psi, se_hand = se_hand, se_predict = se_pk), 5)
```
```text
       h     psi se_hand se_predict
 [1,]  1 1.00000 0.03672    0.03672
 [2,]  2 0.59817 0.04278    0.04278
 [3,]  3 0.59817 0.04809    0.04809
 [4,]  4 0.59817 0.05287    0.05287
 [5,]  5 0.59817 0.05725    0.05725
 [6,]  6 0.59817 0.06132    0.06132
 [7,]  7 0.59817 0.06513    0.06513
 [8,]  8 0.59817 0.06873    0.06873
 [9,]  9 0.59817 0.07216    0.07216
[10,] 10 0.59817 0.07543    0.07543
[11,] 11 0.59817 0.07856    0.07856
[12,] 12 0.59817 0.08157    0.08157
```
<!-- end -->

Look at the $\psi$ column: after $\psi_0 = 1$ it is **constant** at $1-\theta$ for every horizon inside the first year. That is a property of this model — with $d=1$ the weights do not decay, which is precisely why the interval keeps widening instead of settling down. A stationary model would have $\psi_j \to 0$ and a variance that converges.

> [!tip] What to take from this
> A forecast is arithmetic on past values and past residuals. The only judgement in it is the model, and the only genuinely unknown quantity — the future shock — is replaced by its mean of zero. When someone says a forecast "assumes nothing changes", this equation is what they mean, literally.

## Numerically

Forecasts and, more importantly, how fast the uncertainty grows.

Twelve months ahead, back on the original scale:

<!-- run -->
```r
f <- arima(lap, order = c(0, 1, 1),
           seasonal = list(order = c(0, 1, 1), period = 12))
p <- predict(f, n.ahead = 12)
round(cbind(forecast = exp(p$pred), lo95 = exp(p$pred - 1.96 * p$se),
            hi95 = exp(p$pred + 1.96 * p$se)), 1)
```
```text
         forecast  lo95  hi95
Jan 1961    450.4 419.1 484.0
Feb 1961    425.7 391.5 463.0
Mar 1961    479.0 435.9 526.4
Apr 1961    492.4 443.9 546.2
May 1961    509.1 455.0 569.5
Jun 1961    583.3 517.3 657.8
Jul 1961    670.0 589.7 761.2
Aug 1961    667.1 583.0 763.3
Sep 1961    558.2 484.6 643.0
Oct 1961    497.2 428.9 576.4
Nov 1961    429.9 368.5 501.4
Dec 1961    477.2 406.7 560.0
```
<!-- end -->

The interval widens with horizon because the $\psi$-weights accumulate. This is exactly why forecast-extension helps least at the end of a series:

<!-- run -->
```r
round(data.frame(horizon = c(1, 3, 6, 12),
                 se = p$se[c(1, 3, 6, 12)],
                 width_pct = 100 * (exp(1.96 * p$se[c(1, 3, 6, 12)]) - 1)), 3)
```
```text
  horizon    se width_pct
1       1 0.037     7.462
2       3 0.048     9.884
3       6 0.061    12.770
4      12 0.082    17.337
```
<!-- end -->

## Exercises

1. Forecast `log(AirPassengers)` 24 months ahead from the airline model. Plot with intervals on the original scale. How fast do the bands widen?
2. Compute $\psi$-weights for the airline model with `ARMAtoMA()` after expanding the polynomials. Confirm they do not decay to zero.
3. **The key experiment.** Fit the model to data through 1958, forecast 1959–60, and compare to the truth. Then re-run holding out a different window. Where are the errors largest?
4. Truncate the series at various points, adjust each vintage, and plot how the January-1958 seasonal factor changes as more data arrives. You have just measured a revision path — this is Module 5 in miniature.

> [!abstract] Derivation
> - [[derivations#D14. Forecasting, from the difference equation|the recursion and the psi-weight variance]]

## Links

- Prev: [[10-13-model-selection]] · **Module 1 complete** → [[20-00-x11-map]]
- Payoff: [[50-00-diagnostics-map]]

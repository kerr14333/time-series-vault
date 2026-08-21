---
aliases: [Model selection, AICC, Ljung-Box, automdl]
tags: [module-1]
---

# Model selection and residual diagnostics

Code: [[code-10-13-model-selection|`R/10-13-model-selection.R`]]

## Information criteria

$$\text{AIC} = -2\log L + 2k, \qquad \text{AICC} = \text{AIC} + \frac{2k(k+1)}{n-k-1}, \qquad \text{BIC} = -2\log L + k\log n$$

**Use AICC**, the small-sample correction — with 120 monthly observations and 5–8 parameters the correction is not negligible, and it is what X-13 uses.

Two rules that prevent nonsense:

1. Only compare models fitted to the **same differenced data**. Changing $d$ or $D$ changes the number of observations and the likelihood is no longer comparable. Choose $d,D$ first (by ACF and by tests), then use AICC within that.
2. A difference of <2 in AICC is not a real difference. Prefer the simpler model.

## Residual diagnostics — the actual test

The model is adequate when the residuals are indistinguishable from white noise.

**Ljung–Box:**

$$Q = n(n+2)\sum_{k=1}^{h}\frac{\hat\rho_k^2}{n-k} \ \sim\ \chi^2_{h-k_{\text{param}}}$$

Watch the degrees of freedom — R's `Box.test()` does *not* subtract the fitted parameters unless you pass `fitdf=`. A very common silent error.

For seasonal data, always check lags 12, 24, 36 explicitly, not just the first few. Leftover seasonal autocorrelation in the residuals means the seasonal part of your model is wrong, and that is precisely the part seasonal adjustment depends on.

**Also check:**
- Residual ACF/PACF plots (more informative than the single $Q$ statistic).
- Normality: QQ plot, Shapiro. Non-normality usually means undetected outliers.
- **Residual spectrum**: a peak at a seasonal frequency in the residuals is the single most damning diagnostic for a seasonal model. X-13 prints this and flags it.
- Over-fitting check: extend the model by one order; if the extra coefficient is insignificant, you were done.

## Automatic identification

Two lineages:

- **TRAMO's `automdl`** (Gómez–Maravall), used in X-13: tests for differencing orders, then searches ARMA orders, with guards against near-cancelling factors and a preference for parsimony. It also runs the log/level test and outlier detection in the same pass.
- **Hyndman–Khandakar** (`auto.arima`): stepwise search over orders with unit-root tests (KPSS, OCSB) for $d, D$.

Both are good. Neither excuses you from looking at the residual diagnostics — automatic selection optimises a criterion, not adequacy.

## The pragmatic truth in this field

For official statistics the model is often **fixed at the airline model** and reviewed annually, even when a search would find something marginally better. Reason: **stability**. A model that changes each month produces seasonal factors that change for reasons unrelated to the data, and users of the published series cannot tell the two apart. Parsimony and stability beat in-sample fit here. Keep this in mind — it explains a lot of what looks like inertia in agency practice.

## Numerically

Selection is a numerical comparison, so do it numerically.

Four candidates on the same series. Lower AICC wins, but note how close the top two are:

<!-- run -->
```r
aicc <- function(f) { k <- length(coef(f)) + 1; n <- f$nobs
                      AIC(f) + 2 * k * (k + 1) / (n - k - 1) }
cand <- list("(0,1,1)(0,1,1)" = c(0,1,1),
             "(1,1,0)(0,1,1)" = c(1,1,0),
             "(1,1,1)(0,1,1)" = c(1,1,1),
             "(2,1,0)(0,1,1)" = c(2,1,0))
for (nm in names(cand)) {
  f <- arima(lap, order = cand[[nm]],
             seasonal = list(order = c(0, 1, 1), period = 12))
  cat(sprintf("%-16s AICC = %8.3f\n", nm, aicc(f)))
}
```
```text
(0,1,1)(0,1,1)   AICC = -483.210
(1,1,0)(0,1,1)   AICC = -481.301
(1,1,1)(0,1,1)   AICC = -481.582
(2,1,0)(0,1,1)   AICC = -479.706
```
<!-- end -->

Ljung-Box on the residuals: a model that wins on AICC must still leave white noise behind:

<!-- run -->
```r
f <- arima(lap, order = c(0, 1, 1),
           seasonal = list(order = c(0, 1, 1), period = 12))
bt <- Box.test(residuals(f), lag = 24, type = "Ljung-Box", fitdf = 2)
cat("Ljung-Box Q =", round(bt$statistic, 2),
    " df =", bt$parameter, " p =", round(bt$p.value, 4), "\n")
```
```text
Ljung-Box Q = 26.45  df = 22  p = 0.233 
```
<!-- end -->

## Exercises

1. Fit $(0,1,1)(0,1,1)$, $(0,1,2)(0,1,1)$, $(1,1,1)(0,1,1)$ to `log(AirPassengers)`. Compare AICC. Does the extra parameter earn its place?
2. Run `Box.test()` with and without `fitdf=`. How different are the p-values?
3. Look at the residual spectrum of a deliberately under-specified model (drop the seasonal MA) and find the seasonal peak.

## Links

- Prev: [[10-12-estimation]] · Next: [[10-14-forecasting]]
